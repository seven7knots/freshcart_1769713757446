import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/analytics_service.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  String? _role; // source of truth from public.users.role
  bool _isAdmin = false;
  bool _isDriver = false;
  bool _isMerchant = false;

  // Keeping these as-is; wire later when you implement real verification logic.
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
    final normalized = (role ?? '').trim().toLowerCase();

    _role = normalized.isEmpty ? null : normalized;

    _isAdmin = normalized == 'admin';
    _isDriver = normalized == 'driver';
    _isMerchant = normalized == 'merchant';

    debugPrint('[AUTH_PROVIDER] Role applied: $_role');
  }

  /// Public method so RouteGuard / screens can force-refresh role state.
  /// Source of truth: public.users.role
  Future<void> refreshUserRole() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        _resetRoleFlags();
        return;
      }

      final row = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        _resetRoleFlags();
        return;
      }

      _applyRole(row['role'] as String?);
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error refreshing user role: $e');
      _resetRoleFlags();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      await refreshUserRole();

      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'email', success: true);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      await AnalyticsService.logLogin(method: 'email', success: false);
      return false;
    } catch (_) {
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

      // Role may not exist yet in public.users (depends on your trigger).
      // Refresh anyway to keep state consistent.
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
