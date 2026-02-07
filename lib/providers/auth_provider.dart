// ============================================================
// FILE: lib/providers/auth_provider.dart
// ============================================================
// Unified authentication provider with complete role management
// Handles: auth state, role detection, merchant/driver status
// NOW WITH: Partnership application system integration
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

  /// Current user role (display only)
  /// ⚠️ DO NOT USE FOR AUTHORIZATION - Admin must come from AdminProvider.isAdmin
  String get role => _userModel?['role'] as String? ?? 'customer';
  String? get roleString => _userModel?['role'] as String?;

  /// Merchant is "approved" when merchants.status == 'approved'
  /// (do not rely on users.role == 'merchant' because Model A allows admin+merchant)
  bool get isMerchant => _merchantStatusLower == 'approved';

  /// Driver is approved when drivers.is_verified == true OR users.role == 'driver'
  bool get isDriver {
    if (_userModel?['role'] == 'driver') return true;
    return (_driver?['is_verified'] as bool? ?? false) == true;
  }

  /// Check if user is admin (this checks role only, NOT AdminProvider)
  /// For true admin authorization, always use AdminProvider.isAdmin
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

  /// Merchant application statuses
  bool get hasPendingMerchantApplication => merchantStatus == 'pending';
  bool get hasApprovedMerchantApplication => merchantStatus == 'approved';
  bool get hasRejectedMerchantApplication => merchantStatus == 'rejected';

  /// Driver application statuses
  bool get hasPendingDriverApplication {
    final verified = (_driver?['is_verified'] as bool?) == true;
    final active = (_driver?['is_active'] as bool?) == true;
    return !verified && active;
  }
  
  bool get hasApprovedDriverApplication {
    return (_driver?['is_verified'] as bool? ?? false) == true;
  }
  
  bool get hasRejectedDriverApplication {
    // In your Supabase schema, you might track this differently
    // This is a placeholder - adjust based on your actual schema
    final verified = (_driver?['is_verified'] as bool?) == true;
    final active = (_driver?['is_active'] as bool?) == false;
    final exists = _driver != null;
    return exists && !verified && !active;
  }

  /// Can user apply for roles?
  bool get canApplyAsMerchant {
    // Can apply if: no merchant record, or status is none/rejected
    if (_merchant == null) return true;
    return merchantStatus == 'none' || merchantStatus == 'rejected';
  }

  bool get canApplyAsDriver {
    // Can apply if: no driver record, or not verified and not active
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
    // Prefer DB status field if present
    final status = _merchant?.status;
    if (status != null && status.toString().trim().isNotEmpty) {
      return status.toString().toLowerCase();
    }

    // Backward compatibility: if Merchant model only has isVerified/isActive
    // Map to statuses:
    // verified => approved
    // active but not verified => pending
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
        await _loadUserData();
      } else {
        debugPrint('[AUTH] No existing session');
        _resetState();
      }

      _isInitialized = true;
      notifyListeners();

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
          await _loadUserData();
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
          // Refresh user data (roles/merchant status can change without a new session)
          await _loadUserData();
          notifyListeners();
        }
        break;

      case AuthChangeEvent.userUpdated:
        _supabaseUser = session?.user;
        await _loadUserData();
        notifyListeners();
        break;

      default:
        debugPrint('[AUTH] Unhandled event: $event');
    }
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadUserData() async {
    if (_supabaseUser == null) return;

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

      debugPrint('[AUTH] User data loaded completely');
      debugPrint('[AUTH] role: $role, merchantStatus: $merchantStatus, isMerchant: $isMerchant, isDriver: $isDriver');
      debugPrint('[AUTH] ⚠️ For admin status, use AdminProvider.isAdmin');
    } catch (e) {
      debugPrint('[AUTH] Error loading user data: $e');
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

  /// Refresh user role and application data from database
  Future<void> refreshUserRole() async {
    debugPrint('[AUTH] Refreshing user role...');
    await _loadUserData();
    notifyListeners();
  }

  Future<void> refreshRoleData() => refreshUserRole();

  // ============================================================
  // ROUTE DETERMINATION (NEW)
  // ============================================================

  /// Get the appropriate home route based on user role
  /// Used by AuthGateScreen to route users to their correct interface
  String getHomeRouteForUser() {
    // Import AppRoutes in your actual file
    // For this example, using string literals
    
    if (role == 'admin') {
      // Admin sees the regular customer interface by default
      // but has access to admin panel, merchant dashboard, and driver mode
      return '/main-layout'; // AppRoutes.mainLayout
    } else if (role == 'driver' || isDriver) {
      // Driver goes directly to driver home
      return '/driver-home-screen'; // AppRoutes.driverHome
    } else if (role == 'merchant' || isMerchant) {
      // Merchant goes to merchant dashboard
      return '/merchant-dashboard-screen'; // AppRoutes.merchantDashboard
    } else {
      // Regular customer
      return '/main-layout'; // AppRoutes.mainLayout
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
        await _loadUserData();
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
          'phone': phone,
        },
      );

      _supabaseUser = response.user;

      if (_supabaseUser != null) {
        await _createUserRecord(fullName: fullName, phone: phone);
        await _loadUserData();

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

  Future<void> _createUserRecord({String? fullName, String? phone}) async {
    if (_supabaseUser == null) return;

    try {
      await SupabaseService.client.from('users').upsert({
        'id': _supabaseUser!.id,
        'email': _supabaseUser!.email,
        'full_name': fullName,
        'phone': phone,
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

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.freshcart://login-callback/',
      );

      await AnalyticsService.logLogin(method: 'google', success: true);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await SupabaseService.client.auth.signOut();
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

      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.freshcart://reset-password/',
      );

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
  // APPLICATION METHODS (ENHANCED WITH SUPABASE RPC)
  // ============================================================

  /// Submit merchant application using existing Supabase RPC
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

      // Reload merchant data to get new status
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

  /// Submit driver application using existing Supabase RPC
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

      // Reload driver data to get new status
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

  // ============================================================
  // ALTERNATIVE: Submit driver application (NEW - ENHANCED)
  // If you want more control or don't have the RPC function
  // ============================================================

  /// Enhanced driver application submission with image support
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

      // Create or update driver record with pending status
      await SupabaseService.client.from('drivers').upsert({
        'user_id': _supabaseUser!.id,
        'full_name': fullName ?? 'Driver',
        'phone': phone ?? '',
        'vehicle_type': vehicleType,
        'vehicle_plate': vehiclePlate,
        'license_number': licenseNumber,
        'license_image_url': licenseImageUrl,
        'vehicle_image_url': vehicleImageUrl,
        'is_active': true, // Pending status
        'is_verified': false, // Not approved yet
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload driver data
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

  /// Enhanced merchant application submission
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

      // Use the existing RPC or create merchant record
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

      await _loadUserData();
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

