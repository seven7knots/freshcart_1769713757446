import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../l10n/generated/app_localizations.dart';

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

  final String _loadingText = 'Loading...';

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
    // Supabase + Firebase are already initialized in main() before runApp.
    // Navigate on the first frame with no artificial delay.
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToNextScreen());
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.initial);
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
          width: 35.w,
          height: 35.w,
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
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
              child: ClipOval(
                child: Image.asset(
                  'assets/images/kayan_logo-1770269431337.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  semanticLabel:
                      'KJ Delivery Services logo with professional branding',
                ),
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
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            AppLocalizations.of(context)!.fastReliableDelivery,
            style: GoogleFonts.inter(
              color: const Color(0xFFB3B3B3),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 0.5.h),
          Text(
            AppLocalizations.of(context)!.poweredByKjDelivery,
            style: GoogleFonts.inter(
              color: const Color(0xFF666666),
              fontSize: 9.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
