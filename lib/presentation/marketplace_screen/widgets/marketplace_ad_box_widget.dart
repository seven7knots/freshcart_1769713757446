import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widgets/custom_image_widget.dart';

/// Marketplace ad banner — content loaded from `app_config` table.
/// Keys: marketplace_ad_image_url, marketplace_ad_title, marketplace_ad_subtitle
/// Admin manages these via the Marketplace Admin screen.
class MarketplaceAdBoxWidget extends StatefulWidget {
  const MarketplaceAdBoxWidget({super.key});

  @override
  State<MarketplaceAdBoxWidget> createState() => _MarketplaceAdBoxWidgetState();
}

class _MarketplaceAdBoxWidgetState extends State<MarketplaceAdBoxWidget> {
  String? _imageUrl;
  String _title = 'Special Offers This Week';
  String _subtitle = 'Up to 50% off on selected items';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdConfig();
  }

  Future<void> _loadAdConfig() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('app_config')
          .select('key, value')
          .inFilter('key', [
        'marketplace_ad_image_url',
        'marketplace_ad_title',
        'marketplace_ad_subtitle',
      ]);

      final configs = Map<String, String>.fromEntries(
        (response as List).map((row) =>
            MapEntry(row['key'] as String, row['value'] as String? ?? '')),
      );

      if (mounted) {
        setState(() {
          _imageUrl = configs['marketplace_ad_image_url']?.isNotEmpty == true
              ? configs['marketplace_ad_image_url']
              : null;
          if (configs['marketplace_ad_title']?.isNotEmpty == true) {
            _title = configs['marketplace_ad_title']!;
          }
          if (configs['marketplace_ad_subtitle']?.isNotEmpty == true) {
            _subtitle = configs['marketplace_ad_subtitle']!;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MarketplaceAd] Error loading ad config: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        height: 18.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(3.w),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // If no ad image and no custom title, hide the widget
    final fallbackImage =
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da';
    final displayUrl = _imageUrl ?? fallbackImage;

    return GestureDetector(
      onTap: () {
        // Could navigate to a promo page in the future
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        height: 18.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3.w),
          child: Stack(
            children: [
              CustomImageWidget(
                imageUrl: displayUrl,
                width: double.infinity,
                height: 18.h,
                fit: BoxFit.cover,
                semanticLabel: 'Marketplace promotional banner',
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 2.h,
                left: 4.w,
                right: 4.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _subtitle,
                      style: TextStyle(fontSize: 12.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}