// ============================================================
// FILE: lib/providers/auth_provider.dart
// ============================================================
// Unified authentication provider with complete role management
// Handles: auth state, role detection, merchant/driver status
// NOW WITH: Partnership application system integration
// ISSUE 1 FIX: Native Google Sign-In via google_sign_in package
// ISSUE 2 FIX: refreshUserRole() now has a 5-second cooldown
//              to prevent redundant DB calls on every navigation
// SESSION 8 FIX: _merchantStatusLower now correctly extracts
//   enum value (was returning "applicationstatus.approved"
//   instead of "approved", causing isMerchant to be false)
// SESSION 24 FIX (Issue B): _loadUserData() now deduplicated
//   with Completer + cooldown. 3 concurrent calls → 1 DB hit.
// SESSION 26 FIX (Bug #1): _loadUserData() now returns bool.
//   _handleAuthStateChange only calls notifyListeners() when
//   data actually loaded. Previously, initialSession/tokenRefreshed
//   events called notifyListeners() unconditionally — even when
//   _loadUserData was skipped by cooldown — causing parent widgets
//   to rebuild and HomeScreen to remount (double Wave 1 + Wave 2).
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/merchant_model.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

class AuthProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================

  User? _supabaseUser;
  Map<String, dynamic>? _userModel;
  Merchant? _merchant;
  Map<String, dynamic>? _driver;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  StreamSubscription<AuthState>? _authSubscription;

  // ISSUE 2 FIX: Cooldown tracking for refreshUserRole
  DateTime? _lastUserRoleRefresh;
  bool _isRefreshingUserRole = false;
  static const _userRoleRefreshCooldown = Duration(seconds: 5);

  // SESSION 24 FIX (Issue B): Dedup _loadUserData calls.
  // If _loadUserData() is already in progress, subsequent callers
  // await the same Completer instead of firing parallel DB queries.
  Completer<void>? _loadUserDataCompleter;

  // ============================================================
  // GETTERS - User Info
  // ============================================================

  User? get supabaseUser => _supabaseUser;
  Map<String, dynamic>? get userModel => _userModel;
  User? get currentUser => _supabaseUser;

  String? get userId => _supabaseUser?.id;
  String? get email => _supabaseUser?.email ?? _userModel?['email'] as String?;
  String? get fullName => _userModel?['full_name'] as String?;
  String? get phone => _userModel?['phone'] as String?;
  String? get avatarUrl => _userModel?['avatar_url'] as String?;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;

  bool get isAuthenticated => _supabaseUser != null;
  bool get isLoggedIn => isAuthenticated;

  // ============================================================
  // GETTERS - Role Checks
  // ============================================================

  String get role => _userModel?['role'] as String? ?? 'customer';
  String? get roleString => _userModel?['role'] as String?;

  bool get isMerchant => _merchantStatusLower == 'approved';

  bool get isDriver {
    if (_userModel?['role'] == 'driver') return true;
    return (_driver?['is_verified'] as bool? ?? false) == true;
  }

  bool get isAdmin => role == 'admin';

  bool get isCustomer => !isMerchant && !isDriver && !isAdmin;

  // ============================================================
  // GETTERS - Merchant/Driver Data & Application Status
  // ============================================================

  Merchant? get merchant => _merchant;
  Map<String, dynamic>? get driver => _driver;

  String get merchantStatus => _merchantStatusLower;

  String get driverStatus {
    final verified = (_driver?['is_verified'] as bool?) == true;
    final active = (_driver?['is_active'] as bool?) == true;
    if (verified) return 'approved';
    if (active) return 'pending';
    return 'none';
  }

  bool get hasPendingMerchantApplication => merchantStatus == 'pending';
  bool get hasApprovedMerchantApplication => merchantStatus == 'approved';
  bool get hasRejectedMerchantApplication => merchantStatus == 'rejected';

  bool get hasPendingDriverApplication {
    final verified = (_driver?['is_verified'] as bool?) == true;
    final active = (_driver?['is_active'] as bool?) == true;
    return !verified && active;
  }

  bool get hasApprovedDriverApplication {
    return (_driver?['is_verified'] as bool? ?? false) == true;
  }

  bool get hasRejectedDriverApplication {
    final verified = (_driver?['is_verified'] as bool?) == true;
    final active = (_driver?['is_active'] as bool?) == false;
    final exists = _driver != null;
    return exists && !verified && !active;
  }

  bool get canApplyAsMerchant {
    if (_merchant == null) return true;
    return merchantStatus == 'none' || merchantStatus == 'rejected';
  }

  bool get canApplyAsDriver {
    if (_driver == null) return true;
    final verified = (_driver?['is_verified'] as bool? ?? false) == true;
    final active = (_driver?['is_active'] as bool? ?? false) == true;
    return !verified && !active;
  }

  // ============================================================
  // GETTERS - Verification
  // ============================================================

  bool get emailVerified => _userModel?['email_verified'] as bool? ?? false;
  bool get phoneVerified => _userModel?['phone_verified'] as bool? ?? false;
  bool get isFullyVerified => emailVerified && phoneVerified;

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  String get _merchantStatusLower {
    final status = _merchant?.status;
    if (status == null) return 'none';

    String statusStr = status.toString().toLowerCase().trim();

    if (statusStr.contains('.')) {
      statusStr = statusStr.split('.').last;
    }

    if (statusStr == 'approved') return 'approved';
    if (statusStr == 'pending') return 'pending';
    if (statusStr == 'rejected') return 'rejected';
    if (statusStr == 'suspended') return 'suspended';

    if (statusStr.isNotEmpty && statusStr != 'none') {
      debugPrint('[AUTH] ⚠️ Unknown merchant status string: "$statusStr"');
    }

    final isVerified = _merchant?.isVerified == true;
    final isActive = _merchant?.isActive == true;

    if (isVerified) return 'approved';
    if (isActive) return 'pending';
    return 'none';
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  AuthProvider() {
    debugPrint('[AUTH] AuthProvider initialized');
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    try {
      debugPrint('[AUTH] Initializing auth state...');

      final session = SupabaseService.client.auth.currentSession;
      _supabaseUser = session?.user;

      if (_supabaseUser != null) {
        debugPrint('[AUTH] Found existing session: ${_supabaseUser!.email}');
        await _loadUserData(force: true);
      } else {
        debugPrint('[AUTH] No existing session');
        _resetState();
      }

      _isInitialized = true;
      notifyListeners();

      // SESSION 26 FIX: Subscribe to auth AFTER the initial load + notify.
      // The initialSession event will fire shortly after subscribing.
      // Since _loadUserData was just called with force:true, the cooldown
      // will cause the initialSession handler to skip the redundant load,
      // AND (crucially) skip the redundant notifyListeners() too.
      _authSubscription?.cancel();
      _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
        onError: (error) {
          debugPrint('[AUTH] Auth stream error: $error');
        },
      );

      debugPrint('[AUTH] Auth state initialized successfully');
    } catch (e) {
      debugPrint('[AUTH] Error initializing auth state: $e');
      _resetState();
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _handleAuthStateChange(AuthState data) async {
    final event = data.event;
    final session = data.session;

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[AUTH] Auth event: $event');
    debugPrint('[AUTH] Session: ${session != null ? 'exists' : 'null'}');
    debugPrint('[AUTH] User: ${session?.user.email ?? 'none'}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    switch (event) {
      case AuthChangeEvent.signedIn:
        _supabaseUser = session?.user;
        if (_supabaseUser != null) {
          await _loadUserData(force: true);
        }
        notifyListeners();
        break;

      case AuthChangeEvent.signedOut:
        _resetState();
        notifyListeners();
        break;

      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        _supabaseUser = session?.user;
        if (_supabaseUser != null) {
          // SESSION 26 FIX (Bug #1): Only notify listeners if data
          // actually loaded. Previously notifyListeners() fired even
          // when _loadUserData was skipped by cooldown, causing parent
          // widgets to rebuild and HomeScreen to remount (double load).
          final didLoad = await _loadUserData();
          if (didLoad) {
            debugPrint('[AUTH] initialSession/tokenRefreshed: data changed, notifying');
            notifyListeners();
          } else {
            debugPrint('[AUTH] initialSession/tokenRefreshed: no-op, skipping notify');
          }
        }
        break;

      case AuthChangeEvent.userUpdated:
        _supabaseUser = session?.user;
        await _loadUserData(force: true);
        notifyListeners();
        break;

      default:
        debugPrint('[AUTH] Unhandled event: $event');
    }
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  /// SESSION 24 FIX (Issue B): Deduplicated _loadUserData.
  /// SESSION 26 FIX (Bug #1): Now returns bool.
  ///
  /// Returns `true` if data was actually loaded from DB.
  /// Returns `false` if skipped (dedup/cooldown) or user is null.
  ///
  /// Three guards prevent redundant DB calls:
  /// 1. If already in progress → await the same Completer (no parallel calls)
  /// 2. If loaded within cooldown window → skip (unless force=true)
  /// 3. If _supabaseUser is null → skip
  ///
  /// [force] bypasses the cooldown. Used after sign-in, sign-up,
  /// profile update, and user-updated auth events where fresh data
  /// is mandatory.
  Future<bool> _loadUserData({bool force = false}) async {
    if (_supabaseUser == null) return false;

    // Guard 1: If already in progress, just await the same operation
    if (_loadUserDataCompleter != null && !_loadUserDataCompleter!.isCompleted) {
      debugPrint('[AUTH] _loadUserData DEDUPED (already in progress)');
      await _loadUserDataCompleter!.future;
      return false; // Didn't load new data, just waited for existing load
    }

    // Guard 2: If loaded recently, skip (unless forced)
    if (!force && _lastUserRoleRefresh != null) {
      final elapsed = DateTime.now().difference(_lastUserRoleRefresh!);
      if (elapsed < _userRoleRefreshCooldown) {
        debugPrint('[AUTH] _loadUserData SKIPPED (cooldown ${elapsed.inMilliseconds}ms)');
        return false;
      }
    }

    _loadUserDataCompleter = Completer<void>();

    try {
      debugPrint('[AUTH] Loading user data for: ${_supabaseUser!.id}');

      final userRow = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', _supabaseUser!.id)
          .maybeSingle();

      if (userRow != null) {
        _userModel = userRow;
        debugPrint('[AUTH] User loaded: role=${(_userModel!['role'] as String?) ?? 'unknown'}');
      } else {
        debugPrint('[AUTH] No user record found, creating default');
        _userModel = {
          'id': _supabaseUser!.id,
          'email': _supabaseUser!.email,
          'role': 'customer',
        };
      }

      await _loadMerchantData();
      await _loadDriverData();

      // Update the cooldown timestamp after successful load
      _lastUserRoleRefresh = DateTime.now();

      debugPrint('[AUTH] User data loaded completely');
      debugPrint('[AUTH] role: $role, merchantStatus: $merchantStatus, isMerchant: $isMerchant, isDriver: $isDriver');
      debugPrint('[AUTH] ⚠️ For admin status, use AdminProvider.isAdmin');

      _loadUserDataCompleter!.complete();
      return true; // Data was actually loaded
    } catch (e) {
      debugPrint('[AUTH] Error loading user data: $e');
      _loadUserDataCompleter!.completeError(e);
      return false;
    }
  }

  Future<void> _loadMerchantData() async {
    if (_supabaseUser == null) return;

    try {
      final merchantRow = await SupabaseService.client
          .from('merchants')
          .select()
          .eq('user_id', _supabaseUser!.id)
          .maybeSingle();

      if (merchantRow != null) {
        _merchant = Merchant.fromMap(merchantRow);
        debugPrint('[AUTH] Merchant loaded: status=${_merchant?.status} verified=${_merchant?.isVerified} active=${_merchant?.isActive}');
      } else {
        _merchant = null;
        debugPrint('[AUTH] No merchant record found');
      }
    } catch (e) {
      debugPrint('[AUTH] Error loading merchant data: $e');
      _merchant = null;
    }
  }

  Future<void> _loadDriverData() async {
    if (_supabaseUser == null) return;

    try {
      final driverRow = await SupabaseService.client
          .from('drivers')
          .select()
          .eq('user_id', _supabaseUser!.id)
          .maybeSingle();

      if (driverRow != null) {
        _driver = driverRow;
        debugPrint('[AUTH] Driver loaded: verified=${_driver!['is_verified'] as bool? ?? false}');
      } else {
        _driver = null;
        debugPrint('[AUTH] No driver record found');
      }
    } catch (e) {
      debugPrint('[AUTH] Error loading driver data: $e');
      _driver = null;
    }
  }

  // ============================================================
  // ISSUE 2 FIX: refreshUserRole with cooldown
  // ============================================================

  Future<void> refreshUserRole({bool force = false}) async {
    if (_isRefreshingUserRole) {
      debugPrint('[AUTH] refreshUserRole SKIPPED (already in progress)');
      return;
    }

    if (!force && _lastUserRoleRefresh != null) {
      final elapsed = DateTime.now().difference(_lastUserRoleRefresh!);
      if (elapsed < _userRoleRefreshCooldown) {
        debugPrint('[AUTH] refreshUserRole SKIPPED (cooldown ${elapsed.inMilliseconds}ms)');
        return;
      }
    }

    _isRefreshingUserRole = true;
    debugPrint('[AUTH] Refreshing user role...');

    try {
      final didLoad = await _loadUserData(force: force);
      if (didLoad) {
        notifyListeners();
      }
    } finally {
      _isRefreshingUserRole = false;
    }
  }

  Future<void> refreshRoleData() => refreshUserRole();

  // ============================================================
  // ROUTE DETERMINATION
  // ============================================================

  String getHomeRouteForUser() {
    if (role == 'admin') {
      return '/main-layout';
    } else if (role == 'driver' || isDriver) {
      return '/driver-home-screen';
    } else if (role == 'merchant' || isMerchant) {
      return '/merchant-dashboard-screen';
    } else {
      return '/main-layout';
    }
  }

  // ============================================================
  // AUTHENTICATION METHODS
  // ============================================================

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Signing in: $email');

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _supabaseUser = response.user;

      if (_supabaseUser != null) {
        await _loadUserData(force: true);
        debugPrint('[AUTH] Sign in successful');
        await AnalyticsService.logLogin(method: 'email', success: true);
        return true;
      }

      _setError('Sign in failed');
      return false;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Auth error: ${e.message}');
      _setError(e.message);
      await AnalyticsService.logLogin(method: 'email', success: false);
      return false;
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      _setError('An unexpected error occurred');
      await AnalyticsService.logLogin(method: 'email', success: false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Signing up: $email');

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      _supabaseUser = response.user;

      if (_supabaseUser != null) {
        await _createUserRecord(fullName: fullName);
        await _loadUserData(force: true);

        debugPrint('[AUTH] Sign up successful');
        await AnalyticsService.logSignUp(method: 'email', success: true);
        return true;
      }

      _setError('Sign up failed');
      return false;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Auth error: ${e.message}');
      _setError(e.message);
      await AnalyticsService.logSignUp(method: 'email', success: false);
      return false;
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      _setError('An unexpected error occurred');
      await AnalyticsService.logSignUp(method: 'email', success: false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createUserRecord({String? fullName}) async {
    if (_supabaseUser == null) return;

    try {
      await SupabaseService.client.from('users').upsert({
        'id': _supabaseUser!.id,
        'email': _supabaseUser!.email,
        'full_name': fullName,
        'role': 'customer',
        'is_active': true,
        'email_verified': false,
        'phone_verified': false,
      });
      debugPrint('[AUTH] User record created');
    } catch (e) {
      debugPrint('[AUTH] Error creating user record: $e');
    }
  }

  // ============================================================
  // ISSUE 1 FIX: NATIVE GOOGLE SIGN-IN
  // ============================================================

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Starting native Google Sign-In...');

      if (kIsWeb) {
        debugPrint('[AUTH] Web platform detected, using OAuth flow');
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        await AnalyticsService.logLogin(method: 'google', success: true);
        return true;
      }

      final response = await SupabaseService.signInWithGoogle();

      _supabaseUser = response.user;

      if (_supabaseUser != null) {
        await _ensureUserRecordForOAuth();
        await _loadUserData(force: true);

        debugPrint('[AUTH] Google sign-in successful: ${_supabaseUser!.email}');
        await AnalyticsService.logLogin(method: 'google', success: true);
        return true;
      }

      _setError('Google sign-in failed');
      return false;
    } on AuthException catch (e) {
      debugPrint('[AUTH] Google auth error: ${e.message}');

      if (e.message.contains('cancelled') || e.message.contains('canceled')) {
        debugPrint('[AUTH] User cancelled Google sign-in');
        return false;
      }

      _setError(e.message);
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    } catch (e) {
      debugPrint('[AUTH] Google sign-in unexpected error: $e');

      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancel') ||
          errorString.contains('sign_in_cancelled') ||
          errorString.contains('sign_in_canceled')) {
        debugPrint('[AUTH] User cancelled Google sign-in');
        return false;
      }

      _setError('Google sign-in failed. Please try again.');
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _ensureUserRecordForOAuth() async {
    if (_supabaseUser == null) return;

    try {
      final existing = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('id', _supabaseUser!.id)
          .maybeSingle();

      if (existing == null) {
        final metadata = _supabaseUser!.userMetadata;
        await SupabaseService.client.from('users').upsert({
          'id': _supabaseUser!.id,
          'email': _supabaseUser!.email,
          'full_name': metadata?['full_name'] ?? metadata?['name'] ?? '',
          'avatar_url': metadata?['avatar_url'] ?? metadata?['picture'] ?? '',
          'role': 'customer',
          'is_active': true,
          'email_verified': true,
          'phone_verified': false,
        });
        debugPrint('[AUTH] Created user record for OAuth user');
      }
    } catch (e) {
      debugPrint('[AUTH] Error ensuring OAuth user record: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);

      await SupabaseService.signOut();

      _resetState();
      debugPrint('[AUTH] Signed out successfully');
    } catch (e) {
      debugPrint('[AUTH] Error signing out: $e');
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client.auth.resetPasswordForEmail(email);

      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // APPLICATION METHODS
  // ============================================================

  Future<bool> applyAsMerchant({
    required String businessName,
    String? businessType,
    String? description,
    String? address,
    String? logoUrl,
  }) async {
    if (_supabaseUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Submitting merchant application...');

      final result = await SupabaseService.client.rpc(
        'apply_as_merchant',
        params: {
          'p_business_name': businessName,
          'p_business_type': businessType ?? 'general',
          'p_description': description,
          'p_address': address,
          'p_logo_url': logoUrl,
        },
      );

      debugPrint('[AUTH] Apply as merchant result: $result');

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        return false;
      }

      await _loadMerchantData();
      notifyListeners();

      debugPrint('[AUTH] Merchant application submitted successfully');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error applying as merchant: $e');
      _setError('Failed to submit application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyAsDriver({
    required String fullName,
    required String phone,
    String? vehicleType,
    String? vehiclePlate,
    String? licenseNumber,
    String? avatarUrl,
  }) async {
    if (_supabaseUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Submitting driver application...');

      final result = await SupabaseService.client.rpc(
        'apply_as_driver',
        params: {
          'p_full_name': fullName,
          'p_phone': phone,
          'p_vehicle_type': vehicleType ?? 'motorcycle',
          'p_vehicle_plate': vehiclePlate,
          'p_license_number': licenseNumber,
          'p_avatar_url': avatarUrl,
        },
      );

      debugPrint('[AUTH] Apply as driver result: $result');

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        return false;
      }

      await _loadDriverData();
      notifyListeners();

      debugPrint('[AUTH] Driver application submitted successfully');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error applying as driver: $e');
      _setError('Failed to submit application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitDriverApplication({
    required String licenseNumber,
    required String vehicleType,
    required String vehiclePlate,
    String? licenseImageUrl,
    String? vehicleImageUrl,
  }) async {
    if (_supabaseUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Submitting driver application (enhanced)...');

      await SupabaseService.client.from('drivers').upsert({
        'user_id': _supabaseUser!.id,
        'full_name': fullName ?? 'Driver',
        'phone': phone ?? '',
        'vehicle_type': vehicleType,
        'vehicle_plate': vehiclePlate,
        'license_number': licenseNumber,
        'license_image_url': licenseImageUrl,
        'vehicle_image_url': vehicleImageUrl,
        'is_active': true,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadDriverData();
      notifyListeners();

      debugPrint('[AUTH] Driver application submitted successfully');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error submitting driver application: $e');
      _setError('Failed to submit application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitMerchantApplication({
    required String businessName,
    required String businessType,
    required String description,
    required String address,
    required String phone,
    required String email,
  }) async {
    if (_supabaseUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('[AUTH] Submitting merchant application (enhanced)...');

      final result = await SupabaseService.client.rpc(
        'apply_as_merchant',
        params: {
          'p_business_name': businessName,
          'p_business_type': businessType,
          'p_description': description,
          'p_address': address,
          'p_logo_url': null,
        },
      );

      if (result is Map && result['error'] != null) {
        _setError(result['error'] as String);
        return false;
      }

      await _loadMerchantData();
      notifyListeners();

      debugPrint('[AUTH] Merchant application submitted successfully');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error submitting merchant application: $e');
      _setError('Failed to submit application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // PROFILE UPDATE
  // ============================================================

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_supabaseUser == null) {
      _setError('Not authenticated');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return true;

      await SupabaseService.client
          .from('users')
          .update(updates)
          .eq('id', _supabaseUser!.id);

      // Force reload after profile update
      await _loadUserData(force: true);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error updating profile: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _resetState() {
    _supabaseUser = null;
    _userModel = null;
    _merchant = null;
    _driver = null;
    _errorMessage = null;
    _lastUserRoleRefresh = null;
    _isRefreshingUserRole = false;
    _loadUserDataCompleter = null;
    debugPrint('[AUTH] State reset');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}