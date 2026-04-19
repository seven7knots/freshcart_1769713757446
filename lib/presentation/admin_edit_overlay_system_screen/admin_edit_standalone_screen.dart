import 'package:flutter/material.dart' hide FilterChip;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/content_edit_modal_widget.dart';
import '../../l10n/generated/app_localizations.dart';

/// Standalone Admin Edit Screen
/// This screen provides a central hub for admin content management
class AdminEditStandaloneScreen extends StatefulWidget {
  const AdminEditStandaloneScreen({super.key});

  @override
  State<AdminEditStandaloneScreen> createState() =>
      _AdminEditStandaloneScreenState();
}

class _AdminEditStandaloneScreenState extends State<AdminEditStandaloneScreen> {
  String _selectedContentType = 'all';

  final List<Map<String, dynamic>> _contentTypes = [
    {'key': 'all', 'label': 'All Content', 'icon': Icons.dashboard},
    {'key': 'ad', 'label': 'Ads / Banners', 'icon': Icons.campaign},
    {'key': 'category', 'label': 'Categories', 'icon': Icons.category},
    {'key': 'product', 'label': 'Products', 'icon': Icons.shopping_bag},
    {'key': 'store', 'label': 'Stores', 'icon': Icons.store},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      if (!adminProvider.isEditMode) {
        adminProvider.setEditMode(true);
      }
    });
  }

  void _openCreateEditor(String contentType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentEditModalWidget(
        contentType: contentType,
        contentId: null,
        contentData: contentType == 'product' ? {'store_id': ''} : null,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$contentType created successfully!', maxLines: 1, overflow: TextOverflow.ellipsis),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);

    if (!adminProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: theme.colorScheme.outline),
              SizedBox(height: 2.h),
              Text(AppLocalizations.of(context)!.adminAccessRequired,
                  style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              Text(
                AppLocalizations.of(context)!.youDoNotHavePermissionTo2,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
    }

    return AdminLayoutWrapper(
      currentRoute: AppRoutes.adminEditOverlaySystem,
      child: Scaffold(
        appBar: AppBar(
          // FIX Issue 7: Shorter title that doesn't truncate
          title: Text(
            AppLocalizations.of(context)!.contentManager,
            style: TextStyle(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                children: [
                  Flexible(child: Text(
                    AppLocalizations.of(context)!.editMode,
                    style: TextStyle(fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Switch(
                    value: adminProvider.isEditMode,
                    onChanged: (value) => adminProvider.setEditMode(value),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Edit Mode Status Banner
            if (adminProvider.isEditMode)
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade400,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: theme.colorScheme.surface, size: 20),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.editModeIsOnTapEdit,
                        style: TextStyle(
                          color: theme.colorScheme.surface,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),



            // Quick Actions Grid
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.quickActions,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    // FIX Issue 8 + Overflow: Changed childAspectRatio from 1.3 to 1.1
                    // so cards have enough height for icon + title + subtitle without overflow
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                          icon: Icons.add_circle,
                          title: AppLocalizations.of(context)!.createAd,
                          subtitle: AppLocalizations.of(context)!.addNewBannerPromotion,
                          color: Colors.blue,
                          onTap: () => _openCreateEditor('ad'),
                        ),
                        _buildActionCard(
                          icon: Icons.category,
                          title: AppLocalizations.of(context)!.manageCategories,
                          subtitle: AppLocalizations.of(context)!.addEditCategories,
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.adminCategories),
                        ),
                        _buildActionCard(
                          icon: Icons.store,
                          title: AppLocalizations.of(context)!.createStore,
                          subtitle: AppLocalizations.of(context)!.addNewStore,
                          color: Colors.teal,
                          onTap: () => _openCreateEditor('store'),
                        ),
                        _buildActionCard(
                          icon: Icons.shopping_bag,
                          title: AppLocalizations.of(context)!.createProduct,
                          subtitle: AppLocalizations.of(context)!.addNewProduct,
                          color: Colors.orange,
                          onTap: () => _openCreateEditor('product'),
                        ),
                        _buildActionCard(
                          icon: Icons.campaign,
                          title: AppLocalizations.of(context)!.adsManager,
                          subtitle: AppLocalizations.of(context)!.viewAllAds,
                          color: Colors.red,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.adminAdsManagement),
                        ),
                        _buildActionCard(
                          icon: Icons.home,
                          title: AppLocalizations.of(context)!.viewAsCustomer,
                          subtitle: AppLocalizations.of(context)!.testCustomerView,
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.home),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Instructions
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info,
                                  color: Colors.blue.shade700),
                              SizedBox(width: 2.w),
                              Flexible(child: Text(
                                AppLocalizations.of(context)!.howToEditContent,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 14.sp,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '1. Enable "Edit Mode" using the toggle above or the floating pen button\n'
                            '2. Navigate to the customer-facing screens (Home, Marketplace, etc.)\n'
                            '3. Look for edit icons that appear on editable sections\n'
                            '4. Tap the edit icon to modify content directly\n'
                            '5. Disable edit mode when done to see the customer view',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12.sp,
                              height: 1.5,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: color.withAlpha(230),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.3.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}