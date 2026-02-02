import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/analytics_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/signup_form_widget.dart';
import './widgets/social_login_widget.dart';

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
    debugPrint('[AUTH_SCREEN] 🔧 AuthenticationScreen initialized');
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Track authentication screen view
    AnalyticsService.logScreenView(screenName: 'authentication_screen');
    debugPrint('[AUTH_SCREEN] 📊 Analytics: screen view logged');
  }

  @override
  void dispose() {
    debugPrint('[AUTH_SCREEN] 🗑️ AuthenticationScreen disposed');
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      debugPrint(
        '[AUTH_SCREEN] 🔄 Tab changing to index: ${_tabController.index}',
      );
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[AUTH_SCREEN] 🎨 Building authentication UI');
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            debugPrint('[AUTH_SCREEN] ⌨️ Keyboard dismissed');
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      child: Column(
        children: [
          // App Logo
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'shopping_cart',
                size: 10.w,
                color: AppTheme.lightTheme.colorScheme.onPrimary,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'KJ Delivery',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            "A world of choice, delivered.",
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          debugPrint(
            '[AUTH_SCREEN] 👆 Tab tapped: ${index == 0 ? "Login" : "Sign Up"}',
          );
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
        labelColor: AppTheme.lightTheme.colorScheme.onPrimary,
        unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        labelStyle: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.lightTheme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(1.w),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildTabContent() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        debugPrint(
          '[AUTH_SCREEN] 📱 Page changed to: ${index == 0 ? "Login" : "Sign Up"}',
        );
        setState(() {
          _currentIndex = index;
        });
        _tabController.animateTo(index);
      },
      children: [_buildLoginTab(), _buildSignupTab()],
    );
  }

  Widget _buildLoginTab() {
    debugPrint('[AUTH_SCREEN] 🔑 Building login tab');
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Sign in to your account to continue shopping',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          LoginFormWidget(
            onLoginPressed: () {
              debugPrint('[AUTH_SCREEN] ✅ Login success callback triggered');
            },
          ),
          SizedBox(height: 4.h),
          SocialLoginWidget(),
          SizedBox(height: 3.h),
          _buildMockCredentialsInfo(),
        ],
      ),
    );
  }

  Widget _buildSignupTab() {
    debugPrint('[AUTH_SCREEN] ✍️ Building signup tab');
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Join KJ Delivery and start your grocery journey',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          SignupFormWidget(
            onSignupPressed: () {
              debugPrint(
                '[AUTH_SCREEN] ✅ Signup success, navigating to email verification',
              );
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.emailOtpVerification,
              );
            },
          ),
          SizedBox(height: 4.h),
          SocialLoginWidget(),
        ],
      ),
    );
  }

  Widget _buildMockCredentialsInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                size: 5.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Demo Credentials',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Email: user@freshcart.com\nPassword: password123',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
