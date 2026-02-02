import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
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
  bool get isAdmin => _isAdmin;
  bool get isDriver => _isDriver;
  bool get isMerchant => _isMerchant;
  bool get isCustomer => !_isAdmin && !_isDriver && !_isMerchant;
  bool get emailVerified => _emailVerified;
  bool get phoneVerified => _phoneVerified;
  bool get isFullyVerified => _emailVerified && _phoneVerified;

  AuthProvider() {
    debugPrint('[AUTH_PROVIDER] 🔧 AuthProvider initialized');
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    try {
      debugPrint('[AUTH_PROVIDER] 🔍 Initializing auth state...');
      final session = SupabaseService.client.auth.currentSession;
      _currentUser = session?.user;
      debugPrint(
        '[AUTH_PROVIDER] 📋 Session: ${session != null ? "exists" : "null"}',
      );
      debugPrint('[AUTH_PROVIDER] 👤 User: ${_currentUser?.email ?? "none"}');
      debugPrint('[AUTH_PROVIDER] 🆔 User ID: ${_currentUser?.id ?? "none"}');

      // Check admin status if user is logged in
      if (_currentUser != null) {
        await _checkUserRole();
      }

      notifyListeners();

      // Listen to auth state changes
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        _currentUser = data.session?.user;
        debugPrint('[AUTH_PROVIDER] 🔄 Auth state changed');
        debugPrint(
          '[AUTH_PROVIDER] 👤 New user: ${_currentUser?.email ?? "logged out"}',
        );
        debugPrint('[AUTH_PROVIDER] 📊 Event: ${data.event.name}');

        // Check admin status on auth change
        if (_currentUser != null) {
          _checkUserRole();
        } else {
          _isAdmin = false;
          _isDriver = false;
          _isMerchant = false;
        }

        notifyListeners();
      });

      debugPrint('[AUTH_PROVIDER] ✅ Auth state initialization complete');
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] ❌ Error initializing: $e');
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) {
        _isAdmin = false;
        _isDriver = false;
        _isMerchant = false;
        return;
      }

      final response = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final role = response['role'] as String?;
        _isAdmin = role == 'admin';
        _isDriver = role == 'driver';
        _isMerchant = role == 'merchant';
        debugPrint(
            '[AUTH_PROVIDER] 🔐 User role: $role (admin: $_isAdmin, driver: $_isDriver, merchant: $_isMerchant)');
      } else {
        _isAdmin = false;
        _isDriver = false;
        _isMerchant = false;
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] ❌ Error checking user role: $e');
      _isAdmin = false;
      _isDriver = false;
      _isMerchant = false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] 🚀 SignIn attempt');
      debugPrint('[AUTH_PROVIDER] 📧 Email: $email');
      debugPrint('[AUTH_PROVIDER] 🔐 Password length: ${password.length}');

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = response.user;

      // Check admin status after successful login
      await _checkUserRole();

      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ✅ SignIn successful');
      debugPrint('[AUTH_PROVIDER] 👤 User: ${_currentUser?.email}');
      debugPrint('[AUTH_PROVIDER] 🆔 User ID: ${_currentUser?.id}');
      debugPrint('[AUTH_PROVIDER] 🔐 Is Admin: $_isAdmin');
      debugPrint(
        '[AUTH_PROVIDER] 📋 Session: ${response.session != null ? "created" : "null"}',
      );

      await AnalyticsService.logLogin(method: 'email', success: true);

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ❌ SignIn failed (AuthException)');
      debugPrint('[AUTH_PROVIDER] ⚠️ Error: ${e.message}');
      debugPrint('[AUTH_PROVIDER] 🔢 Status code: ${e.statusCode}');

      await AnalyticsService.logLogin(method: 'email', success: false);

      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ❌ SignIn failed (Exception)');
      debugPrint('[AUTH_PROVIDER] ⚠️ Error: $e');

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

      debugPrint('[AUTH_PROVIDER] 🚀 SignUp attempt');
      debugPrint('[AUTH_PROVIDER] 📧 Email: $email');
      debugPrint('[AUTH_PROVIDER] 👤 Full name: $fullName');
      debugPrint('[AUTH_PROVIDER] 📱 Phone: $phone');
      debugPrint('[AUTH_PROVIDER] 🔐 Password length: ${password.length}');

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      _currentUser = response.user;

      if (_currentUser != null) {
        // Send email OTP after signup
        try {
          await SupabaseService.client.rpc(
            'send_email_otp',
            params: {'user_email': email},
          );
          debugPrint('[AUTH_PROVIDER] ✅ Email OTP sent');
        } catch (e) {
          debugPrint('[AUTH_PROVIDER] ⚠️ Error sending email OTP: $e');
        }
      }

      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ✅ SignUp successful');
      debugPrint('[AUTH_PROVIDER] 👤 User: ${_currentUser?.email}');
      debugPrint('[AUTH_PROVIDER] 🆔 User ID: ${_currentUser?.id}');
      debugPrint(
        '[AUTH_PROVIDER] 📋 Session: ${response.session != null ? "created" : "null"}',
      );

      await AnalyticsService.logSignUp(method: 'email', success: true);

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ❌ SignUp failed (AuthException)');
      debugPrint('[AUTH_PROVIDER] ⚠️ Error: ${e.message}');
      debugPrint('[AUTH_PROVIDER] 🔢 Status code: ${e.statusCode}');

      await AnalyticsService.logSignUp(method: 'email', success: false);

      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ❌ SignUp failed (Exception)');
      debugPrint('[AUTH_PROVIDER] ⚠️ Error: $e');

      await AnalyticsService.logSignUp(method: 'email', success: false);

      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] 🚀 SignOut attempt');

      await SupabaseService.client.auth.signOut();

      _currentUser = null;
      _errorMessage = null;
      _isAdmin = false;
      _isDriver = false;
      _isMerchant = false;
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ✅ SignOut successful');
    } catch (e) {
      _errorMessage = 'Failed to sign out';
      _isLoading = false;
      notifyListeners();

      debugPrint('[AUTH_PROVIDER] ❌ SignOut failed');
      debugPrint('[AUTH_PROVIDER] ⚠️ Error: $e');
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return signIn(email, password);
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return signUp(email, password, fullName: fullName, phone: phone);
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

      // Track Google login
      await AnalyticsService.logLogin(method: 'google', success: true);

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'google', success: false);

      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'google', success: false);

      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.kjdelivery://login-callback/',
      );

      _isLoading = false;
      notifyListeners();

      // Track Apple login
      await AnalyticsService.logLogin(method: 'apple', success: true);

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'apple', success: false);

      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'apple', success: false);

      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.kjdelivery://login-callback/',
      );

      _isLoading = false;
      notifyListeners();

      // Track Facebook login
      await AnalyticsService.logLogin(method: 'facebook', success: true);

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'facebook', success: false);

      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();

      await AnalyticsService.logLogin(method: 'facebook', success: false);

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
    } catch (e) {
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
