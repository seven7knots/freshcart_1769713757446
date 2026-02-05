import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/seed_service.dart';

class AdminNavigationDrawerScreen extends StatefulWidget {
  const AdminNavigationDrawerScreen({super.key});

  @override
  State<AdminNavigationDrawerScreen> createState() =>
      _AdminNavigationDrawerScreenState();
}

class _AdminNavigationDrawerScreenState
    extends State<AdminNavigationDrawerScreen> {
  bool _isSeeding = false;
  bool _isResetting = false;
  String? _seedMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(
      screenName: 'admin_navigation_drawer_screen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildAdminHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavigationSection(
                    title: 'Dashboard',
                    items: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        title: 'Analytics Overview',
                        route: AppRoutes.adminLandingDashboard,
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Users'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.adminUsersManagement);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_ind_outlined),
                    title: const Text('Role Requests'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.adminRoleUpgradeManagement);
                    },
                  ),
                  _buildNavigationSection(
                    title: 'Content Management',
                    items: [
                      _buildNavItem(
                        icon: Icons.inventory,
                        title: 'Products',
                        route: AppRoutes.home,
                      ),
                      _buildNavItem(
                        icon: Icons.category,
                        title: 'Categories',
                        route: AppRoutes.allCategoriesScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Categories',
                        route: AppRoutes.adminCategories,
                      ),
                      _buildNavItem(
                        icon: Icons.storefront,
                        title: 'Stores',
                        route: AppRoutes.marketplaceScreen,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: 'Order Operations',
                    items: [
                      _buildNavItem(
                        icon: Icons.shopping_bag,
                        title: 'Active Orders',
                        route: AppRoutes.enhancedOrderManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.assignment,
                        title: 'Delivery Assignments',
                        route: AppRoutes.enhancedOrderManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.map,
                        title: 'Logistics Management',
                        route: AppRoutes.adminLogisticsManagement,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: 'Marketing Tools',
                    items: [
                      _buildNavItem(
                        icon: Icons.campaign,
                        title: 'Ads & Promotions',
                        route: AppRoutes.adminAdsManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.local_offer,
                        title: 'Campaigns',
                        route: AppRoutes.adminAdsManagement,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: 'System Settings',
                    items: [
                      _buildNavItem(
                        icon: Icons.settings,
                        title: 'App Configuration',
                        route: AppRoutes.adminDashboard,
                      ),
                      _buildNavItem(
                        icon: Icons.security,
                        title: 'Permissions',
                        route: AppRoutes.adminDashboard,
                      ),
                    ],
                  ),
                  const Divider(),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Developer Tools',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 1.h),
                        ElevatedButton.icon(
                          onPressed: _isSeeding || _isResetting
                              ? null
                              : _handleSeedDemoData,
                          icon: _isSeeding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload, size: 20),
                          label: Text(
                            _isSeeding ? 'Seeding...' : 'Seed Demo Data',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        ElevatedButton.icon(
                          onPressed: _isSeeding || _isResetting
                              ? null
                              : _handleResetDemoData,
                          icon: _isResetting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          label: Text(
                            _isResetting ? 'Resetting...' : 'Reset Demo Data',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                        ),
                        if (_seedMessage != null) ...[
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: _seedMessage!.contains('failed')
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _seedMessage!.contains('failed')
                                    ? Colors.red[300]!
                                    : Colors.green[300]!,
                              ),
                            ),
                            child: Text(
                              _seedMessage!,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: _seedMessage!.contains('failed')
                                    ? Colors.red[900]
                                    : Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildAdminFooter(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSeedDemoData() async {
    setState(() {
      _isSeeding = true;
      _seedMessage = null;
    });

    try {
      final result = await SeedService.seedDemoData();
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown result';
      final counts = result['counts'] as Map<String, int>? ?? {};

      setState(() {
        _seedMessage = message;
        _isSeeding = false;
      });

      if (success && counts.isNotEmpty) {
        if (mounted) _showSummaryDialog(counts);
      } else if (!success) {
        final errorDetails = result['errorDetails'] ?? result['error'] ?? '';
        if (mounted && errorDetails.toString().isNotEmpty) {
          _showErrorDialog(message, errorDetails.toString());
        }
      }

      if (success) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _seedMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _seedMessage = 'Seeding failed: $e';
        _isSeeding = false;
      });
      if (mounted) {
        _showErrorDialog('Seeding Error', e.toString());
      }
    }
  }

  Future<void> _handleResetDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will call reset_demo_data() RPC to delete all demo rows, then re-seed the database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset & Re-seed'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isResetting = true;
      _seedMessage = null;
    });

    try {
      final resetResult = await SeedService.resetDemoData();
      final resetSuccess = resetResult['success'] as bool? ?? false;
      final resetMessage =
          resetResult['message'] as String? ?? 'Unknown result';
      final resetCounts = resetResult['counts'] as Map<String, dynamic>? ?? {};

      if (!resetSuccess) {
        setState(() {
          _seedMessage = resetMessage;
          _isResetting = false;
        });
        if (mounted) {
          final errorDetails = resetResult['errorDetails'] ?? '';
          _showErrorDialog('RPC Reset Error', '$resetMessage\n\n$errorDetails');
        }
        return;
      }

      if (mounted && resetCounts.isNotEmpty) {
        await _showResetCountsDialog(resetCounts);
      }

      final seedResult = await SeedService.seedDemoData();
      final seedSuccess = seedResult['success'] as bool? ?? false;
      final seedMessage = seedResult['message'] as String? ?? 'Unknown result';
      final seedCounts = seedResult['counts'] as Map<String, int>? ?? {};

      setState(() {
        _seedMessage = seedSuccess
            ? 'Reset & re-seed completed successfully'
            : seedMessage;
        _isResetting = false;
      });

      if (seedSuccess && seedCounts.isNotEmpty) {
        if (mounted) _showSummaryDialog(seedCounts);
      } else if (!seedSuccess) {
        final errorDetails =
            seedResult['errorDetails'] ?? seedResult['error'] ?? '';
        if (mounted && errorDetails.toString().isNotEmpty) {
          _showErrorDialog(seedMessage, errorDetails.toString());
        }
      }

      if (seedSuccess) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _seedMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _seedMessage = 'Reset & re-seed failed: $e';
        _isResetting = false;
      });
      if (mounted) {
        _showErrorDialog('Reset Error', e.toString());
      }
    }
  }

  Future<void> _showResetCountsDialog(Map<String, dynamic> counts) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange, size: 28),
            SizedBox(width: 2.w),
            const Text('RPC Reset Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'reset_demo_data() RPC returned deletion counts:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2.h),
              ...counts.entries.map((entry) {
                return _buildCountRow(
                  entry.key,
                  entry.value is int ? entry.value : 0,
                );
              }),
              SizedBox(height: 2.h),
              const Text(
                'Now proceeding to re-seed demo data...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog(Map<String, int> counts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 2.w),
            const Text('Seeding Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo data has been successfully seeded. Summary:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2.h),
              _buildCountRow('Users', counts['users'] ?? 0),
              _buildCountRow('Stores', counts['stores'] ?? 0),
              _buildCountRow('Products', counts['products'] ?? 0),
              _buildCountRow('Categories', counts['categories'] ?? 0),
              _buildCountRow('Marketplace Listings', counts['listings'] ?? 0),
              _buildCountRow('Orders', counts['orders'] ?? 0),
              _buildCountRow('Conversations', counts['conversations'] ?? 0),
              _buildCountRow('Messages', counts['messages'] ?? 0),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow(String label, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 2.w),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  details,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontFamily: 'monospace',
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: CustomIconWidget(
                      iconName: 'admin_panel_settings',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email?.split('@')[0] ?? 'Admin',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.adminDashboard);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String route,
    int? notificationCount,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.toString().split('.').last,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: notificationCount != null && notificationCount > 0
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                notificationCount.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        Navigator.pop(context);

        final isAdminRoute = route == AppRoutes.adminDashboard ||
            route == AppRoutes.adminLandingDashboard ||
            route == AppRoutes.adminUsersManagement ||
            route == AppRoutes.adminRoleUpgradeManagement ||
            route == AppRoutes.adminCategories ||
            route == AppRoutes.adminAdsManagement ||
            route == AppRoutes.adminLogisticsManagement ||
            route == AppRoutes.enhancedOrderManagement;

        if (isAdminRoute) {
          print(
            '[NAV] going to admin route=$route, isAdmin=${context.read<AdminProvider>().isAdmin}',
          );

          await context
              .read<AdminProvider>()
              .checkAdminStatus(reason: 'nav_drawer_to_$route');

          print(
            '[NAV] after checkAdminStatus route=$route, isAdmin=${context.read<AdminProvider>().isAdmin}',
          );
        }

        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildAdminFooter() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Admin Logout',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text(
                    'Are you sure you want to logout from admin panel?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.authentication,
                    (route) => false,
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}
