import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../models/merchant_model.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

    if (authProvider.userId != null) {
      await merchantProvider.loadMyMerchant(authProvider.userId);
      if (merchantProvider.merchant?.isApproved == true) {
        await merchantProvider.loadMyStores();
        await merchantProvider.loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.merchantProfile),
            tooltip: 'Settings',
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
            label: const Text('New Store'),
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
            Icon(
              Icons.store_outlined,
              size: 20.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Merchant Account',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You need to apply as a merchant first',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.merchantApplication),
              icon: const Icon(Icons.add_business),
              label: const Text('Apply as Merchant'),
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
    final isPending = merchant.isPending;
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
                color: isRejected ? Colors.red.shade50 : Colors.orange.shade50,
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
              isRejected ? 'Application Rejected' : 'Application Pending',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isRejected ? Colors.red : Colors.orange,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              isRejected
                  ? 'Your merchant application was rejected'
                  : 'Your application is being reviewed by our team',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isRejected && merchant.rejectionReason != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Reason: ${merchant.rejectionReason}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 4.h),
            if (isRejected)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.merchantApplication),
                icon: const Icon(Icons.refresh),
                label: const Text('Reapply'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                image: merchant.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(merchant.logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: merchant.logoUrl == null
                  ? Icon(Icons.store, size: 8.w, color: theme.colorScheme.primary)
                  : null,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          merchant.businessName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 3.w),
                            SizedBox(width: 1.w),
                            Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  if (merchant.businessType != null)
                    Text(
                      merchant.businessType!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  SizedBox(height: 0.5.h),
                  Text(
                    merchant.address ?? 'No address set',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          label: 'Total Stores',
          value: '${stats?['total_stores'] ?? merchantProvider.stores.length}',
          icon: Icons.store,
          color: Colors.blue,
        ),
        _buildStatCard(
          label: 'Total Products',
          value: '${stats?['total_products'] ?? 0}',
          icon: Icons.inventory_2,
          color: Colors.green,
        ),
        _buildStatCard(
          label: "Today's Orders",
          value: '${stats?['today_orders'] ?? 0}',
          icon: Icons.shopping_bag,
          color: Colors.orange,
        ),
        _buildStatCard(
          label: "Today's Revenue",
          value: '\$${(stats?['today_revenue'] ?? 0.0).toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 7.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STORES SECTION
  // ============================================================

  Widget _buildStoresSection(MerchantProvider merchantProvider) {
    final theme = Theme.of(context);
    final stores = merchantProvider.stores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Stores',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showCreateStoreDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Store'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (stores.isEmpty)
          _buildEmptyStoresState()
        else
          ...stores.map((store) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: _buildStoreCard(store),
              )),
      ],
    );
  }

  Widget _buildEmptyStoresState() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 12.w,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Stores Yet',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create your first store to start selling',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _showCreateStoreDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Store'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final theme = Theme.of(context);
    final isActive = store['is_active'] as bool? ?? true;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToStoreManagement(store['id'] as String),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  image: store['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(store['image_url'] as String),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: store['image_url'] == null
                    ? Icon(Icons.store, size: 6.w, color: theme.colorScheme.outline)
                    : null,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store['name'] as String? ?? 'Unnamed Store',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      store['category'] as String? ?? 'General',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.star, size: 3.5.w, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          (store['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        SizedBox(width: 3.w),
                        Icon(Icons.shopping_bag_outlined, size: 3.5.w, color: theme.colorScheme.outline),
                        SizedBox(width: 1.w),
                        Text(
                          '${store['total_reviews'] ?? 0} orders',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
                size: 6.w,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(MerchantProvider merchantProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.receipt_long,
                label: 'Orders',
                onTap: () {
                  // Navigate to merchant orders
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                label: 'Analytics',
                onTap: () {
                  // Navigate to analytics
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.inventory,
                label: 'Products',
                onTap: () {
                  if (merchantProvider.stores.isNotEmpty) {
                    final storeId = merchantProvider.stores.first['id'] as String;
                    _navigateToStoreManagement(storeId);
                  }
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.reviews,
                label: 'Reviews',
                onTap: () {
                  // Navigate to reviews
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Icon(icon, size: 8.w, color: theme.colorScheme.primary),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOGS & NAVIGATION
  // ============================================================

  void _showCreateStoreDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Store'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Restaurant, Grocery',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<MerchantProvider>(
            builder: (context, merchantProvider, child) {
              return ElevatedButton(
                onPressed: merchantProvider.isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Store name is required')),
                          );
                          return;
                        }

                        // Get a default category ID (you may need to adjust this)
                        final store = await merchantProvider.createStore(
                          name: nameController.text.trim(),
                          categoryId: 'default', // You may want to get this from a dropdown
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        if (store != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Store created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                child: merchantProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToStoreManagement(String storeId) {
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
    merchantProvider.selectStore(storeId);
    Navigator.pushNamed(context, AppRoutes.merchantStore);
  }
}