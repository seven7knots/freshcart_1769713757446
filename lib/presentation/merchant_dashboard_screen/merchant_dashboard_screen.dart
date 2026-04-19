import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_address_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../providers/merchant_provider.dart';
import '../../models/merchant_model.dart';
import '../map_location_picker/map_location_picker_screen.dart';
import '../merchant_analytics_screen/merchant_analytics_screen.dart';
import '../../l10n/generated/app_localizations.dart';
// SESSION 20: Removed MerchantReviewsScreen import (review system removed)

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  // SESSION 8 FIX: Allowed category values matching stores_category_check
  static const _allowedCategories = [
    'food',
    'grocery',
    'pharmacy',
    'retail',
    'marketplace',
    'restaurant',
    'services',
    'electronics',
    'fashion',
    'beauty',
    'sports',
    'pets',
    'home',
    'bakery',
    'coffee',
    'other',
  ];

  static String _categoryLabel(String value) {
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final merchantProvider =
        Provider.of<MerchantProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await merchantProvider.loadMyMerchant(authProvider.userId);
      if (merchantProvider.merchant?.isApproved == true) {
        await merchantProvider.loadMyStores();
        await merchantProvider.loadStats();
      }
    }
  }

  // ============================================================
  // SESSION 17 M4 FIX: Logout handler with confirmation dialog
  // ============================================================

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.signOut, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo6, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.signOut, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.authentication,
      (route) => false,
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.merchantDashboard, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
          tooltip: AppLocalizations.of(context)!.backToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.merchantProfile),
            tooltip: AppLocalizations.of(context)!.settings,
          ),
          // SESSION 17 M4 FIX: Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: Consumer2<MerchantProvider, AuthProvider>(
        builder: (context, merchantProvider, authProvider, child) {
          if (merchantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final merchant = merchantProvider.merchant;

          if (merchant == null) {
            return _buildNoMerchantState();
          }

          if (!merchant.isApproved) {
            return _buildPendingState(merchant);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMerchantHeader(merchant),
                  SizedBox(height: 3.h),
                  _buildStatsGrid(merchantProvider),
                  SizedBox(height: 3.h),
                  _buildStoresSection(merchantProvider),
                  SizedBox(height: 3.h),
                  _buildQuickActions(merchantProvider),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<MerchantProvider>(
        builder: (context, merchantProvider, child) {
          if (merchantProvider.merchant?.isApproved != true) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showCreateStoreDialog(),
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.newStore, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        },
      ),
    );
  }

  // ============================================================
  // NO MERCHANT STATE
  // ============================================================

  Widget _buildNoMerchantState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 20.w,
                color: theme.colorScheme.outline),
            SizedBox(height: 3.h),
            Text(AppLocalizations.of(context)!.noMerchantAccount,
                style: TextStyle(
                    fontSize: 18.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(AppLocalizations.of(context)!.youNeedToApplyAsA,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.merchantApplication),
              icon: const Icon(Icons.add_business),
              label: Text(AppLocalizations.of(context)!.applyAsMerchant, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PENDING STATE
  // ============================================================

  Widget _buildPendingState(Merchant merchant) {
    final theme = Theme.of(context);
    final isRejected = merchant.isRejected;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: isRejected
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                size: 15.w,
                color: isRejected ? Colors.red : Colors.orange,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              isRejected ? AppLocalizations.of(context)!.applicationRejected : AppLocalizations.of(context)!.applicationPending,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isRejected ? Colors.red : Colors.orange,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text(
              isRejected
                  ? AppLocalizations.of(context)!.yourMerchantApplicationWasRejected
                  : AppLocalizations.of(context)!.yourApplicationIsBeingReviewedBy,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (isRejected && merchant.rejectionReason != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                      child: Text('Reason: ${merchant.rejectionReason}',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.red.shade800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
            SizedBox(height: 4.h),
            if (isRejected)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.merchantApplication),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.reapply, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MERCHANT HEADER
  // ============================================================

  Widget _buildMerchantHeader(Merchant merchant) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              image: merchant.logoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(merchant.logoUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: merchant.logoUrl == null
                ? Icon(Icons.store,
                    size: 8.w, color: theme.colorScheme.primary)
                : null,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(merchant.businessName,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: theme.colorScheme.surface, size: 3.w),
                            SizedBox(width: 1.w),
                            Text('VERIFIED',
                                style: TextStyle(
                                    color: theme.colorScheme.surface,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                    ),
                  ]),
                  SizedBox(height: 0.5.h),
                  if (merchant.businessType != null)
                    Text(merchant.businessType!.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.5.h),
                  Text(merchant.address ?? AppLocalizations.of(context)!.noAddressSet,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ]),
      ),
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================

  Widget _buildStatsGrid(MerchantProvider merchantProvider) {
    final stats = merchantProvider.stats;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
            label: AppLocalizations.of(context)!.totalStores,
            value:
                '${stats?['total_stores'] ?? merchantProvider.stores.length}',
            icon: Icons.store,
            color: Colors.blue),
        _buildStatCard(
            label: AppLocalizations.of(context)!.totalProducts,
            value: '${stats?['total_products'] ?? 0}',
            icon: Icons.inventory_2,
            color: Colors.green),
        _buildStatCard(
            label: AppLocalizations.of(context)!.todaySOrders,
            value: '${stats?['today_orders'] ?? 0}',
            icon: Icons.shopping_bag,
            color: Colors.orange),
        // SESSION 20 FIX: Label clarifies this is product revenue (no delivery fees)
        _buildStatCard(
            label: AppLocalizations.of(context)!.todaySRevenue,
            value:
                '\$${(stats?['today_revenue'] ?? 0.0).toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.purple),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 6.w),
              const SizedBox(height: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ),
            ]),
      ),
    );
  }

  // ============================================================
  // STORES SECTION — SESSION 20 FIX: Real order count per store
  // ============================================================

  Widget _buildStoresSection(MerchantProvider merchantProvider) {
    final stores = merchantProvider.stores;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(AppLocalizations.of(context)!.myStores,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                TextButton.icon(
                  onPressed: _showCreateStoreDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context)!.addStore, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
          SizedBox(height: 1.h),
          if (stores.isEmpty)
            _buildEmptyStoresState()
          else
            ...stores.map((store) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: _buildStoreCard(store, merchantProvider),
                )),
        ]);
  }

  Widget _buildEmptyStoresState() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(children: [
          Icon(Icons.storefront_outlined,
              size: 12.w, color: theme.colorScheme.outline),
          SizedBox(height: 2.h),
          Text(AppLocalizations.of(context)!.noStoresYet,
              style: TextStyle(
                  fontSize: 14.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Text(AppLocalizations.of(context)!.createYourFirstStoreToStart,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _showCreateStoreDialog,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createStore, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  // SESSION 20 FIX: Store card now shows real order count from provider
  Widget _buildStoreCard(
      Map<String, dynamic> store, MerchantProvider merchantProvider) {
    final theme = Theme.of(context);
    final isActive = store['is_active'] as bool? ?? true;
    final hasLocation = store['lat'] != null;
    final storeId = store['id'] as String? ?? '';

    // SESSION 20 FIX: Use real order count instead of total_reviews
    final orderCount = merchantProvider.storeOrderCounts[storeId] ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToStoreManagement(storeId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                image: store['image_url'] != null
                    ? DecorationImage(
                        image:
                            NetworkImage(store['image_url'] as String),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: store['image_url'] == null
                  ? Icon(Icons.store,
                      size: 6.w, color: theme.colorScheme.outline)
                  : null,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              store['name'] as String? ?? 'Unnamed Store',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(isActive ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.green.shade800
                                    : theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(store['category'] as String? ?? 'General',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 0.5.h),
                    Row(children: [
                      Icon(Icons.star, size: 3.5.w, color: Colors.amber),
                      SizedBox(width: 1.w),
                      Text(
                          (store['rating'] as num?)
                                  ?.toStringAsFixed(1) ??
                              '0.0',
                          style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(width: 3.w),
                      Icon(Icons.shopping_bag_outlined,
                          size: 3.5.w, color: theme.colorScheme.outline),
                      SizedBox(width: 1.w),
                      // SESSION 20 FIX: Real order count from DB
                      Text('$orderCount orders',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color:
                                  theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (hasLocation) ...[
                        SizedBox(width: 2.w),
                        Icon(Icons.gps_fixed,
                            size: 3.5.w, color: Colors.green),
                      ],
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.outline, size: 6.w),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS — SESSION 20 FIX:
  //   - "Orders" navigates to store management with initialTab=1 (orders tab)
  //   - "Products" navigates with initialTab=0 (products tab)
  //   - "Reviews" button REMOVED (review system removed app-wide)
  //   - Replaced with "Settings" button
  // ============================================================

  Widget _buildQuickActions(MerchantProvider merchantProvider) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.quickActions,
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          Row(children: [
            Expanded(
                child: _buildActionCard(
                    icon: Icons.receipt_long,
                    label: AppLocalizations.of(context)!.orders,
                    onTap: () {
                      // SESSION 20 FIX: Navigate to store management
                      // with initialTab=1 to open Orders tab directly
                      if (merchantProvider.stores.isNotEmpty) {
                        final storeId =
                            merchantProvider.stores.first['id'] as String;
                        _navigateToStoreManagement(storeId, initialTab: 1);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Create a store first to view orders'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    })),
            SizedBox(width: 3.w),
            Expanded(
                child: _buildActionCard(
                    icon: Icons.analytics,
                    label: AppLocalizations.of(context)!.analytics,
                    onTap: () {
                      final storeId = merchantProvider.selectedStoreId ??
                          (merchantProvider.stores.isNotEmpty
                              ? merchantProvider.stores.first['id'] as String?
                              : null);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MerchantAnalyticsScreen(storeId: storeId),
                        ),
                      );
                    })),
          ]),
          SizedBox(height: 2.h),
          Row(children: [
            Expanded(
                child: _buildActionCard(
                    icon: Icons.inventory,
                    label: AppLocalizations.of(context)!.products,
                    onTap: () {
                      // SESSION 20 FIX: Explicit initialTab=0 for Products
                      if (merchantProvider.stores.isNotEmpty) {
                        final storeId =
                            merchantProvider.stores.first['id'] as String;
                        _navigateToStoreManagement(storeId, initialTab: 0);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Create a store first to manage products'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    })),
            SizedBox(width: 3.w),
            // SESSION 20: Replaced Reviews with Settings
            Expanded(
                child: _buildActionCard(
                    icon: Icons.settings,
                    label: AppLocalizations.of(context)!.settings,
                    onTap: () {
                      Navigator.pushNamed(
                          context, AppRoutes.merchantProfile);
                    })),
          ]),
        ]);
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(children: [
            Icon(icon, size: 8.w, color: theme.colorScheme.primary),
            SizedBox(height: 1.h),
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE STORE DIALOG — SESSION 8 FIX
  // ============================================================

  void _showCreateStoreDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final addressController = TextEditingController();

    String? selectedCategory;
    double? storeLat;
    double? storeLng;
    double? deliveryRadiusKm;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewStore, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.storeName,
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 2.h),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.category,
                    border: OutlineInputBorder(),
                  ),
                  hint: Text(AppLocalizations.of(context)!.selectACategory, maxLines: 1, overflow: TextOverflow.ellipsis),
                  items: _allowedCategories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 2.h),

                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<UserAddress>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => UniversalMapPickerScreen(
                          mode: MapPickerMode.storeSetup,
                          initialLat: storeLat,
                          initialLng: storeLng,
                          initialRadiusKm: deliveryRadiusKm,
                        ),
                      ),
                    );
                    if (result != null) {
                      setDialogState(() {
                        addressController.text = result.address;
                        storeLat = result.lat;
                        storeLng = result.lng;
                        deliveryRadiusKm = result.radiusKm;
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.storeLocationDeliveryZone,
                        hintText: AppLocalizations.of(context)!.tapToPickOnMap,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: Icon(Icons.map,
                            color: Theme.of(ctx).colorScheme.primary),
                      ),
                    ),
                  ),
                ),

                if (deliveryRadiusKm != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Row(children: [
                      const Icon(Icons.radar, size: 14, color: Colors.green),
                      SizedBox(width: 1.w),
                      Flexible(child: Text(
                        'Delivery radius: ${deliveryRadiusKm!.toStringAsFixed(1)} km',
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Consumer<MerchantProvider>(
            builder: (context, merchantProvider, child) {
              return ElevatedButton(
                onPressed: merchantProvider.isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(AppLocalizations.of(context)!.storeNameIsRequired, maxLines: 1, overflow: TextOverflow.ellipsis)));
                          return;
                        }

                        final store = await merchantProvider.createStore(
                          name: nameController.text.trim(),
                          categoryId: null,
                          description: descriptionController.text
                                  .trim()
                                  .isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          category: selectedCategory,
                        );

                        if (store != null &&
                            storeLat != null &&
                            store['id'] != null) {
                          try {
                            await SupabaseService.client
                                .from('stores')
                                .update({
                              'address': addressController.text.trim(),
                              'lat': storeLat,
                              'lng': storeLng,
                              'delivery_radius_km': deliveryRadiusKm,
                            }).eq('id', store['id']);
                          } catch (e) { debugPrint('[MERCHANT_DASHBOARD_SCREEN] Silent error: $e'); }
                        }

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);

                        if (store != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(AppLocalizations.of(context)!.storeCreatedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  backgroundColor: Colors.green));
                          _loadData();
                        }
                      },
                child: merchantProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.create, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            },
          ),
        ],
      ),
    );
  }

  // SESSION 20 FIX: Added optional initialTab parameter
  // so Orders and Products navigate to different tabs
  void _navigateToStoreManagement(String storeId, {int initialTab = 0}) {
    final merchantProvider =
        Provider.of<MerchantProvider>(context, listen: false);
    merchantProvider.selectStore(storeId);
    Navigator.pushNamed(
      context,
      AppRoutes.merchantStore,
      arguments: {'initialTab': initialTab},
    );
  }
}
