import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/locale_provider.dart';
import '../../l10n/generated/app_localizations.dart';

/// AuthGateScreen - Routes authenticated users to their role-specific home screen.
///
/// Flow:
/// 1. Not logged in → Authentication screen
/// 2. Logged in, email NOT verified (customer/merchant) → Email OTP verification screen
/// 3. Logged in, verified → Home (role-based)
///
/// Phone collection moved to checkout (first order).
/// Phone OTP removed (reactivated with WhatsApp in v1.1.1).
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  StreamSubscription<AuthState>? _authSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
      // Set up auth listener here so Supabase is guaranteed initialized.
      // On fast devices initState runs before SupabaseService.initialize()
      // completes, causing "You must initialize the supabase instance" crash.
      try {
        Supabase.instance;
      } catch (e) {
        debugPrint('[AUTH_GATE] Supabase not initialized for auth listener: $e');
        return;
      }
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_navigated) {
        if (data.event == AuthChangeEvent.signedOut) {
          debugPrint('[AUTH_GATE] signedOut after navigation – redirecting to auth');
          _navigated = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAuthAndNavigate();
          });
        }
        return;
      }

      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint('[AUTH_GATE] signedIn event – triggering navigation');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAuthAndNavigate();
        });
      }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _navigated) return;

    debugPrint('[AUTH_GATE] _checkAuthAndNavigate started');

    // Check if user has seen onboarding (first install check).
    // Only show onboarding for truly new installs (no session + no flag).
    // Existing users who update the app already have a session, so they
    // skip onboarding and the flag is set automatically.
    // ── Language selection check (first launch) ──
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      if (!localeProvider.hasChosenLanguage) {
        bool hasSession = false;
        try {
          hasSession = Supabase.instance.client.auth.currentSession != null;
        } catch (_) {
          hasSession = false;
        }
        if (!hasSession && mounted && !_navigated) {
          debugPrint('[AUTH_GATE] No language chosen -> language selection');
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
          return;
        } else {
          // Existing user updating app — mark language as chosen
          await localeProvider.markLanguageChosen();
        }
      }
    } catch (e) {
      debugPrint('[AUTH_GATE] Language check failed: $e');
    }

    if (!mounted || _navigated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        final hasSession = Supabase.instance.client.auth.currentSession != null;
        if (hasSession) {
          // Existing user updating the app — set flag, skip onboarding
          await prefs.setBool('has_seen_onboarding', true);
          debugPrint('[AUTH_GATE] Existing user — skipping onboarding, flag set');
        } else if (mounted && !_navigated) {
          // Truly new install — show onboarding
          debugPrint('[AUTH_GATE] First install -> onboarding screen');
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
          return;
        }
      }
    } catch (e) {
      debugPrint('[AUTH_GATE] Onboarding check failed: \$e');
    }

    // Guard against deactivated widget — fast devices can trigger navigation
    // callbacks after the widget tree has already been torn down.
    if (!mounted || _navigated) return;

    // Supabase is already initialized in main() before runApp(),
    // so no polling needed here. Just verify it's ready.
    try {
      Supabase.instance;
    } catch (_) {
      debugPrint('[AUTH_GATE] Supabase not initialized \u2014 aborting');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for AuthProvider to finish its own initialization.
    // Poll every 200ms (instead of 100ms) to reduce scheduling pressure.
    int attempts = 0;
    while (!authProvider.isInitialized && attempts < 25) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _navigated) return;
      attempts++;
    }

    if (!authProvider.isInitialized) {
      debugPrint('[AUTH_GATE] AuthProvider failed to initialize after 5s');
    }

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    // ── Not logged in → auth screen ──
    if (session == null || user == null) {
      debugPrint('[AUTH_GATE] No session → authentication screen');
      _navigated = true;
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.authentication);
      }
      return;
    }

    if (!mounted || _navigated) return;

    final userRole = authProvider.role;
    final skipEmailCheck = userRole == 'driver' || userRole == 'admin';

    // ── Email not verified → email OTP screen ──
    // Google sign-in users have email_verified = true at creation.
    // Drivers/admins skip this check.
    final emailVerified = authProvider.emailVerified;
    if (!emailVerified && !skipEmailCheck) {
      debugPrint('[AUTH_GATE] Email not verified → email OTP screen');
      _navigated = true;
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.emailOtpVerification);
      }
      return;
    }

    // ── Verified → role-based home ──
    final targetRoute = authProvider.getHomeRouteForUser();
    debugPrint('[AUTH_GATE] Navigating to: $targetRoute (role=$userRole)');
    _navigated = true;
    if (mounted) {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.loading ?? 'Loading...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}