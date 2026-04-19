import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:sizer/sizer.dart';

import '../../providers/marketplace_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/custom_image_widget.dart';
import '../marketplace_screen/widgets/marketplace_bottom_nav_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Use the dedicated myListingsProvider — fetches only current user's listings
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.myAds,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createListingScreen)
                  .then((result) {
                if (result == true) {
                  ref.invalidate(myListingsProvider);
                }
              });
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 60, color: theme.disabledColor),
                  SizedBox(height: 2.h),
                  Text(
                    AppLocalizations.of(context)!.noAdsYet,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 1.h),
                  Text(
                    AppLocalizations.of(context)!.createYourFirstListingToGet,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 3.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createListingScreen,
                      ).then((result) {
                        if (result == true) {
                          ref.invalidate(myListingsProvider);
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.createListing, maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.5.h,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myListingsProvider),
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                final imageUrl = listing.images.isNotEmpty
                    ? listing.images[0]
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.marketplaceListingDetailScreen,
                      arguments: listing.id,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3.w),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(3.w),
                          ),
                          child: imageUrl != null
                              ? CustomImageWidget(
                                  imageUrl: imageUrl,
                                  width: 25.w,
                                  height: 12.h,
                                  fit: BoxFit.cover,
                                  semanticLabel: listing.title,
                                )
                              : Container(
                                  width: 25.w,
                                  height: 12.h,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.image,
                                      size: 8.w, color: theme.disabledColor),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        listing.title,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: listing.isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(1.w),
                                      ),
                                      child: Text(
                                        listing.isSold
                                            ? AppLocalizations.of(context)!.sold
                                            : listing.isActive
                                                ? AppLocalizations.of(context)!.active2
                                                : AppLocalizations.of(context)!.inactive2,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: listing.isSold
                                              ? Colors.orange
                                              : listing.isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  '\$${listing.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Icon(Icons.visibility,
                                        size: 4.w,
                                        color: Colors.grey),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing.views} views',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey,
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    SizedBox(width: 3.w),
                                    Icon(Icons.chat_bubble_outline,
                                        size: 4.w,
                                        color: Colors.grey),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing.inquiries} inquiries',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey,
                                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            final service = MarketplaceService();
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.marketplaceListingDetailScreen,
                                arguments: listing.id,
                              );
                            } else if (value == 'sold') {
                              await service.markAsSold(listing.id);
                              ref.invalidate(myListingsProvider);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.deleteListing2, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  content: Text(
                                      AppLocalizations.of(context)!.areYouSureYouWantTo10, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: Text(AppLocalizations.of(context)!.delete,
                                          style:
                                              TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await service.deleteListing(listing.id);
                                ref.invalidate(myListingsProvider);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.edit, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (!listing.isSold)
                              PopupMenuItem(
                                value: 'sold',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 20, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.markAsSold, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.delete,
                                      style: TextStyle(color: Colors.red), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.failedToLoadAds,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              TextButton(
                onPressed: () => ref.invalidate(myListingsProvider),
                child: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MarketplaceBottomNavWidget(
        currentIndex: 3,
        onIndexChanged: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.marketplaceScreen);
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.chatListScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.createListingScreen)
                .then((result) {
              if (result == true) ref.invalidate(myListingsProvider);
            });
          } else if (index == 4) {
            Navigator.pushNamed(context, AppRoutes.marketplaceAccountScreen);
          }
        },
      ),
    );
  }
}