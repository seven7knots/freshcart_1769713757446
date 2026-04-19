import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/custom_tab_bar.dart';
import './widgets/product_listings_widget.dart';
import './widgets/service_categories_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class MarketplaceHomeScreen extends ConsumerWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedTab = ref.watch(marketplaceTabProvider);
    final unreadCountAsync = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.marketplace,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          // Messages icon with unread badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chatListScreen);
                },
              ),
              unreadCountAsync.when(
                data: (count) {
                  if (count > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50914),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.surface,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: CustomTabBar(
              tabs: const ['Services', 'Products'],
              onTap: (index) {
                ref.read(marketplaceTabProvider.notifier).state = index;
              },
            ),
          ),
          Expanded(
            child: selectedTab == 0
                ? const ServiceCategoriesWidget()
                : const ProductListingsWidget(),
          ),
        ],
      ),
    );
  }
}