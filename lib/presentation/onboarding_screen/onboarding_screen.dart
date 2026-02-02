import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/analytics_service.dart';
import './widgets/location_permission_widget.dart';
import './widgets/onboarding_slide_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _showLocationPermission = false;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Premium Quality\nProducts",
      "description":
          "Hand-picked fresh groceries from trusted local suppliers. Every item meets our quality standards for your family's health.",
      "imageUrl":
          "https://images.unsplash.com/photo-1730145313984-838b35077667",
      "semanticLabel":
          "Fresh organic vegetables and fruits displayed in wicker baskets at a farmers market with vibrant colors",
    },
    {
      "title": "30-Minute\nDelivery",
      "description":
          "Lightning-fast delivery to your doorstep. Fresh groceries delivered in 30 minutes or less, guaranteed.",
      "imageUrl":
          "https://images.unsplash.com/photo-1572504586329-2650fedc583d",
      "semanticLabel":
          "Delivery person on electric scooter carrying insulated grocery bags through city streets",
    },
    {
      "title": "Personalized\nRecommendations",
      "description":
          "Smart suggestions based on your preferences and purchase history. Discover new products tailored just for you.",
      "imageUrl": "https://images.unsplash.com/photo-1544365712-91cd4904cd07",
      "semanticLabel":
          "Smartphone screen showing grocery app interface with personalized product recommendations and shopping cart",
    },
    {
      "title": "Loyalty Rewards\n& Savings",
      "description":
          "Earn points with every purchase and unlock exclusive deals. Save more while shopping for premium quality groceries.",
      "imageUrl":
          "https://images.unsplash.com/photo-1614110073736-1778d27f588a",
      "semanticLabel":
          "Golden loyalty card with reward points and discount badges surrounded by fresh groceries and coins",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Track onboarding start
    AnalyticsService.logOnboardingStart();
    AnalyticsService.logScreenView(screenName: 'onboarding_screen');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentIndex < _onboardingData.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showLocationRequest();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _showLocationRequest();
  }

  void _showLocationRequest() {
    setState(() {
      _showLocationPermission = true;
    });
  }

  void _onLocationPermissionGranted() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-screen',
      (route) => false,
    );
  }

  void _onLocationPermissionDenied() {
    HapticFeedback.lightImpact();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-screen',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _showLocationPermission
            ? LocationPermissionWidget(
                onPermissionGranted: _onLocationPermissionGranted,
                onPermissionDenied: _onLocationPermissionDenied,
              )
            : Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      // Skip button
                      Padding(
                        padding: EdgeInsets.only(top: 2.h, right: 6.w),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: _skipOnboarding,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.h,
                              ),
                            ),
                            child: Text(
                              "Skip",
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PageView
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _onboardingData.length,
                          itemBuilder: (context, index) {
                            final data = _onboardingData[index];
                            return OnboardingSlideWidget(
                              title: data["title"]!,
                              description: data["description"]!,
                              imageUrl: data["imageUrl"]!,
                              semanticLabel: data["semanticLabel"]!,
                            );
                          },
                        ),
                      ),

                      // Bottom section with indicators and button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        child: Column(
                          children: [
                            // Page indicators
                            PageIndicatorWidget(
                              currentIndex: _currentIndex,
                              totalPages: _onboardingData.length,
                            ),

                            SizedBox(height: 4.h),

                            // Next/Get Started button
                            SizedBox(
                              width: 80.w,
                              height: 6.h,
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  elevation: 2,
                                  shadowColor: theme.colorScheme.shadow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _currentIndex == _onboardingData.length - 1
                                      ? "Get Started"
                                      : "Next",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      // No bottom navigation bar for onboarding
    );
  }
}
