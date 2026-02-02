import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';

class MarketplaceAccountScreen extends ConsumerWidget {
  const MarketplaceAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userProfile = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Account',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  child: Text(
                    userProfile.when(
                      data: (profile) =>
                          profile?.fullName?.substring(0, 1).toUpperCase() ??
                          'U',
                      loading: () => 'U',
                      error: (_, __) => 'U',
                    ),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.when(
                          data: (profile) => profile?.fullName ?? 'User',
                          loading: () => 'Loading...',
                          error: (_, __) => 'User',
                        ),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
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
          SizedBox(height: 3.h),
          Text(
            'My Activity',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          _buildMenuItem(
            context,
            icon: Icons.list_alt,
            title: 'My Ads',
            subtitle: 'View and manage your listings',
            onTap: () {
              Navigator.pushNamed(context, '/my-ads-screen');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Saved listings',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.chat_bubble,
            title: 'Messages',
            subtitle: 'Your conversations',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.chatListScreen);
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 1.h),
          _buildMenuItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help with marketplace',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    : AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 5.w,
                color: isDestructive
                    ? Colors.red[600]
                    : AppTheme.lightTheme.colorScheme.primary,
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
                      color: isDestructive ? Colors.red[600] : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 5.w, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
