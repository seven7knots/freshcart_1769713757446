import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/main_layout_wrapper.dart';
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

  // NOTE: You had _isLoading=true and never updated; that locks the screen.
  // This file now treats loading as "provider-driven", while keeping your mock lists.
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  bool get _shouldShowBack =>
      Navigator.of(context).canPop() && MainLayoutWrapper.of(context) == null;

  void _goToTab(int index) {
    final wrapper = MainLayoutWrapper.of(context);
    if (wrapper != null) {
      wrapper.updateTabIndex(index);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.getRouteForIndex(index));
  }

  void _removeCartItem(int itemId) async {
    try {
      await ref
          .read(cartNotifierProvider.notifier)
          .removeItem(itemId.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed from cart'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: $e')),
      );
    }
  }

  void _updateQuantity(int itemId, int newQuantity) async {
    try {
      await ref
          .read(cartNotifierProvider.notifier)
          .updateQuantity(itemId.toString(), newQuantity);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e')),
      );
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
          'Are you sure you want to remove all items from your cart?',
        ),
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
                setState(() => _cartItems.clear());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear cart: $e')),
                );
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

    final outOfStockItems =
        _cartItems.where((item) => item['isOutOfStock'] == true).toList();

    if (outOfStockItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Items Out of Stock'),
          content: const Text(
            'Some items in your cart are currently out of stock. Please remove them before proceeding to checkout.',
          ),
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
    Navigator.pushNamed(context, AppRoutes.checkout);
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      if (item['isOutOfStock'] == true) return sum;
      return sum + (item['price'] * item['quantity']);
    });
  }

  double get _taxes => _subtotal * 0.08;

  int get _totalItems =>
      _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Read provider to keep state “alive” (even if you still use mock lists here).
    ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                leading: _shouldShowBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: Text(
                  'Shopping Cart',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                pinned: true,
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: cs.onSurface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 2,
                shadowColor: cs.shadow.withValues(alpha: 0.1),
                actions: [
                  if (_cartItems.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear cart',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _clearCart,
                    ),
                ],
              ),
            ),
          ];
        },
        body: _buildMainContent(),
      ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : SafeArea(
              minimum: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  child: Text(
                    'Checkout • \$${(_subtotal + _deliveryFee + _taxes - _promoDiscount).toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 2.h),
                Text('Loading cart...',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        if (_cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(height: 2.h),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Browse items and add them to your cart.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToTab(0),
                      child: const Text('Start Shopping'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
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
                      Icon(Icons.shopping_cart,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
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
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 1.h),
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
                  SavedForLaterWidget(
                    savedItems: _savedItems,
                    onMoveToCart: _moveToCart,
                    onRemoveFromSaved: _removeFromSaved,
                  ),
                  SizedBox(height: 2.h),
                  DeliveryTimeSelectorWidget(
                    selectedSlot: _selectedDeliverySlot,
                    onSlotSelected: _onDeliverySlotSelected,
                  ),
                  SizedBox(height: 2.h),
                  OrderSummaryWidget(
                    subtotal: _subtotal,
                    deliveryFee: _deliveryFee,
                    taxes: _taxes,
                    discount: _promoDiscount,
                    promoCode: _appliedPromoCode,
                    onPromoCodeApplied: _onPromoCodeApplied,
                    onPromoCodeRemoved: _onPromoCodeRemoved,
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
