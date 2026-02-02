import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isInitialized = false;
  String _loadingText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse animation for logo glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Shimmer animation for loading indicator
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo scale animation with smooth curve
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Pulse animation for glow effect
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoAnimationController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization tasks
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _loadingText = 'Loading preferences...';
      });
      await _loadUserPreferences();

      setState(() {
        _loadingText = 'Checking location...';
      });
      await _checkLocationPermissions();

      setState(() {
        _loadingText = 'Preparing your delivery...';
      });
      await _prepareCachedData();

      setState(() {
        _loadingText = 'Almost ready...';
      });
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _isInitialized = true;
      });

      // Navigate after initialization
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();
    } catch (e) {
      // Handle initialization errors
      _showRetryOption();
    }
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _checkLocationPermissions() async {
    // Simulate checking location permissions
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached product data
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _navigateToNextScreen() async {
    try {
      // Check actual Supabase authentication state
      final session = SupabaseService.client.auth.currentSession;
      final bool isAuthenticated = session != null;

      // Check if first time (this would use SharedPreferences in production)
      final bool isFirstTime = false; // Set to false to skip onboarding for now

      if (isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home-screen');
      } else if (isFirstTime) {
        Navigator.pushReplacementNamed(context, '/onboarding-screen');
      } else {
        Navigator.pushReplacementNamed(context, '/authentication-screen');
      }
    } catch (e) {
      // On error, navigate to authentication
      Navigator.pushReplacementNamed(context, '/authentication-screen');
    }
  }

  void _showRetryOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Connection Issue',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Unable to initialize the app. Please check your connection and try again.',
          style: GoogleFonts.inter(
            color: const Color(0xFFB3B3B3),
            fontSize: 12.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background particles
              _buildBackgroundParticles(),

              // Main content
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App logo with animation
                          AnimatedBuilder(
                            animation: _logoAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Opacity(
                                  opacity: _logoOpacityAnimation.value,
                                  child: _buildAppLogo(),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 6.h),

                          // Loading indicator and text
                          _buildLoadingSection(),
                        ],
                      ),
                    ),
                  ),

                  // Bottom branding
                  _buildBottomBranding(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFE50914).withValues(alpha: 0.3),
                const Color(0xFFE50914).withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(
                  color: const Color(0xFFE50914),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    color: const Color(0xFFE50914),
                    size: 10.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'KJ',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'DELIVERY',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE50914),
                      fontWeight: FontWeight.w700,
                      fontSize: 8.sp,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Modern loading indicator with shimmer effect
        AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              width: 40.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _shimmerAnimation.value * 40.w,
                    child: Container(
                      width: 15.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFE50914).withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        SizedBox(height: 3.h),

        // Loading text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _loadingText,
            key: ValueKey(_loadingText),
            style: GoogleFonts.inter(
              color: const Color(0xFFB3B3B3),
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Stack(
          children: [
            // Delivery icon particle
            Positioned(
              top: 20.h + (_shimmerAnimation.value * 5.h),
              left: 15.w,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.local_shipping,
                  color: const Color(0xFFE50914),
                  size: 5.w,
                ),
              ),
            ),

            // Package icon particle
            Positioned(
              top: 30.h - (_shimmerAnimation.value * 3.h),
              right: 20.w,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.inventory_2,
                  color: const Color(0xFFE50914),
                  size: 4.w,
                ),
              ),
            ),

            // Location icon particle
            Positioned(
              bottom: 35.h + (_shimmerAnimation.value * 4.h),
              left: 25.w,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.location_on,
                  color: const Color(0xFFE50914),
                  size: 4.5.w,
                ),
              ),
            ),

            // Timer icon particle
            Positioned(
              bottom: 40.h - (_shimmerAnimation.value * 2.h),
              right: 18.w,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.access_time,
                  color: const Color(0xFFE50914),
                  size: 3.5.w,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBranding() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Column(
        children: [
          Text(
            'Fast & Reliable Delivery',
            style: GoogleFonts.inter(
              color: const Color(0xFFB3B3B3),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Powered by KJ Delivery',
            style: GoogleFonts.inter(
              color: const Color(0xFF666666),
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
