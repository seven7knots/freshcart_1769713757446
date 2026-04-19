import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/ads_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/admin_editable_item_wrapper.dart';
import '../../../widgets/shimmer_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

class HeroBannerWidget extends StatefulWidget {
  const HeroBannerWidget({super.key});

  @override
  State<HeroBannerWidget> createState() => _HeroBannerWidgetState();
}

class _HeroBannerWidgetState extends State<HeroBannerWidget>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final AdsService _adsService = AdsService();
  List<Map<String, dynamic>> _activeAds = [];
  bool _isLoadingAds = true;

  /// Auto-refresh timer — reloads ads every 5 minutes so new ads
  /// appear without requiring a full app restart.
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer initial load to avoid first-frame jank
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _loadActiveAds();
    });
    // Refresh ads every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadActiveAds();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Reload ads when user returns to the app from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadActiveAds();
    }
  }

  // ============================================================
  // SESSION 20 FIX (Bug 5): Removed RPC call to non-existent
  // get_active_ads function. Now queries ads table directly.
  // This eliminates the recurring type mismatch error every 5 min.
  // ============================================================

  Future<void> _loadActiveAds() async {
    try {
      final ads = await _loadAdsDirectly();

      // SESSION 39 FIX: Accept ALL active ads regardless of format.
      // The 'status=active' filter in the query is sufficient.
      // Previous filter excluded 'rotating' and 'fixed' format ads.
      List<Map<String, dynamic>> filtered = ads;

      setState(() {
        _activeAds = filtered;
        _isLoadingAds = false;
      });

      debugPrint('[HERO_BANNER] Loaded ${filtered.length} active ads');
    } catch (e) {
      debugPrint('[HERO_BANNER] Failed to load ads: $e');
      setState(() => _isLoadingAds = false);
    }
  }

  /// Direct query — fetches active ads from the ads table
  Future<List<Map<String, dynamic>>> _loadAdsDirectly() async {
    try {
      final result = await SupabaseService.client
          .from('ads')
          .select()
          .eq('status', 'active')
          .order('display_order', ascending: true)
          .limit(10);

      debugPrint('[HERO_BANNER] Direct query returned ${result.length} ads');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('[HERO_BANNER] Direct query failed: $e');
      return [];
    }
  }

  final List<Map<String, dynamic>> _bannerData = [
    {
      "id": "demo-1",
      "title": 'Fresh Organic Vegetables',
      "subtitle": 'Up to 40% OFF',
      "description": 'Farm-fresh organic produce delivered to your doorstep',
      "image":
          "https://images.unsplash.com/photo-1667988672217-10a31d5cca30",
      "semanticLabel":
          "Fresh organic vegetables including broccoli, carrots, and leafy greens arranged in a wooden basket",
      "backgroundColor": const Color(0xFFFF3B30),
      "textColor": Colors.white,
      "routeCategoryId": "fresh_produce",
    },
    {
      "id": "demo-2",
      "title": 'Premium Dairy Products',
      "subtitle": 'Buy 2 Get 1 FREE',
      "description": 'Fresh milk, cheese, and yogurt from local farms',
      "image":
          "https://images.unsplash.com/photo-1558475890-1ebfc06edcf5",
      "semanticLabel":
          "Glass bottles of fresh milk and various dairy products on a rustic wooden table",
      "backgroundColor": const Color(0xFF2196F3),
      "textColor": Colors.white,
      "routeCategoryId": "dairy_eggs",
    },
    {
      "id": "demo-3",
      "title": 'Seasonal Fruits',
      "subtitle": "Starting at \$2.99",
      "description": 'Sweet and juicy fruits picked at perfect ripeness',
      "image":
          "https://images.unsplash.com/photo-1592060133206-422e97c60097",
      "semanticLabel":
          "Colorful assortment of fresh seasonal fruits including apples, oranges, and berries in a wicker basket",
      "backgroundColor": const Color(0xFFFF9800),
      "textColor": Colors.white,
      "routeCategoryId": "fresh_produce",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final displayData =
        _activeAds.isNotEmpty ? _activeAds : _bannerData;
    final isEditMode =
        adminProvider.isAdmin && adminProvider.isEditMode;

    return Container(
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Section header with admin add button
          if (isEditMode)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.heroBanners,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  InkWell(
                    onTap: _addNewBanner,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              color: Colors.white, size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            AppLocalizations.of(context)!.addBanner,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingAds
                ? const ShimmerHeroBanner()
                : CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: displayData.length,
                    itemBuilder:
                        (context, index, realIndex) {
                      final banner = displayData[index];
                      final bannerCard =
                          _buildBannerCard(banner);

                      if (isEditMode) {
                        return AdminEditableItemWrapper(
                          contentType: 'ad',
                          contentId:
                              banner['id']?.toString(),
                          contentData: banner,
                          onDeleted: _loadActiveAds,
                          onUpdated: _loadActiveAds,
                          child: bannerCard,
                        );
                      }

                      return bannerCard;
                    },
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 0.92,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.2,
                      autoPlay: !isEditMode,
                      autoPlayInterval: Duration(
                        milliseconds: displayData.isNotEmpty &&
                                displayData[0][
                                        'auto_play_interval'] !=
                                    null
                            ? displayData[0]
                                ['auto_play_interval']
                            : 4000,
                      ),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      onPageChanged: (index, reason) {
                        setState(
                            () => _currentIndex = index);
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
          SizedBox(height: 1.h),
          _buildIndicators(displayData.length),
        ],
      ),
    );
  }

  void _addNewBanner() {
    Navigator.pushNamed(context, AppRoutes.adminAdsManagement);
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final theme = Theme.of(context);
    final isAdData = banner.containsKey('link_type');
    final imageUrl =
        isAdData ? banner['image_url'] : banner['image'];
    final title = banner['title'] ?? AppLocalizations.of(context)!.untitled;
    final subtitle =
        isAdData ? banner['description'] : banner['subtitle'];
    final description =
        isAdData ? '' : (banner['description'] ?? '');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            (banner["backgroundColor"] as Color? ??
                    theme.colorScheme.primary)
                .withAlpha(230),
            (banner["backgroundColor"] as Color? ??
                theme.colorScheme.primary),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow
                .withAlpha(38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image — only show if we have a valid URL
            if (imageUrl != null &&
                (imageUrl as String).isNotEmpty)
              Positioned.fill(
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  semanticLabel:
                      banner["semanticLabel"] as String? ??
                          '$title banner image',
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (banner["backgroundColor"] as Color? ??
                              theme.colorScheme.primary)
                          .withAlpha(179),
                      (banner["backgroundColor"] as Color? ??
                              theme.colorScheme.primary)
                          .withAlpha(77),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 5.w,
              top: 2.h,
              bottom: 2.h,
              right: 5.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null &&
                      (subtitle as String).isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        color: banner["textColor"]
                                as Color? ??
                            Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 0.5.h),
                  Text(
                    title as String,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(
                      color:
                          banner["textColor"] as Color? ??
                              Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description is String &&
                      description.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Flexible(
                      child: Text(
                        description,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: (banner["textColor"]
                                      as Color? ??
                                  Colors.white)
                              .withAlpha(230),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  SizedBox(height: 1.h),
                  SizedBox(
                    height: 4.h,
                    child: ElevatedButton(
                      onPressed: () => _handleShopNow(banner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.w, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.shopNow,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          onTap: () =>
              _carouselController.animateToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 8.w : 2.w,
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline
                      .withAlpha(77),
            ),
          ),
        );
      }),
    );
  }

  void _handleShopNow(Map<String, dynamic> banner) {
    final isAdData = banner.containsKey('link_type');

    if (isAdData) {
      _adsService.trackClick(banner['id'],
          contextPage: 'home');

      final linkType = banner['link_type'];
      final linkTargetId = banner['link_target_id'];

      switch (linkType) {
        case 'category':
          if (linkTargetId != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.categoryListingsScreen,
              arguments: {'categoryId': linkTargetId},
            );
            return;
          }
          break;
        case 'store':
          if (linkTargetId != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.storeDetail,
              arguments: {'storeId': linkTargetId},
            );
            return;
          }
          break;
        case 'product':
          if (linkTargetId != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: {'productId': linkTargetId},
            );
            return;
          }
          break;
        case 'external':
          // External URLs — could launch in browser
          break;
        default:
          break;
      }
    }

    // Fallback: navigate to marketplace
    Navigator.pushNamed(context, AppRoutes.home);
  }
}