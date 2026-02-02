import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/role_upgrade_service.dart';
import './widgets/loyalty_rewards_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;

  final RoleUpgradeService _roleUpgradeService = RoleUpgradeService();
  bool _canRequestUpgrade = false;
  List<Map<String, dynamic>> _userRequests = [];

  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "phone": "+1 (555) 123-4567",
    "avatar": "https://images.unsplash.com/photo-1727784892015-4f4b8d67a083",
    "avatarSemanticLabel":
        "Professional headshot of a woman with shoulder-length brown hair wearing a white blazer against a neutral background",
    "membershipTier": "Gold Member",
    "totalOrders": 47,
    "loyaltyPoints": 2840,
    "totalSaved": 156.50,
    "isPhoneVerified": true,
    "isEmailVerified": true,
    "joinDate": "March 2023",
  };

  // Mock rewards data
  final Map<String, dynamic> rewardsData = {
    "currentPoints": 2840,
    "nextTierPoints": 5000,
    "nextTier": "Platinum",
    "freeDeliveries": 3,
    "cashbackRate": 5,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkRoleUpgradeEligibility();
    _loadUserRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                title: Text(
                  'Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                automaticallyImplyLeading: false,
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      // Navigate to settings
                    },
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ];
        },
        body: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        if (_isLoading) return _buildLoadingState();

        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [_buildProfileTab(), _buildSettingsTab()],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          SizedBox(height: 2.h),
          Text(
            'Loading profile...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeaderWidget(userData: userData, onEditPressed: _editProfile),
          SizedBox(height: 3.h),
          LoyaltyRewardsWidget(
            rewardsData: rewardsData,
            onViewAllPressed: _viewAllRewards,
          ),
          SettingsSectionWidget(
            title: 'Quick Actions',
            items: _getQuickActionItems(),
          ),
          SettingsSectionWidget(
            title: 'Account Information',
            items: _getAccountItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),

          // Admin Section - Only show for admin users
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAdmin) {
                return Column(
                  children: [
                    SettingsSectionWidget(
                      title: "Admin Panel",
                      items: _getAdminItems(),
                    ),
                    SizedBox(height: 2.h),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          SettingsSectionWidget(title: "Account", items: _getAccountItems()),
          SettingsSectionWidget(
            title: 'Delivery & Addresses',
            items: _getDeliveryItems(),
          ),
          SettingsSectionWidget(
            title: 'Payment & Billing',
            items: _getPaymentItems(),
          ),
          SettingsSectionWidget(
            title: 'App Preferences',
            items: _getPreferenceItems(),
          ),
          SettingsSectionWidget(
            title: 'Help & Support',
            items: _getHelpItems(),
          ),
          SizedBox(height: 2.h),
          _buildSignOutButton(),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickActionItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "history",
        "iconColor": theme.colorScheme.primary,
        "title": "Order History",
        "subtitle": "View past orders and reorder",
        "route": "/order-history-screen",
      },
      {
        "icon": "shopping_cart",
        "iconColor": theme.colorScheme.secondary,
        "title": "Shopping Cart",
        "subtitle": "Continue your shopping",
        "route": "/shopping-cart-screen",
      },
      {
        "icon": "favorite",
        "iconColor": theme.colorScheme.error,
        "title": "Wishlist",
        "subtitle": "Saved items for later",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getAdminItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "admin_panel_settings",
        "iconColor": theme.colorScheme.error,
        "title": "Admin Dashboard",
        "subtitle": "Manage users, orders, and system",
        "route": AppRoutes.adminDashboard,
      },
      {
        "icon": "people",
        "iconColor": theme.colorScheme.primary,
        "title": "User Management",
        "subtitle": "View and manage all users",
        "route": AppRoutes.adminUsersManagement,
      },
      {
        "icon": "shopping_bag",
        "iconColor": theme.colorScheme.secondary,
        "title": "Order Management",
        "subtitle": "Monitor and manage orders",
        "route": AppRoutes.enhancedOrderManagement,
      },
      {
        "icon": "campaign",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Ads Management",
        "subtitle": "Create and manage advertisements",
        "route": AppRoutes.adminAdsManagement,
      },
    ];
  }

  List<Map<String, dynamic>> _getAccountItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "store",
        "iconColor": theme.colorScheme.primary,
        "title": "Merchant Profile",
        "subtitle": "Manage your business account",
        "route": "/merchant-profile-screen",
      },
      {
        "icon": "person",
        "iconColor": theme.colorScheme.primary,
        "title": "Personal Information",
        "subtitle": "Name, email, phone number",
        "route": null,
      },
      {
        "icon": "security",
        "iconColor": theme.colorScheme.secondary,
        "title": "Privacy & Security",
        "subtitle": "Password, biometric settings",
        "route": null,
        "trailing": Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Verified',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      },
      {
        "icon": "notifications",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Notification Preferences",
        "subtitle": "Order updates, promotions",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getDeliveryItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "location_on",
        "iconColor": theme.colorScheme.primary,
        "title": "Delivery Addresses",
        "subtitle": "Manage your delivery locations",
        "route": null,
      },
      {
        "icon": "schedule",
        "iconColor": theme.colorScheme.secondary,
        "title": "Delivery Preferences",
        "subtitle": "Time slots, special instructions",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getPaymentItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "payment",
        "iconColor": theme.colorScheme.primary,
        "title": "Payment Methods",
        "subtitle": "Manage cards and payment options",
        "route": null,
      },
      {
        "icon": "account_balance_wallet",
        "iconColor": theme.colorScheme.secondary,
        "title": "Wallet",
        "subtitle": "View balance and transactions",
        "route": null,
      },
      {
        "icon": "card_membership",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Subscription Plans",
        "subtitle": "Manage your subscription",
        "route": "/subscription-management-screen",
      },
      {
        "icon": "receipt_long",
        "iconColor": theme.colorScheme.error,
        "title": "Billing History",
        "subtitle": "View past invoices and receipts",
        "route": null,
      },
    ];
  }

  List<Map<String, dynamic>> _getPreferenceItems() {
    final theme = Theme.of(context);

    return [
      {
        "icon": "language",
        "iconColor": theme.colorScheme.primary,
        "title": "Language",
        "subtitle": "English (US)",
        "route": null,
      },
      {
        "icon": "restaurant",
        "iconColor": theme.colorScheme.secondary,
        "title": "Dietary Restrictions",
        "subtitle": "Allergies, preferences",
        "route": null,
      },

      // Theme: make it 3-state (System/Light/Dark) to avoid mismatches + mixed UI
      {
        "icon": "dark_mode",
        "iconColor": theme.colorScheme.onSurfaceVariant,
        "title": "App Theme",
        "subtitle": _themeModeLabel(context),
        "route": null,
        "trailing": Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final cs = Theme.of(context).colorScheme;

            return PopupMenuButton<ThemeMode>(
              tooltip: 'Theme',
              initialValue: themeProvider.themeMode,
              onSelected: (mode) => themeProvider.setThemeMode(mode),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _themeModeShortLabel(themeProvider.themeMode),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(width: 1.5.w),
                  Icon(Icons.expand_more, color: cs.primary),
                ],
              ),
            );
          },
        ),
      },
    ];
  }

  String _themeModeLabel(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context, listen: false);

    switch (tp.themeMode) {
      case ThemeMode.system:
        return Theme.of(context).brightness == Brightness.dark
            ? "System (Dark)"
            : "System (Light)";
      case ThemeMode.dark:
        return "Dark mode";
      case ThemeMode.light:
        return "Light mode";
    }
  }

  String _themeModeShortLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  List<Map<String, dynamic>> _getHelpItems() {
    final theme = Theme.of(context);
    return [
      {
        "icon": "help",
        "iconColor": theme.colorScheme.primary,
        "title": "Help Center",
        "subtitle": "FAQs and support articles",
        "route": null,
      },
      {
        "icon": "chat",
        "iconColor": theme.colorScheme.secondary,
        "title": "Live Chat",
        "subtitle": "Get instant help",
        "route": null,
      },
      {
        "icon": "feedback",
        "iconColor": theme.colorScheme.tertiary,
        "title": "Send Feedback",
        "subtitle": "Help us improve the app",
        "route": null,
      },
      {
        "icon": "info",
        "iconColor": theme.colorScheme.onSurfaceVariant,
        "title": "About KJ Delivery",
        "subtitle": "Version 2.1.0",
        "route": null,
      },
    ];
  }

  Widget _buildSignOutButton() {
    final theme = Theme.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () => _handleSignOut(authProvider),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 5.w,
                    width: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onError,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      SizedBox(width: 2.w),
                      Text(
                        'Sign Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(AuthProvider authProvider) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final notificationsProvider = Provider.of<NotificationsProvider>(
        context,
        listen: false,
      );
      notificationsProvider.clearNotifications();

      await authProvider.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.authentication,
          (route) => false,
        );
      }
    }
  }

  void _editProfile() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit profile feature coming soon!'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _viewAllRewards() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rewards center coming soon!'),
        backgroundColor: theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Kept (if referenced elsewhere), now theme-aware + does not hardcode mode labels.
  void _toggleTheme(bool value) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);

    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark theme enabled' : 'Light theme enabled'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSettingsMenu() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'download',
                color: theme.colorScheme.secondary,
                size: 6.w,
              ),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile sharing feature coming soon!'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportData() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data export feature coming soon!'),
        backgroundColor: theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _signOut() {
    final theme = Theme.of(context);
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/authentication-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final notificationsProvider = Provider.of<NotificationsProvider>(
                context,
                listen: false,
              );
              notificationsProvider.clearNotifications();

              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/authentication-screen',
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRoleUpgradeEligibility() async {
    try {
      final canRequest = await _roleUpgradeService.canRequestRoleUpgrade();
      if (mounted) {
        setState(() {
          _canRequestUpgrade = canRequest;
        });
      }
    } catch (e) {
      debugPrint('[PROFILE] Error checking upgrade eligibility: $e');
    }
  }

  Future<void> _loadUserRequests() async {
    try {
      final requests = await _roleUpgradeService.getUserRoleUpgradeRequests();
      if (mounted) {
        setState(() {
          _userRequests = requests;
        });
      }
    } catch (e) {
      debugPrint('[PROFILE] Error loading requests: $e');
    }
  }

  Future<void> _showRoleUpgradeDialog() async {
    String? selectedRole;
    final notesController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return AlertDialog(
          title: const Text('Request Role Upgrade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select the role you want to upgrade to:'),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'merchant', child: Text('Merchant')),
                ],
                onChanged: (value) {
                  selectedRole = value;
                },
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRole == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please select a role'),
                      backgroundColor: cs.tertiary,
                    ),
                  );
                  return;
                }

                try {
                  final response =
                      await _roleUpgradeService.createRoleUpgradeRequest(
                    requestedRole: selectedRole!,
                    requestNotes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop(true);

                    final bool ok = response['success'] == true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(response['message'] ?? 'Request submitted'),
                        backgroundColor: ok ? cs.primary : cs.error,
                      ),
                    );

                    if (ok) {
                      _checkRoleUpgradeEligibility();
                      _loadUserRequests();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  void _showUserRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return AlertDialog(
          title: const Text('My Role Upgrade Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _userRequests.length,
              itemBuilder: (context, index) {
                final request = _userRequests[index];
                final status = request['status'] as String;
                final requestedRole = request['requested_role'] as String;
                final createdAt =
                    DateTime.parse(request['created_at'] as String);

                Color statusColor;
                IconData statusIcon;
                switch (status) {
                  case 'pending':
                    statusColor = cs.tertiary;
                    statusIcon = Icons.pending;
                    break;
                  case 'approved':
                    statusColor = cs.primary;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'rejected':
                    statusColor = cs.error;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = cs.outline;
                    statusIcon = Icons.help;
                }

                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: ListTile(
                    leading: Icon(statusIcon, color: statusColor),
                    title: Text(
                      'Upgrade to ${requestedRole.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${status.toUpperCase()}'),
                        Text(
                          'Requested: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        ),
                        if (status == 'rejected' &&
                            request['rejection_reason'] != null)
                          Text(
                            'Reason: ${request['rejection_reason']}',
                            style: TextStyle(color: cs.error),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
