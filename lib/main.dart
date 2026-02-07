import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
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
import './providers/theme_provider.dart';
import './routes/app_routes.dart';
import './services/analytics_service.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import './utils/route_guard.dart';
import './widgets/custom_error_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
StreamSubscription<AuthState>? _supabaseAuthSub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Firebase is kept (no auth usage)
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
  } catch (_) {
    // best-effort only
  }

  await SupabaseService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final authProvider = AuthProvider();
  final adminProvider = AdminProvider();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
          ),
          provider.ChangeNotifierProvider<AdminProvider>.value(
            value: adminProvider,
          ),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          provider.ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Initial role resolve
    if (Supabase.instance.client.auth.currentUser != null) {
      await adminProvider.refreshRoles(reason: 'app-start-existing-session');
    } else {
      await adminProvider.refreshRoles(reason: 'app-start-no-session');
    }

    await _supabaseAuthSub?.cancel();
    _supabaseAuthSub =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      final shouldResolve =
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated;

      if (shouldResolve) {
        adminProvider.refreshRoles(reason: 'supabase-auth-$event');
        return;
      }

      if (event == AuthChangeEvent.signedOut) {
        adminProvider.refreshRoles(reason: 'supabase-auth-signedOut');
      }
    });

    authProvider.addListener(() {
      adminProvider.refreshRoles(reason: 'auth-provider-listener');
    });
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
          builder: (context, themeProvider, _) {
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
