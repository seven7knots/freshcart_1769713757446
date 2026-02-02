import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import './floating_ai_chatbox.dart';

/// Admin-specific layout wrapper with sidebar navigation
/// Replaces customer bottom nav with admin drawer/sidebar
class AdminLayoutWrapper extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayoutWrapper({
    super.key,
    required this.child,
    this.currentRoute = AppRoutes.adminLandingDashboard,
  });

  @override
  State<AdminLayoutWrapper> createState() => _AdminLayoutWrapperState();
}

class _AdminLayoutWrapperState extends State<AdminLayoutWrapper> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAdminDrawer(context),
      body: Stack(
        children: [
          widget.child,
          const FloatingAIChatbox(),
        ],
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Admin Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
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
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: theme.primaryColor,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                authProvider.currentUser?.email ??
                                    'admin@app.com',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: AppRoutes.adminLandingDashboard,
                      isSelected: widget.currentRoute ==
                          AppRoutes.adminLandingDashboard,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      title: 'User Management',
                      route: AppRoutes.adminUsersManagement,
                      isSelected:
                          widget.currentRoute == AppRoutes.adminUsersManagement,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.shopping_bag,
                      title: 'Order Management',
                      route: AppRoutes.enhancedOrderManagement,
                      isSelected: widget.currentRoute ==
                          AppRoutes.enhancedOrderManagement,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.campaign,
                      title: 'Ads Management',
                      route: AppRoutes.adminAdsManagement,
                      isSelected:
                          widget.currentRoute == AppRoutes.adminAdsManagement,
                    ),
                    Divider(height: 3.h),
                    _buildDrawerItem(
                      context,
                      icon: Icons.edit,
                      title: 'Edit Overlay System',
                      route: AppRoutes.adminEditOverlaySystem,
                      isSelected: widget.currentRoute ==
                          AppRoutes.adminEditOverlaySystem,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.store,
                      title: 'View Marketplace',
                      route: AppRoutes.marketplaceScreen,
                      isSelected:
                          widget.currentRoute == AppRoutes.marketplaceScreen,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'View Customer Home',
                      route: AppRoutes.home,
                      isSelected: widget.currentRoute == AppRoutes.home,
                    ),
                  ],
                ),
              ),
              // Logout Button
              Padding(
                padding: EdgeInsets.all(4.w),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.authentication,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.primaryColor : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.primaryColor : Colors.grey[800],
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          if (widget.currentRoute != route) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
