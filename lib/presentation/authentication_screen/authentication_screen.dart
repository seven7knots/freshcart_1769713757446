// ============================================================
// FILE: lib/presentation/authentication_screen/authentication_screen.dart
// ============================================================
// REDESIGNED: Gradient background, glassmorphism form overlay,
// elegant white-on-dark text, all form logic preserved.
//
// UPDATED: Removed OTP verification redirect after signup.
// After signup → AuthGate → checks phone → home.
// After Google sign-in → AuthGate → checks phone → home.
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/signup_form_widget.dart';
import './widgets/social_login_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    AnalyticsService.logScreenView(screenName: 'authentication_screen');

    // Force light status bar icons on dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Called after successful signup or Google sign-in.
  /// Routes through AuthGate which checks if phone is present.
  void _navigateToAuthGate() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.initial, // AuthGate route
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // LAYER 1: Full-screen gradient background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFFF6F00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // LAYER 2: Dark gradient overlay for readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.25, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // LAYER 3: Content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  SizedBox(height: 1.5.h),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/kayan_logo-1770269431337.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 10.w,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            AppLocalizations.of(context)!.kjDelivery,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 0.5.h),
          Text(
            AppLocalizations.of(context)!.aWorldOfChoiceDelivered,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 6),
              ],
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TabBar(
            controller: _tabController,
            onTap: (index) {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = index);
            },
            tabs: [
              Tab(text: AppLocalizations.of(context)!.login),
              Tab(text: AppLocalizations.of(context)!.signUp),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.55),
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            indicator: BoxDecoration(
              color: AppTheme.kjRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppTheme.kjRed.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(3),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        _tabController.animateTo(index);
      },
      children: [_buildLoginTab(), _buildSignupTab()],
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.welcomeBack,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  AppLocalizations.of(context)!.signInToYourAccountTo,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.7),
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),
                LoginFormWidget(
                  onLoginPressed: () {
                    debugPrint('[AUTH_SCREEN] Login success → AuthGate');
                    _navigateToAuthGate();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          SocialLoginWidget(),
          SizedBox(height: 2.h),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildSignupTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.createAccount,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 0.5.h),
                Text(
                  AppLocalizations.of(context)!.joinKjDeliveryAndStartYour,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.7),
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 3.h),
                SignupFormWidget(
                  onSignupPressed: () {
                    // UPDATED: Go to AuthGate instead of OTP screen.
                    // AuthGate will check if phone is present (it is,
                    // since signup form requires it) and route to home.
                    debugPrint('[AUTH_SCREEN] Signup success → AuthGate');
                    _navigateToAuthGate();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          SocialLoginWidget(),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}