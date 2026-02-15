// ============================================================
// FILE: lib/presentation/favorites_screen/favorites_screen.dart
// ============================================================
// Favorites screen with two tabs:
// - Delivery Favorites (products from delivery stores)
// - Marketplace Favorites (marketplace listings)
// Backed by Supabase `user_favorites` table
// ============================================================

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/product_model.dart';
import '../../services/supabase_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _deliveryFavorites = [];
  List<Map<String, dynamic>> _marketplaceFavorites = [];
  bool _isLoadingDelivery = true;
  bool _isLoadingMarketplace = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeliveryFavorites();
    _loadMarketplaceFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryFavorites() async {
    setState(() => _isLoadingDelivery = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingDelivery = false);
        return;
      }

      final result = await SupabaseService.client
          .from('user_favorites')
          .select('*, products(*)')
          .eq('user_id', userId)
          .eq('favorite_type', 'delivery')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _deliveryFavorites = List<Map<String, dynamic>>.from(result);
          _isLoadingDelivery = false;
        });
      }
    } catch (e) {
      debugPrint('[FAVORITES] Error loading delivery favorites: $e');
      if (mounted) setState(() => _isLoadingDelivery = false);
    }
  }

  Future<void> _loadMarketplaceFavorites() async {
    setState(() => _isLoadingMarketplace = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingMarketplace = false);
        return;
      }

      final result = await SupabaseService.client
          .from('user_favorites')
          .select('*, marketplace_listings(*)')
          .eq('user_id', userId)
          .eq('favorite_type', 'marketplace')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _marketplaceFavorites = List<Map<String, dynamic>>.from(result);
          _isLoadingMarketplace = false;
        });
      }
    } catch (e) {
      debugPrint('[FAVORITES] Error loading marketplace favorites: $e');
      if (mounted) setState(() => _isLoadingMarketplace = false);
    }
  }

  Future<void> _removeFavorite(String favoriteId, String type) async {
    try {
      await SupabaseService.client
          .from('user_favorites')
          .delete()
          .eq('id', favoriteId);

      if (type == 'delivery') {
        _loadDeliveryFavorites();
      } else {
        _loadMarketplaceFavorites();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 20),
              text: 'Delivery',
            ),
            Tab(
              icon: const Icon(Icons.storefront_outlined, size: 20),
              text: 'Marketplace',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeliveryTab(theme),
          _buildMarketplaceTab(theme),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY FAVORITES TAB
  // ============================================================

  Widget _buildDeliveryTab(ThemeData theme) {
    if (_isLoadingDelivery) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deliveryFavorites.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.local_shipping_outlined,
        title: 'No delivery favorites yet',
        subtitle: 'Browse stores and tap the heart icon to save products here',
        buttonText: 'Browse Stores',
        onPressed: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveryFavorites,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _deliveryFavorites.length,
        itemBuilder: (context, index) {
          final fav = _deliveryFavorites[index];
          final product = fav['products'] as Map<String, dynamic>?;

          if (product == null) {
            return const SizedBox.shrink();
          }

          return _buildFavoriteCard(
            theme: theme,
            favoriteId: fav['id'] as String,
            type: 'delivery',
            name: product['name'] ?? 'Unknown Product',
            subtitle: product['store_name'] ?? 'Store',
            price: _formatPrice(product['price']),
            imageUrl: product['image_url'] as String?,
            onTap: () {
              try {
                final p = Product.fromJson(product);
                Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open product')),
                );
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // MARKETPLACE FAVORITES TAB
  // ============================================================

  Widget _buildMarketplaceTab(ThemeData theme) {
    if (_isLoadingMarketplace) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_marketplaceFavorites.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.storefront_outlined,
        title: 'No marketplace favorites yet',
        subtitle: 'Browse the marketplace and save listings you like',
        buttonText: 'Browse Marketplace',
        onPressed: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.marketplaceScreen);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarketplaceFavorites,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _marketplaceFavorites.length,
        itemBuilder: (context, index) {
          final fav = _marketplaceFavorites[index];
          final listing = fav['marketplace_listings'] as Map<String, dynamic>?;

          if (listing == null) {
            return const SizedBox.shrink();
          }

          return _buildFavoriteCard(
            theme: theme,
            favoriteId: fav['id'] as String,
            type: 'marketplace',
            name: listing['title'] ?? 'Unknown Listing',
            subtitle: listing['seller_name'] ?? 'Seller',
            price: _formatPrice(listing['price']),
            imageUrl: listing['image_url'] as String?,
            onTap: () {
              // Navigate to marketplace listing detail
              Navigator.pushNamed(
                context,
                AppRoutes.marketplaceScreen,
                arguments: listing['id'],
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildFavoriteCard({
    required ThemeData theme,
    required String favoriteId,
    required String type,
    required String name,
    required String subtitle,
    required String price,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 8.w,
                          ),
                        )
                      : Icon(
                          type == 'delivery'
                              ? Icons.shopping_bag_outlined
                              : Icons.storefront_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 8.w,
                        ),
                ),
              ),
              SizedBox(width: 3.w),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kjRed,
                      ),
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                onPressed: () => _confirmRemove(favoriteId, type, name),
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15.w, color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 3.h),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kjRed,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _confirmRemove(String favoriteId, String type, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: Text('Remove "$name" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeFavorite(favoriteId, type);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    final p = double.tryParse(price.toString()) ?? 0;
    return 'USD ${p.toStringAsFixed(2)}';
  }
}