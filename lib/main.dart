import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import './providers/admin_provider.dart';
import './providers/auth_provider.dart';
import './providers/merchant_provider.dart';
import './providers/notifications_provider.dart';
import './providers/theme_provider.dart';
import './routes/app_routes.dart';
import './services/analytics_service.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import './widgets/custom_error_widget.dart';
import './utils/route_guard.dart';

// Global navigator key for route protection
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------
  // Custom error handling
  // --------------------
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

  // --------------------
  // Orientation lock (mobile only)
  // --------------------
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // --------------------
  // Firebase initialization
  // --------------------
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
    debugPrint('✅ Firebase and Analytics initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization skipped or failed: $e');
  }

  // --------------------
  // Supabase initialization
  // --------------------
  try {
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // --------------------
  // Theme initialization (IMPORTANT: load prefs before first frame)
  // --------------------
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // --------------------
  // Run app with Provider + Riverpod
  // --------------------
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
          provider.ChangeNotifierProvider(create: (_) => AdminProvider()),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(
              create: (_) => NotificationsProvider()),
          // Provide the already-initialized ThemeProvider instance
          provider.ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // --------------------
  // Runtime health check (post-frame) with theme-aware UI feedback
  // --------------------
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final result = await SupabaseService.runtimeHealthCheck();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final cs = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result,
            style: const TextStyle(fontSize: 12),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: result.contains('✅') ? cs.primary : cs.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              routes: AppRoutes.routes,
              onGenerateRoute: (settings) {
                final routeName = settings.name ?? AppRoutes.initial;

                final navContext = navigatorKey.currentContext;
                if (navContext != null) {
                  final authProvider = provider.Provider.of<AuthProvider>(
                    navContext,
                    listen: false,
                  );

                  if (RouteGuard.isAdminRoute(routeName)) {
                    if (!authProvider.isAdmin) {
                      final redirectRoute =
                          RouteGuard.getHomeRouteForRole(authProvider);
                      return MaterialPageRoute(
                        builder: AppRoutes.routes[redirectRoute]!,
                        settings: RouteSettings(name: redirectRoute),
                      );
                    }
                  }

                  if (RouteGuard.isDriverRoute(routeName)) {
                    if (!authProvider.isDriver && !authProvider.isAdmin) {
                      return MaterialPageRoute(
                        builder: AppRoutes.routes[AppRoutes.home]!,
                        settings: const RouteSettings(name: AppRoutes.home),
                      );
                    }
                  }
                }

                return null;
              },
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
