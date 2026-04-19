import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../services/ads_service.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/ad_analytics_widget.dart';
import './widgets/ad_card_widget.dart';
import './widgets/ad_creation_wizard_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminAdsManagementScreen extends StatefulWidget {
  const AdminAdsManagementScreen({super.key});

  @override
  State<AdminAdsManagementScreen> createState() =>
      _AdminAdsManagementScreenState();
}

class _AdminAdsManagementScreenState extends State<AdminAdsManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdsService _adsService = AdsService();
  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _carouselAds = [];
  List<Map<String, dynamic>> _rotatingAds = [];
  List<Map<String, dynamic>> _fixedAds = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allAds = await _adsService.getAllAds();

      setState(() {
        _carouselAds =
            allAds.where((ad) => ad['format'] == 'carousel').toList();
        _rotatingAds =
            allAds.where((ad) => ad['format'] == 'rotating_banner').toList();
        _fixedAds =
            allAds.where((ad) => ad['format'] == 'fixed_banner').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateAdWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdCreationWizardWidget(
        onAdCreated: () {
          Navigator.pop(context);
          _loadAds();
        },
      ),
    );
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdAnalyticsWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    if (!adminProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.accessDenied, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: Center(
          child: Text(AppLocalizations.of(context)!.youDoNotHavePermissionTo, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return AdminLayoutWrapper(
      currentRoute: AppRoutes.adminAdsManagement,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.adsManagement, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              onPressed: _showAnalytics,
              icon: const CustomIconWidget(iconName: 'analytics', size: 24),
              tooltip: AppLocalizations.of(context)!.viewAnalytics,
            ),
            IconButton(
              onPressed: _loadAds,
              icon: const CustomIconWidget(iconName: 'refresh', size: 24),
              tooltip: AppLocalizations.of(context)!.refresh,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.carousel),
              Tab(text: AppLocalizations.of(context)!.rotating),
              Tab(text: AppLocalizations.of(context)!.fixed),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error', maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: _loadAds,
                          child: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAdsList(_carouselAds, 'carousel'),
                      _buildAdsList(_rotatingAds, 'rotating_banner'),
                      _buildAdsList(_fixedAds, 'fixed_banner'),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateAdWizard,
          icon: const CustomIconWidget(
            iconName: 'add',
            color: Colors.white,
            size: 24,
          ),
          label: Text(AppLocalizations.of(context)!.createAd, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  Widget _buildAdsList(List<Map<String, dynamic>> ads, String format) {
    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'campaign',
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 2.h),
            Text(
              'No ${format.replaceAll('_', ' ')} ads yet',
              style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              AppLocalizations.of(context)!.createYourFirstAdToGet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAds,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return AdCardWidget(
            ad: ad,
            onEdit: () => _editAd(ad),
            onDelete: () => _deleteAd(ad['id']),
            onStatusChange: (status) => _updateAdStatus(ad['id'], status),
          );
        },
      ),
    );
  }

  void _editAd(Map<String, dynamic> ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdCreationWizardWidget(
        existingAd: ad,
        onAdCreated: () {
          Navigator.pop(context);
          _loadAds();
        },
      ),
    );
  }

  Future<void> _deleteAd(String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAd, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo4, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adsService.deleteAd(adId);
        _loadAds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adDeletedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete ad: $e', maxLines: 1, overflow: TextOverflow.ellipsis)));
        }
      }
    }
  }

  Future<void> _updateAdStatus(String adId, String status) async {
    try {
      await _adsService.updateAdStatus(adId, status);

      // SESSION 39: Send push notification when ad goes active
      if (status == 'active') {
        try {
          final ad = await _adsService.getAdById(adId);
          if (ad != null) {
            await _adsService.notifyCustomersAboutAd(
              adId: adId,
              title: ad['title'] ?? AppLocalizations.of(context)!.newPromotion,
              description: ad['description'],
            );
          }
        } catch (e) {
          debugPrint('[ADS] Notification send failed (non-fatal): \$e');
        }
      }

      _loadAds();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ad status updated to \$status', maxLines: 1, overflow: TextOverflow.ellipsis)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ad status: $e', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }
    }
  }
}
