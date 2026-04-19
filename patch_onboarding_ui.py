"""Issue 1: Onboarding CTA padding + page indicator dots.

Full-file replacements for:
  - lib/presentation/onboarding_screen/onboarding_screen.dart
  - lib/presentation/onboarding_screen/widgets/page_indicator_widget.dart
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ONBOARDING_SCREEN = r'''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';
import './widgets/location_permission_widget.dart';
import './widgets/onboarding_slide_widget.dart';
import './widgets/page_indicator_widget.dart';
import '../../l10n/generated/app_localizations.dart';

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
          "assets/images/onboarding/onboarding_1.jpg",
      "semanticLabel":
          "Fresh organic vegetables and fruits displayed in wicker baskets at a farmers market with vibrant colors",
    },
    {
      "title": "30-Minute\nDelivery",
      "description": 'Lightning-fast delivery to your doorstep. Fresh groceries delivered in 30 minutes or less, guaranteed.',
      "imageUrl":
          "assets/images/onboarding/onboarding_2.jpg",
      "semanticLabel":
          "Delivery person on electric scooter carrying insulated grocery bags through city streets",
    },
    {
      "title": "Personalized\nRecommendations",
      "description": 'Smart suggestions based on your preferences and purchase history. Discover new products tailored just for you.',
      "imageUrl": "assets/images/onboarding/onboarding_3.jpg",
      "semanticLabel":
          "Smartphone screen showing grocery app interface with personalized product recommendations and shopping cart",
    },

  ];

  @override
  void initState() {
    super.initState();
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

  void _onLocationPermissionGranted() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (route) => false,
      );
    }
  }

  void _onLocationPermissionDenied() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (route) => false,
      );
    }
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
                  Column(
                    children: [
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
                              AppLocalizations.of(context)!.skip,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

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

                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PageIndicatorWidget(
                                currentIndex: _currentIndex,
                                totalPages: _onboardingData.length,
                              ),
                              const SizedBox(height: 28),
                              ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50913),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: theme.colorScheme.shadow,
                                  minimumSize: const Size(double.infinity, 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                child: Text(
                                  _currentIndex == _onboardingData.length - 1
                                      ? "Get Started"
                                      : "Next",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
'''

PAGE_INDICATOR = r'''import 'package:flutter/material.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageIndicatorWidget({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) {
          final bool isActive = currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE50913)
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}
'''

def write(rel_path: str, content: str) -> None:
    p = ROOT / rel_path
    p.write_text(content, encoding='utf-8', newline='\n')
    print(f"wrote {rel_path} ({len(content)} bytes)")

write('lib/presentation/onboarding_screen/onboarding_screen.dart', ONBOARDING_SCREEN)
write('lib/presentation/onboarding_screen/widgets/page_indicator_widget.dart', PAGE_INDICATOR)
print("done")
