"""
KJ Delivery — Session 43: Firebase Crashlytics Integration
Run from: C:\dev\kj_delivery_fresh
Command:  C:\Python314\python.exe patch_crashlytics.py
"""

import os
import sys

PROJECT = os.getcwd()

def patch_file(rel_path, old, new, label):
    full = os.path.join(PROJECT, rel_path)
    if not os.path.exists(full):
        print(f"[SKIP] {rel_path} not found")
        return False
    content = open(full, 'r', encoding='utf-8').read()
    if new.strip() in content:
        print(f"[SKIP] {label} — already applied")
        return True
    if old not in content:
        print(f"[FAIL] {label} — anchor text not found in {rel_path}")
        return False
    content = content.replace(old, new, 1)
    open(full, 'w', encoding='utf-8').write(content)
    print(f"[OK]   {label}")
    return True

def write_file(rel_path, content, label):
    full = os.path.join(PROJECT, rel_path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    open(full, 'w', encoding='utf-8').write(content)
    print(f"[OK]   {label}")
    return True

# ──────────────────────────────────────────────
# 1. pubspec.yaml — add firebase_crashlytics
# ──────────────────────────────────────────────
patch_file(
    'pubspec.yaml',
    '  firebase_messaging: ^16.1.1',
    '  firebase_crashlytics: ^4.3.2\n  firebase_messaging: ^16.1.1',
    'pubspec.yaml — added firebase_crashlytics'
)

# ──────────────────────────────────────────────
# 2. android/settings.gradle.kts — add crashlytics plugin
# ──────────────────────────────────────────────
patch_file(
    os.path.join('android', 'settings.gradle.kts'),
    'id("com.google.gms.google-services") version "4.4.2" apply false',
    'id("com.google.gms.google-services") version "4.4.2" apply false\n    id("com.google.firebase.crashlytics") version "3.0.3" apply false',
    'settings.gradle.kts — added crashlytics plugin'
)

# ──────────────────────────────────────────────
# 3. android/app/build.gradle.kts — apply crashlytics plugin
# ──────────────────────────────────────────────
patch_file(
    os.path.join('android', 'app', 'build.gradle.kts'),
    'id("com.google.gms.google-services")',
    'id("com.google.gms.google-services")\n    id("com.google.firebase.crashlytics")',
    'app/build.gradle.kts — applied crashlytics plugin'
)

# ──────────────────────────────────────────────
# 4. lib/main.dart — full replacement with Crashlytics
# ──────────────────────────────────────────────
MAIN_DART = r"""import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './providers/admin_provider.dart';
import './providers/auth_provider.dart';
import './providers/merchant_provider.dart';
import './providers/notifications_provider.dart';
import './providers/favorites_provider.dart';
import './providers/theme_provider.dart';
import './routes/app_routes.dart';
import './services/analytics_service.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import './widgets/custom_error_widget.dart';
import './utils/route_guard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase + Crashlytics (must be first) ──
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Enable Crashlytics collection
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Catch all Flutter framework errors
    FlutterError.onError = (errorDetails) {
      debugPrint('[CRASHLYTICS] Flutter error: ${errorDetails.exceptionAsString()}');
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Catch async errors not caught by Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[CRASHLYTICS] Platform error: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Analytics (non-blocking, runs after Crashlytics is ready)
    try {
      await AnalyticsService.initialize();
      debugPrint('Analytics initialized successfully');
    } catch (e) {
      debugPrint('Analytics init failed (non-fatal): $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, fatal: false);
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // ── Error widget (visual fallback for debug/release) ──
  bool hasShownError = false;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // ── Orientation lock ──
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // ── Supabase (critical path — app cannot run without it) ──
  try {
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current, fatal: true);
  }

  // ── Theme + providers ──
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final authProvider = AuthProvider();
  final adminProvider = AdminProvider();
  final favoritesProvider = FavoritesProvider();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          provider.ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          provider.ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // ── Post-frame: auth listeners + admin check ──
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[MAIN] Post-frame callback: Setting up auth listeners');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('[MAIN] Initial user check: ' + (currentUser?.email ?? 'not logged in'));

    // Set Crashlytics user identifier for crash grouping
    if (currentUser != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(currentUser.id);

      debugPrint('[MAIN] User already logged in, checking admin status...');
      adminProvider.checkAdminStatus(reason: 'app-startup-existing-session').then((_) {
        debugPrint('[MAIN] Initial admin status: ' + adminProvider.isAdmin.toString());
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        favoritesProvider.loadFavorites();
      });
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[MAIN] Supabase Auth Event: $event');
      debugPrint('[MAIN] Session exists: ${session != null}');
      debugPrint('[MAIN] User: ${session?.user.email ?? 'none'}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('[MAIN] User signed in, triggering admin check...');
        // Tag crashes with the signed-in user
        FirebaseCrashlytics.instance.setUserIdentifier(session.user.id);
        adminProvider.checkAdminStatus(reason: 'supabase-auth-signed-in').then((_) {
          debugPrint('[MAIN] Admin check complete: isAdmin=${adminProvider.isAdmin}');
        });
        favoritesProvider.loadFavorites();
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('[MAIN] User signed out');
        // Clear Crashlytics user on logout
        FirebaseCrashlytics.instance.setUserIdentifier('');
        favoritesProvider.clear();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('[MAIN] Token refreshed');
        adminProvider.checkAdminStatus(reason: 'token-refreshed');
      }
    });

    authProvider.addListener(() {
      debugPrint('[MAIN] AuthProvider listener triggered: isAuthenticated=${authProvider.isAuthenticated}');

      if (authProvider.isAuthenticated) {
        if (!adminProvider.isAdmin) {
          debugPrint('[MAIN] AuthProvider authenticated but not admin yet, checking...');
          adminProvider.checkAdminStatus(reason: 'auth-provider-listener');
        }
      }
    });

    SupabaseService.runtimeHealthCheck();

    debugPrint('[MAIN] Setup complete');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<dynamic>? _guardedRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.initial;

    final builder = AppRoutes.routes[routeName];
    if (builder == null) return null;

    final navContext = navigatorKey.currentContext;
    if (navContext == null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        RouteGuard.verifyAccess(navContext, routeName);
        return builder(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return provider.Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: 'FreshCart',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              initialRoute: AppRoutes.initial,
              onGenerateRoute: _guardedRoute,
              routes: AppRoutes.routes,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }
}
"""

write_file(os.path.join('lib', 'main.dart'), MAIN_DART, 'lib/main.dart — full replacement with Crashlytics')

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
print()
print('=' * 55)
print('  CRASHLYTICS PATCH COMPLETE')
print('=' * 55)
print()
print('Next steps:')
print('  1. flutter pub get')
print('  2. flutter run --dart-define=... -d GUHEAYS8JR4H9TVW')
print('  3. Verify "[CRASHLYTICS]" and "Firebase initialized"')
print('     appear in the debug logs')
print()
print('To test Crashlytics after successful run:')
print('  - Add this line temporarily in any onTap:')
print('    FirebaseCrashlytics.instance.crash();')
print('  - Run the app, tap the button, app will crash')
print('  - Check Firebase Console > Crashlytics in ~5 min')
print('  - REMOVE the crash() line after testing!')
print()
