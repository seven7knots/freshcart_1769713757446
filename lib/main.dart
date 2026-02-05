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
import './widgets/custom_error_widget.dart';
import './utils/route_guard.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom error widget with auto-hide
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

  // Lock portrait orientation on mobile
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Initialize Firebase and Analytics
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
    debugPrint('✅ Firebase and Analytics initialized successfully');
  } catch (e) {
    debugPrint('⚠️  Firebase initialization skipped or failed: $e');
  }

  // Initialize Supabase (CRITICAL - must succeed for app to work)
  try {
    await SupabaseService.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ CRITICAL: Failed to initialize Supabase: $e');
    // You might want to show an error screen here instead of continuing
  }

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Create providers early so we can set up listeners
  final authProvider = AuthProvider();
  final adminProvider = AdminProvider();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          provider.ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          provider.ChangeNotifierProvider(create: (_) => MerchantProvider()),
          provider.ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          provider.ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // ============================================================
  // POST-FRAME SETUP: Auth Listeners & Admin Status Check
  // ============================================================
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[MAIN] Post-frame callback: Setting up auth listeners');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Wait briefly for auth to fully settle
    await Future.delayed(const Duration(milliseconds: 500));
    
    // ============================================================
    // INITIAL CHECK: Handle existing sessions (user already logged in)
    // ============================================================
    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('[MAIN] Initial user check: ${currentUser?.email ?? 'not logged in'}');
    
    if (currentUser != null) {
      debugPrint('[MAIN] 🔐 User already logged in, checking admin status...');
      await adminProvider.checkAdminStatus(reason: 'app-startup-existing-session');
      debugPrint('[MAIN] Initial admin status: ${adminProvider.isAdmin}');
    } else {
      debugPrint('[MAIN] 👤 No existing session');
    }

    // ============================================================
    // CRITICAL: Supabase Auth State Listener
    // This is the PRIMARY way to detect login/logout events
    // ============================================================
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[MAIN] 🔥 Supabase Auth Event: $event');
      debugPrint('[MAIN] Session exists: ${session != null}');
      debugPrint('[MAIN] User: ${session?.user.email ?? 'none'}');
      debugPrint('[MAIN] User ID: ${session?.user.id ?? 'none'}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Handle different auth events
      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('[MAIN] ✅ User signed in, triggering admin check...');
        
        // CRITICAL: Check admin status after successful login
        adminProvider.checkAdminStatus(reason: 'supabase-auth-signed-in').then((_) {
          debugPrint('[MAIN] Admin check complete: isAdmin=${adminProvider.isAdmin}');
          
          // Optional: Navigate to appropriate screen based on admin status
          // if (adminProvider.isAdmin) {
          //   navigatorKey.currentState?.pushReplacementNamed('/admin');
          // }
        }).catchError((error) {
          debugPrint('[MAIN] ❌ Admin check failed: $error');
        });
        
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('[MAIN] 🚪 User signed out');
        // Admin status will reset to false automatically on next check
        // Optional: Clear admin provider state explicitly
        // adminProvider.clearAdminData();
        
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('[MAIN] 🔄 Token refreshed');
        // Optionally re-verify admin status when token refreshes
        // This ensures admin privileges stay current
        adminProvider.checkAdminStatus(reason: 'token-refreshed');
        
      } else if (event == AuthChangeEvent.userUpdated) {
        debugPrint('[MAIN] 👤 User data updated');
        // Re-check admin status if user metadata changed
        adminProvider.checkAdminStatus(reason: 'user-updated');
        
      } else {
        debugPrint('[MAIN] ℹ️  Other auth event: $event');
      }
    });

    // ============================================================
    // BACKUP: AuthProvider Listener (Secondary check)
    // This catches cases where AuthProvider updates independently
    // ============================================================
    authProvider.addListener(() {
      debugPrint('[MAIN] 📢 AuthProvider listener triggered: isAuthenticated=${authProvider.isAuthenticated}');
      
      if (authProvider.isAuthenticated) {
        // Only check if we don't already know they're admin
        // This prevents redundant checks
        if (!adminProvider.isAdmin) {
          debugPrint('[MAIN] AuthProvider authenticated but not admin yet, checking...');
          adminProvider.checkAdminStatus(reason: 'auth-provider-listener');
        }
      } else {
        debugPrint('[MAIN] User not authenticated (via AuthProvider)');
      }
    });

    // ============================================================
    // HEALTH CHECK: Verify Supabase connection
    // ============================================================
    try {
      final result = await SupabaseService.runtimeHealthCheck();
      debugPrint('[MAIN] Health check result: $result');
      
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result, style: const TextStyle(fontSize: 12)),
            duration: const Duration(seconds: 5),
            backgroundColor: result.contains('✅') ? cs.primary : cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[MAIN] ❌ Health check failed: $e');
    }
    
    debugPrint('[MAIN] ✅ Setup complete');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
        // Route guard will verify access and redirect if needed
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
              // Keep routes map for compatibility with existing code
              routes: AppRoutes.routes,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    // Lock text scaling to 1.0 for consistent UI
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
