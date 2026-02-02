import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/ads_service.dart';
import '../../admin_edit_overlay_system_screen/admin_edit_overlay_system_screen.dart';

class HeroBannerWidget extends StatefulWidget {
  const HeroBannerWidget({super.key});

  @override
  State<HeroBannerWidget> createState() => _HeroBannerWidgetState();
}

class _HeroBannerWidgetState extends State<HeroBannerWidget> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final AdsService _adsService = AdsService();
  List<Map<String, dynamic>> _activeAds = [];
  bool _isLoadingAds = true;

  @override
  void initState() {
    super.initState();
    _loadActiveAds();
  }

  Future<void> _loadActiveAds() async {
    try {
      final ads = await _adsService.getActiveAdsForContext(
        targetType: 'global_home',
      );
      setState(() {
        _activeAds = ads.where((ad) => ad['format'] == 'carousel').toList();
        _isLoadingAds = false;
      });
    } catch (e) {
      setState(() => _isLoadingAds = false);
    }
  }

  final List<Map<String, dynamic>> _bannerData = [
    {
      "id": 1,
      "title": "Fresh Organic Vegetables",
      "subtitle": "Up to 40% OFF",
      "description": "Farm-fresh organic produce delivered to your doorstep",
      "image": "https://images.unsplash.com/photo-1667988672217-10a31d5cca30",
      "semanticLabel":
          "Fresh organic vegetables including broccoli, carrots, and leafy greens arranged in a wooden basket",
      "backgroundColor": Color(0xFFFF3B30),
      "textColor": Colors.white,
    },
    {
      "id": 2,
      "title": "Premium Dairy Products",
      "subtitle": "Buy 2 Get 1 FREE",
      "description": "Fresh milk, cheese, and yogurt from local farms",
      "image": "https://images.unsplash.com/photo-1558475890-1ebfc06edcf5",
      "semanticLabel":
          "Glass bottles of fresh milk and various dairy products on a rustic wooden table",
      "backgroundColor": Color(0xFF2196F3),
      "textColor": Colors.white,
    },
    {
      "id": 3,
      "title": "Seasonal Fruits",
      "subtitle": "Starting at \$2.99",
      "description": "Sweet and juicy fruits picked at perfect ripeness",
      "image": "https://images.unsplash.com/photo-1592060133206-422e97c60097",
      "semanticLabel":
          "Colorful assortment of fresh seasonal fruits including apples, oranges, and berries in a wicker basket",
      "backgroundColor": Color(0xFFFF9800),
      "textColor": Colors.white,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final displayData = _activeAds.isNotEmpty ? _activeAds : _bannerData;

    Widget bannerWidget = Container(
      height: 25.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Expanded(
            child: _isLoadingAds
                ? const Center(child: CircularProgressIndicator())
                : CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: displayData.length,
                    itemBuilder: (context, index, realIndex) {
                      final banner = displayData[index];
                      return _buildBannerCard(banner);
                    },
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 0.92,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.2,
                      autoPlay: true,
                      autoPlayInterval: Duration(
                        milliseconds: displayData.isNotEmpty &&
                                displayData[0]['auto_play_interval'] != null
                            ? displayData[0]['auto_play_interval']
                            : 4000,
                      ),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                        if (_activeAds.isNotEmpty &&
                            index < _activeAds.length) {
                          _adsService.trackImpression(
                            _activeAds[index]['id'],
                            contextPage: 'home',
                          );
                        }
                      },
                    ),
                  ),
          ),
          SizedBox(height: 2.h),
          _buildIndicators(displayData.length),
        ],
      ),
    );

    if (adminProvider.isAdmin) {
      return AdminEditOverlaySystemScreen(
        contentType: 'carousel',
        child: bannerWidget,
      );
    }

    return bannerWidget;
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final isAdData = banner.containsKey('link_type');
    final imageUrl = isAdData ? banner['image_url'] : banner['image'];
    final title = isAdData ? banner['title'] : banner['title'];
    final subtitle = isAdData ? banner['description'] : banner['subtitle'];
    final description = isAdData ? '' : banner['description'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            (banner["backgroundColor"] as Color? ??
                    AppTheme.lightTheme.colorScheme.primary)
                .withValues(alpha: 0.9),
            (banner["backgroundColor"] as Color? ??
                AppTheme.lightTheme.colorScheme.primary),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomImageWidget(
                imageUrl: imageUrl as String,
                fit: BoxFit.cover,
                semanticLabel:
                    banner["semanticLabel"] as String? ?? '$title banner image',
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (banner["backgroundColor"] as Color? ??
                              AppTheme.lightTheme.colorScheme.primary)
                          .withValues(alpha: 0.7),
                      (banner["backgroundColor"] as Color? ??
                              AppTheme.lightTheme.colorScheme.primary)
                          .withValues(alpha: 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6.w,
              top: 4.h,
              bottom: 4.h,
              right: 6.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle as String,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: banner["textColor"] as Color? ?? Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  SizedBox(height: 1.h),
                  Text(
                    title as String,
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: banner["textColor"] as Color? ?? Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: (banner["textColor"] as Color? ?? Colors.white)
                            .withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () => _handleShopNow(banner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: banner["backgroundColor"] as Color? ??
                          AppTheme.lightTheme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Shop Now',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = _currentIndex == index;
        return GestureDetector(
          onTap: () => _carouselController.animateToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 8.w : 2.w,
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }

  void _handleShopNow(Map<String, dynamic> banner) {
    final isAdData = banner.containsKey('link_type');

    if (isAdData) {
      _adsService.trackClick(banner['id'], contextPage: 'home');

      final linkType = banner['link_type'];
      final linkTargetId = banner['link_target_id'];
      final externalUrl = banner['external_url'];

      switch (linkType) {
        case 'store':
          if (linkTargetId != null) {
            Navigator.pushNamed(context, '/search-screen',
                arguments: {'storeId': linkTargetId});
          }
          break;
        case 'product':
          if (linkTargetId != null) {
            Navigator.pushNamed(context, '/product-detail-screen',
                arguments: {'productId': linkTargetId});
          }
          break;
        case 'category':
          if (linkTargetId != null) {
            Navigator.pushNamed(context, '/search-screen',
                arguments: {'category': linkTargetId});
          }
          break;
        case 'external_url':
          break;
        default:
          Navigator.pushNamed(context, '/search-screen');
      }
    } else {
      Navigator.pushNamed(context, '/search-screen');
    }
  }
}
