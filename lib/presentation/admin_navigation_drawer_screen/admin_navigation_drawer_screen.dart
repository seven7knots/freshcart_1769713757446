import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/seed_service.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final theme = Theme.of(context);

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
                    title: AppLocalizations.of(context)!.dashboard,
                    items: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        title: AppLocalizations.of(context)!.analyticsOverview,
                        route: AppRoutes.adminLandingDashboard,
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: Text(AppLocalizations.of(context)!.users, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.adminUsersManagement);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_ind_outlined),
                    title: Text(AppLocalizations.of(context)!.roleRequests, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.adminRoleUpgradeManagement);
                    },
                  ),
                  _buildNavigationSection(
                    title: AppLocalizations.of(context)!.contentManagement,
                    items: [
                      _buildNavItem(
                        icon: Icons.inventory,
                        title: AppLocalizations.of(context)!.products,
                        route: AppRoutes.home,
                      ),
                      _buildNavItem(
                        icon: Icons.category,
                        title: AppLocalizations.of(context)!.categories,
                        route: AppRoutes.allCategoriesScreen,
                      ),
                      _buildNavItem(
                        icon: Icons.admin_panel_settings,
                        title: AppLocalizations.of(context)!.adminCategories,
                        route: AppRoutes.adminCategories,
                      ),
                      _buildNavItem(
                        icon: Icons.storefront,
                        title: AppLocalizations.of(context)!.stores,
                        route: AppRoutes.marketplaceScreen,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: AppLocalizations.of(context)!.orderOperations,
                    items: [
                      _buildNavItem(
                        icon: Icons.shopping_bag,
                        title: AppLocalizations.of(context)!.activeOrders,
                        route: AppRoutes.enhancedOrderManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.assignment,
                        title: AppLocalizations.of(context)!.deliveryAssignments,
                        route: AppRoutes.enhancedOrderManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.map,
                        title: AppLocalizations.of(context)!.logisticsManagement,
                        route: AppRoutes.adminLogisticsManagement,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: AppLocalizations.of(context)!.marketingTools,
                    items: [
                      _buildNavItem(
                        icon: Icons.campaign,
                        title: AppLocalizations.of(context)!.adsPromotions,
                        route: AppRoutes.adminAdsManagement,
                      ),
                      _buildNavItem(
                        icon: Icons.local_offer,
                        title: AppLocalizations.of(context)!.campaigns,
                        route: AppRoutes.adminAdsManagement,
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: AppLocalizations.of(context)!.systemSettings,
                    items: [
                      _buildNavItem(
                        icon: Icons.settings,
                        title: AppLocalizations.of(context)!.appConfiguration,
                        route: AppRoutes.adminDashboard,
                      ),
                      _buildNavItem(
                        icon: Icons.security,
                        title: AppLocalizations.of(context)!.permissions,
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
                          AppLocalizations.of(context)!.developerTools,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                            _isSeeding ? AppLocalizations.of(context)!.seeding : AppLocalizations.of(context)!.seedDemoData,
                            style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.primary,
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
                            _isResetting ? AppLocalizations.of(context)!.resetting : AppLocalizations.of(context)!.resetDemoData2,
                            style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                              borderRadius: BorderRadius.circular(14),
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
                              ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        _showErrorDialog(AppLocalizations.of(context)!.seedingError, e.toString());
      }
    }
  }

  Future<void> _handleResetDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetDemoData, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
          AppLocalizations.of(context)!.thisWillCallResetDemoData, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.resetReSeed, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          resetResult['message'] as String? ?? AppLocalizations.of(context)!.unknownResult;
      final resetCounts = resetResult['counts'] as Map<String, dynamic>? ?? {};

      if (!resetSuccess) {
        setState(() {
          _seedMessage = resetMessage;
          _isResetting = false;
        });
        if (mounted) {
          final errorDetails = resetResult['errorDetails'] ?? '';
          _showErrorDialog(AppLocalizations.of(context)!.rpcResetError, '$resetMessage\n\n$errorDetails');
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
            ? AppLocalizations.of(context)!.resetReSeedCompletedSuccessfully
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
        _showErrorDialog(AppLocalizations.of(context)!.resetError, e.toString());
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
            Flexible(child: Text(AppLocalizations.of(context)!.rpcResetComplete, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.resetDemoDataRpcReturnedDeletion,
                style: TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              ...counts.entries.map((entry) {
                return _buildCountRow(
                  entry.key,
                  entry.value is int ? entry.value : 0,
                );
              }),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.nowProceedingToReSeedDemo,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.continueText, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Flexible(child: Text(AppLocalizations.of(context)!.seedingComplete, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.demoDataHasBeenSuccessfullySeeded,
                style: TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              _buildCountRow(AppLocalizations.of(context)!.users, counts['users'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.stores, counts['stores'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.products, counts['products'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.categories, counts['categories'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.marketplaceListings, counts['listings'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.orders, counts['orders'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.conversations, counts['conversations'] ?? 0),
              _buildCountRow(AppLocalizations.of(context)!.messages, counts['messages'] ?? 0),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          Flexible(child: Text(label, style: TextStyle(fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.errorDetails,
                style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  details,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontFamily: 'monospace',
                    color: Colors.red[900],
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
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
                      color: theme.colorScheme.primary,
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
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
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
              color: Colors.grey,
              letterSpacing: 0.5,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final theme = Theme.of(context);

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.toString().split('.').last,
        color: theme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            )
          : Icon(Icons.chevron_right, color: Colors.grey),
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
          top: BorderSide(color: Colors.grey.shade300!, width: 1),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              AppLocalizations.of(context)!.adminLogout,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.confirmLogout, maxLines: 1, overflow: TextOverflow.ellipsis),
                  content: Text(
                    AppLocalizations.of(context)!.areYouSureYouWantTo11, maxLines: 1, overflow: TextOverflow.ellipsis),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.logout,
                        style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
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