import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/cart_provider.dart';
import './widgets/cart_item_widget.dart';
import './widgets/delivery_time_selector_widget.dart';
import './widgets/order_summary_widget.dart';
import './widgets/saved_for_later_widget.dart';

class ShoppingCartScreen extends ConsumerStatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ConsumerState<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends ConsumerState<ShoppingCartScreen> {
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _savedItems = [];
  String? _selectedDeliverySlot = 'standard_2h';
  double _deliveryFee = 2.99;
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;
  final bool _isLoading = true;

  // Mock recently viewed products for empty cart state
  final List<Map<String, dynamic>> _recentlyViewedProducts = [
    {
      'id': 1,
      'name': 'Organic Bananas',
      'price': 2.99,
      'image': 'https://images.unsplash.com/photo-1565804212260-280f967e431b',
      'semanticLabel': 'Fresh organic bananas in a bunch on white background',
    },
    {
      'id': 2,
      'name': 'Fresh Milk',
      'price': 4.49,
      'image': 'https://images.unsplash.com/photo-1517448931760-9bf4414148c5',
      'semanticLabel': 'Glass of fresh white milk on wooden table',
    },
    {
      'id': 3,
      'name': 'Whole Wheat Bread',
      'price': 3.99,
      'image': 'https://images.unsplash.com/photo-1626423642733-9bb26dea2691',
      'semanticLabel': 'Sliced whole wheat bread loaf on cutting board',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Cart data will be loaded via provider
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _removeCartItem(int itemId) async {
    try {
      await ref
          .read(cartNotifierProvider.notifier)
          .removeItem(itemId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item removed from cart'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Implement undo functionality
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item: $e')),
        );
      }
    }
  }

  void _updateQuantity(int itemId, int newQuantity) async {
    try {
      await ref
          .read(cartNotifierProvider.notifier)
          .updateQuantity(itemId.toString(), newQuantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')),
        );
      }
    }
  }

  void _moveToWishlist(int itemId) {
    final item = _cartItems.firstWhere((item) => item['id'] == itemId);
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == itemId);
      _savedItems.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item moved to wishlist')),
    );
  }

  void _moveToCart(Map<String, dynamic> item) {
    setState(() {
      _savedItems.removeWhere((savedItem) => savedItem['id'] == item['id']);
      _cartItems.add({...item, 'quantity': 1});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item moved to cart')),
    );
  }

  void _removeFromSaved(Map<String, dynamic> item) {
    setState(() {
      _savedItems.removeWhere((savedItem) => savedItem['id'] == item['id']);
    });
  }

  void _onDeliverySlotSelected(String slotId, double fee) {
    setState(() {
      _selectedDeliverySlot = slotId;
      _deliveryFee = fee;
    });
  }

  void _onPromoCodeApplied(String promoCode) {
    setState(() {
      _appliedPromoCode = promoCode;
      // Calculate discount based on promo code
      switch (promoCode) {
        case 'SAVE10':
          _promoDiscount = _subtotal * 0.10;
          break;
        case 'WELCOME20':
          _promoDiscount = _subtotal * 0.20;
          break;
        case 'FIRST15':
          _promoDiscount = _subtotal * 0.15;
          break;
        case 'FRESH25':
          _promoDiscount = _subtotal * 0.25;
          break;
        default:
          _promoDiscount = 0.0;
      }
    });
  }

  void _onPromoCodeRemoved() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0.0;
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(cartNotifierProvider.notifier).clearCart();
                setState(() {
                  _cartItems.clear();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart cleared')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear cart: $e')),
                  );
                }
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) return;

    // Check for out of stock items
    final outOfStockItems =
        _cartItems.where((item) => item['isOutOfStock'] == true).toList();

    if (outOfStockItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Items Out of Stock'),
          content: const Text(
              'Some items in your cart are currently out of stock. Please remove them before proceeding to checkout.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/checkout-screen');
  }

  void _startShopping() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-screen',
      (route) => false,
    );
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      if (item['isOutOfStock'] == true) return sum;
      return sum + (item['price'] * item['quantity']);
    });
  }

  double get _taxes {
    return _subtotal * 0.08; // 8% tax
  }

  int get _totalItems {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Shopping Cart',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
                foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.1),
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
        return CustomScrollView(
          slivers: [
            // Cart Header
            if (_cartItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'shopping_cart',
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$_totalItems item${_totalItems != 1 ? 's' : ''} in cart',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${_subtotal.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ),

            // Scrollable Content
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 1.h),

                    // Cart Items
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return CartItemWidget(
                          item: item,
                          onRemove: () => _removeCartItem(item['id']),
                          onQuantityChanged: (quantity) =>
                              _updateQuantity(item['id'], quantity),
                          onMoveToWishlist: () => _moveToWishlist(item['id']),
                        );
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Saved for Later
                    SavedForLaterWidget(
                      savedItems: _savedItems,
                      onMoveToCart: _moveToCart,
                      onRemoveFromSaved: _removeFromSaved,
                    ),

                    SizedBox(height: 2.h),

                    // Delivery Time Selector
                    DeliveryTimeSelectorWidget(
                      selectedSlot: _selectedDeliverySlot,
                      onSlotSelected: _onDeliverySlotSelected,
                    ),

                    SizedBox(height: 2.h),

                    // Order Summary
                    OrderSummaryWidget(
                      subtotal: _subtotal,
                      deliveryFee: _deliveryFee,
                      taxes: _taxes,
                      discount: _promoDiscount,
                      promoCode: _appliedPromoCode,
                      onPromoCodeApplied: _onPromoCodeApplied,
                      onPromoCodeRemoved: _onPromoCodeRemoved,
                    ),

                    SizedBox(height: 10.h), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
