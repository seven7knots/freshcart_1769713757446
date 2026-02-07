import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';

/// AuthGateScreen - Routes authenticated users to their role-specific home screen
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
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _navigated = false; // allow re-route on auth change
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _navigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait briefly for providers to initialize
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted || _navigated) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    if (session == null || user == null) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, AppRoutes.authentication);
      return;
    }

    await authProvider.refreshUserRole();

    if (!mounted || _navigated) return;

    final targetRoute = authProvider.getHomeRouteForUser();
    _navigated = true;
    Navigator.pushReplacementNamed(context, targetRoute);
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
              'Loading...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
