import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../services/ads_service.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/ad_analytics_widget.dart';
import './widgets/ad_card_widget.dart';
import './widgets/ad_creation_wizard_widget.dart';

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
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    return AdminLayoutWrapper(
      currentRoute: AppRoutes.adminAdsManagement,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Ads Management'),
          actions: [
            IconButton(
              onPressed: _showAnalytics,
              icon: const CustomIconWidget(iconName: 'analytics', size: 24),
              tooltip: 'View Analytics',
            ),
            IconButton(
              onPressed: _loadAds,
              icon: const CustomIconWidget(iconName: 'refresh', size: 24),
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Carousel'),
              Tab(text: 'Rotating'),
              Tab(text: 'Fixed'),
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
                        Text('Error: $_error'),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: _loadAds,
                          child: const Text('Retry'),
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
          label: const Text('Create Ad'),
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Create your first ad to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
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
        title: const Text('Delete Ad'),
        content: const Text('Are you sure you want to delete this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('Ad deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete ad: $e')));
        }
      }
    }
  }

  Future<void> _updateAdStatus(String adId, String status) async {
    try {
      await _adsService.updateAdStatus(adId, status);
      _loadAds();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ad status updated to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ad status: $e')),
        );
      }
    }
  }
}
