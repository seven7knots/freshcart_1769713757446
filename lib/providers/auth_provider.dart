import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/analytics_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  String? _role;
  bool _isAdmin = false;
  bool _isDriver = false;
  bool _isMerchant = false;

  final bool _emailVerified = false;
  final bool _phoneVerified = false;

  User? get currentUser => _currentUser;
  User? get user => _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  String? get role => _role;
  bool get isAdmin => _isAdmin;
  bool get isDriver => _isDriver;
  bool get isMerchant => _isMerchant;
  bool get isCustomer => !_isAdmin && !_isDriver && !_isMerchant;

  bool get emailVerified => _emailVerified;
  bool get phoneVerified => _phoneVerified;
  bool get isFullyVerified => _emailVerified && _phoneVerified;

  AuthProvider() {
    debugPrint('[AUTH_PROVIDER] AuthProvider initialized');
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      _currentUser = session?.user;

      if (_currentUser != null) {
        await refreshUserRole();
      } else {
        _resetRoleFlags();
      }

      notifyListeners();

      SupabaseService.client.auth.onAuthStateChange.listen((data) async {
        _currentUser = data.session?.user;
        debugPrint('[AUTH_PROVIDER] Auth state changed: ${data.event.name}');

        if (_currentUser != null) {
          await refreshUserRole();
        } else {
          _resetRoleFlags();
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error initializing: $e');
      _resetRoleFlags();
      notifyListeners();
    }
  }

  void _resetRoleFlags() {
    _role = null;
    _isAdmin = false;
    _isDriver = false;
    _isMerchant = false;
  }

  void _applyRole(String? role) {
    debugPrint('[AUTH_PROVIDER] _applyRole called with: "$role"');
    
    final normalized = (role ?? '').trim().toLowerCase();
    debugPrint('[AUTH_PROVIDER] After normalize: "$normalized"');

    _role = normalized.isEmpty ? null : normalized;

    _isAdmin = normalized == 'admin';
    _isDriver = normalized == 'driver';
    _isMerchant = normalized == 'merchant';

    debugPrint('[AUTH_PROVIDER] Role flags set:');
    debugPrint('[AUTH_PROVIDER]    _role = $_role');
    debugPrint('[AUTH_PROVIDER]    _isAdmin = $_isAdmin');
    debugPrint('[AUTH_PROVIDER]    _isDriver = $_isDriver');
    debugPrint('[AUTH_PROVIDER]    _isMerchant = $_isMerchant');
  }

  Future<void> refreshUserRole() async {
    debugPrint('[AUTH_PROVIDER] ======= refreshUserRole START =======');
    try {
      final userId = _currentUser?.id;
      debugPrint('[AUTH_PROVIDER] Current user ID: $userId');
      
      if (userId == null) {
        debugPrint('[AUTH_PROVIDER] User ID is null, resetting roles');
        _resetRoleFlags();
        return;
      }

      debugPrint('[AUTH_PROVIDER] Querying database for user role...');
      final row = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('[AUTH_PROVIDER] Database returned: $row');

      if (row == null) {
        debugPrint('[AUTH_PROVIDER] No row found in database, resetting roles');
        _resetRoleFlags();
        return;
      }

      final roleValue = row['role'];
      debugPrint('[AUTH_PROVIDER] Role value from database: "$roleValue" (type: ${roleValue.runtimeType})');
      
      _applyRole(roleValue as String?);
      debugPrint('[AUTH_PROVIDER] ======= refreshUserRole END =======');
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] ERROR refreshing user role: $e');
      _resetRoleFlags();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] Attempting sign in for: $email');

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      debugPrint('[AUTH_PROVIDER] Sign in successful, user ID: ${_currentUser?.id}');
      
      await refreshUserRole();

      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] Sign in complete. isAdmin: $_isAdmin');

      await AnalyticsService.logLogin(method: 'email', success: true);
      return true;
    } on AuthException catch (e) {
      debugPrint('[AUTH_PROVIDER] Auth error: ${e.message}');
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logLogin(method: 'email', success: false);
      return false;
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Unexpected error: $e');
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logLogin(method: 'email', success: false);
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      _currentUser = response.user;

      await refreshUserRole();

      if (_currentUser != null) {
        try {
          await SupabaseService.client.rpc(
            'send_email_otp',
            params: {'user_email': email},
          );
        } catch (_) {}
      }

      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logSignUp(method: 'email', success: true);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logSignUp(method: 'email', success: false);
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logSignUp(method: 'email', success: false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await SupabaseService.client.auth.signOut();

      _currentUser = null;
      _errorMessage = null;
      _resetRoleFlags();

      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Failed to sign out';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.kjdelivery://login-callback/',
      );

      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'google', success: true);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logLogin(method: 'google', success: false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.kjdelivery://reset-password/',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}