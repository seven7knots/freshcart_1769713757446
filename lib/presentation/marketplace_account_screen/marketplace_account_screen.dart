// ============================================================
// FILE: lib/presentation/marketplace_account_screen/marketplace_account_screen.dart
// ============================================================
// SESSION 29 FIX:
// - Removed all non-functional menu items with empty onTap handlers:
//   Favorites, Notifications, Language, Help & Support, Privacy Policy.
// - Kept only working items: My Ads, Messages, Logout.
// - "My Activity" section header renamed to match trimmed list.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class MarketplaceAccountScreen extends ConsumerStatefulWidget {
  const MarketplaceAccountScreen({super.key});

  @override
  ConsumerState<MarketplaceAccountScreen> createState() =>
      _MarketplaceAccountScreenState();
}

class _MarketplaceAccountScreenState
    extends ConsumerState<MarketplaceAccountScreen> {
  bool _checkedAdmin = false;
  bool _isAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedAdmin) {
      _checkedAdmin = true;
      _checkAdminAndRedirect();
    }
  }

  Future<void> _checkAdminAndRedirect() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await Supabase.instance.client.rpc('is_admin');
      final isAdmin = res == true;

      if (!mounted) return;

      setState(() => _isAdmin = isAdmin);

      if (isAdmin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.adminLandingDashboard,
            (route) => false,
          );
        });
      }
    } catch (_) {
      // Ignore; keep marketplace account screen
    }
  }

  String _getFullName(dynamic profile, {String fallback = 'User'}) {
    if (profile == null) return fallback;
    if (profile is Map<String, dynamic>) {
      return (profile['full_name'] as String?) ?? fallback;
    }
    try {
      return (profile.fullName as String?) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userProfile = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.account,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // ── Profile card ──
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    userProfile.when(
                      data: (profile) {
                        final name = _getFullName(profile);
                        return name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : 'U';
                      },
                      loading: () => 'U',
                      error: (_, __) => 'U',
                    ),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.surface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.when(
                          data: (profile) => _getFullName(profile),
                          loading: () => 'Loading...',
                          error: (_, __) => 'User',
                        ),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),
              ],
            ),
          ),

          // ── Admin shortcut (only visible to admins) ──
          if (_isAdmin) ...[
            SizedBox(height: 2.h),
            _buildMenuItem(
              context,
              icon: Icons.admin_panel_settings,
              title: AppLocalizations.of(context)!.adminDashboard,
              subtitle: AppLocalizations.of(context)!.openAdminControls,
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.adminLandingDashboard,
                  (route) => false,
                );
              },
            ),
          ],

          SizedBox(height: 3.h),

          // ── My Activity ──
          Text(
            AppLocalizations.of(context)!.myActivity,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          _buildMenuItem(
            context,
            icon: Icons.list_alt,
            title: AppLocalizations.of(context)!.myAds,
            subtitle: AppLocalizations.of(context)!.viewAndManageYourListings,
            onTap: () {
              Navigator.pushNamed(context, '/my-ads-screen');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.chat_bubble,
            title: AppLocalizations.of(context)!.messages,
            subtitle: AppLocalizations.of(context)!.yourConversations,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.chatListScreen);
            },
          ),

          SizedBox(height: 3.h),

          // ── Logout ──
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: AppLocalizations.of(context)!.logout,
            subtitle: AppLocalizations.of(context)!.signOutOfYourAccount,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.authentication,
                  (route) => false,
                );
              }
            },
            isDestructive: true,
          ),
        ],
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: 4,
        onIndexChanged: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, AppRoutes.marketplaceScreen);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen);
          } else if (index == 3) {
            Navigator.pushNamed(context, '/my-ads-screen');
          }
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red[50]
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 5.w,
                color: isDestructive
                    ? Colors.red[600]
                    : theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          isDestructive ? Colors.red[600] : Colors.black87,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 5.w, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}