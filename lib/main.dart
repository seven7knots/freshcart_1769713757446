import 'dart:async';
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
import './providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './l10n/generated/app_localizations.dart';

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

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  final authProvider = AuthProvider();
  final adminProvider = AdminProvider();
  final favoritesProvider = FavoritesProvider();

  // SESSION 44: Global Flutter error handler — sends to Crashlytics
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // SESSION 44: Global async error handler — catches auth network errors as non-fatal
  PlatformDispatcher.instance.onError = (error, stack) {
    // Auth token refresh failures on bad network — non-fatal, expected
    final msg = error.toString();
    if (msg.contains('AuthRetryableFetchException') ||
        msg.contains('ClientException') ||
        msg.contains('SocketException') ||
        msg.contains('connection abort')) {
      debugPrint('[AUTH] Network error (non-fatal): $msg');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      return true; // handled, don't crash
    }
    // Everything else — fatal
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
          provider.ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
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
        return provider.Consumer2<ThemeProvider, LocaleProvider>(
          builder: (context, themeProvider, localeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              title: 'KJ Delivery',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: AppRoutes.initial,
              onGenerateRoute: _guardedRoute,
              routes: AppRoutes.routes,
              builder: (context, child) {
                return Directionality(
                  textDirection: localeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
