import 'package:flutter/material.dart' hide FilterChip;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_layout_wrapper.dart';
import './widgets/content_edit_modal_widget.dart';

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
    // Enable edit mode when entering this screen
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
              content: Text('$contentType created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh
        },
      ),
    );
  }

  void _navigateToSpecificManagement(String contentType) {
    switch (contentType) {
      case 'ad':
        Navigator.pushNamed(context, AppRoutes.adminAdsManagement);
        break;
      case 'category':
        Navigator.pushNamed(context, AppRoutes.adminCategories);
        break;
      case 'product':
      case 'store':
        // For products and stores, show create modal or navigate to a list
        _openCreateEditor(contentType);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);

    // Access check
    if (!adminProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              SizedBox(height: 2.h),
              Text(
                'Admin Access Required',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: 1.h),
              Text(
                'You do not have permission to access this page.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
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
          title: const Text('Content Management'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Edit Mode Toggle
            Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                children: [
                  Text(
                    'Edit Mode',
                    style: TextStyle(fontSize: 12.sp),
                  ),
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
                padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Edit mode is ON - Tap edit icons on supported sections throughout the app',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content Type Filter
            Container(
              height: 7.h,
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _contentTypes.length,
                itemBuilder: (context, index) {
                  final type = _contentTypes[index];
                  final isSelected = _selectedContentType == type['key'];
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(
                            () => _selectedContentType = type['key'] as String);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? Colors.orange : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 16,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 1.3,
                      children: [
                        _buildActionCard(
                          icon: Icons.add_circle,
                          title: 'Create Ad',
                          subtitle: 'Add new banner/promotion',
                          color: Colors.blue,
                          onTap: () => _openCreateEditor('ad'),
                        ),
                        _buildActionCard(
                          icon: Icons.category,
                          title: 'Manage Categories',
                          subtitle: 'Add/edit categories',
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.adminCategories),
                        ),
                        _buildActionCard(
                          icon: Icons.store,
                          title: 'Create Store',
                          subtitle: 'Add new store',
                          color: Colors.teal,
                          onTap: () => _openCreateEditor('store'),
                        ),
                        _buildActionCard(
                          icon: Icons.shopping_bag,
                          title: 'Create Product',
                          subtitle: 'Add new product',
                          color: Colors.orange,
                          onTap: () => _openCreateEditor('product'),
                        ),
                        _buildActionCard(
                          icon: Icons.campaign,
                          title: 'Ads Manager',
                          subtitle: 'View all ads',
                          color: Colors.red,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.adminAdsManagement),
                        ),
                        _buildActionCard(
                          icon: Icons.home,
                          title: 'View as Customer',
                          subtitle: 'Test customer view',
                          color: Colors.green,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.home),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Instructions
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              SizedBox(width: 2.w),
                              Text(
                                'How to Edit Content',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '1. Enable "Edit Mode" using the toggle above or the floating pen button\n'
                            '2. Navigate to the customer-facing screens (Home, Marketplace, etc.)\n'
                            '3. Look for edit icons (✏️) that appear on editable sections\n'
                            '4. Tap the edit icon to modify content directly\n'
                            '5. Disable edit mode when done to see the customer view',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 12.sp,
                              height: 1.5,
                            ),
                          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
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
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
