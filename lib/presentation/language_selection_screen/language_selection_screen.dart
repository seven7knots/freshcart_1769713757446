import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/locale_provider.dart';
import '../../routes/app_routes.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE50913),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            // KJ Logo
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'KJ',
                  style: TextStyle(
                    fontSize: 14.w,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE50913),
                    letterSpacing: 2,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'KJ Delivery',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              'Food, Grocery & Services',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.85),
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            // Language selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  Text(
                    'Choose your language',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Text(
                    'اختر لغتك',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4.h),
                  // English button
                  _LanguageButton(
                    label: 'English',
                    subtitle: 'Continue in English',
                    locale: const Locale('en'),
                    icon: '🇺🇸',
                  ),
                  SizedBox(height: 2.h),
                  // Arabic button
                  _LanguageButton(
                    label: 'العربية',
                    subtitle: 'المتابعة بالعربية',
                    locale: const Locale('ar'),
                    icon: '🇱🇧',
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Locale locale;
  final String icon;

  const _LanguageButton({
    required this.label,
    required this.subtitle,
    required this.locale,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final localeProvider = Provider.of<LocaleProvider>(
            context,
            listen: false,
          );
          await localeProvider.setLocale(locale);
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.initial);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE50913),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(
              icon,
              style: TextStyle(fontSize: 18.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 3.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
