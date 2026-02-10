import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/main_layout_wrapper.dart';

class ShoppingCartScreen extends ConsumerStatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ConsumerState<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends ConsumerState<ShoppingCartScreen> {
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;

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

  // ============================================================
  // CART HELPERS
  // ============================================================

  String _productName(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    return product?['name'] as String? ?? 'Unknown Product';
  }

  String? _productImage(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    return product?['image_url'] as String?;
  }

  double _productPrice(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    if (product == null) return 0.0;
    final salePrice = product['sale_price'];
    final price = product['price'];
    if (salePrice != null) return (salePrice as num).toDouble();
    if (price != null) return (price as num).toDouble();
    return 0.0;
  }

  double? _originalPrice(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    if (product == null) return null;
    final salePrice = product['sale_price'];
    final price = product['price'];
    if (salePrice != null && price != null) {
      final p = (price as num).toDouble();
      final s = (salePrice as num).toDouble();
      if (s < p) return p;
    }
    return null;
  }

  String? _storeName(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    final stores = product?['stores'] as Map<String, dynamic>?;
    return stores?['name'] as String?;
  }

  int _quantity(Map<String, dynamic> item) => item['quantity'] as int? ?? 1;
  String _cartItemId(Map<String, dynamic> item) => item['id'].toString();

  bool _isAvailable(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>?;
    return product?['is_available'] as bool? ?? true;
  }

  // ============================================================
  // CART ACTIONS
  // ============================================================

  void _removeCartItem(String cartItemId) async {
    try {
      await ref.read(cartNotifierProvider.notifier).removeItem(cartItemId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updateQuantity(String cartItemId, int newQuantity) async {
    try {
      await ref.read(cartNotifierProvider.notifier).updateQuantity(cartItemId, newQuantity);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(cartNotifierProvider.notifier).clearCart();
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

  void _onPromoCodeApplied(String promoCode, double subtotal) {
    setState(() {
      _appliedPromoCode = promoCode;
      switch (promoCode.toUpperCase()) {
        case 'SAVE10': _promoDiscount = subtotal * 0.10; break;
        case 'WELCOME20': _promoDiscount = subtotal * 0.20; break;
        case 'FIRST15': _promoDiscount = subtotal * 0.15; break;
        case 'FRESH25': _promoDiscount = subtotal * 0.25; break;
        default: _promoDiscount = 0.0;
      }
    });
  }

  void _onPromoCodeRemoved() {
    setState(() { _appliedPromoCode = null; _promoDiscount = 0.0; });
  }

  void _proceedToCheckout(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    final unavailable = items.where((item) => !_isAvailable(item)).toList();
    if (unavailable.isNotEmpty) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Items Unavailable'),
        content: const Text('Some items in your cart are currently unavailable. Please remove them first.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, AppRoutes.checkout);
  }

  double _calcSubtotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      if (!_isAvailable(item)) return sum;
      return sum + (_productPrice(item) * _quantity(item));
    });
  }

  int _calcTotalItems(List<Map<String, dynamic>> items) =>
      items.fold(0, (sum, item) => sum + _quantity(item));

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _shouldShowBack
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
            : null,
        title: Text('Shopping Cart', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          cartState.maybeWhen(
            data: (items) => items.isNotEmpty
                ? IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Clear cart', onPressed: _clearCart)
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          SizedBox(height: 2.h),
          Text('Failed to load cart', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Text(e.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          SizedBox(height: 2.h),
          ElevatedButton(onPressed: () => ref.read(cartNotifierProvider.notifier).loadCart(), child: const Text('Retry')),
        ])),
        data: (items) => _buildCartContent(theme, items),
      ),
      bottomNavigationBar: cartState.maybeWhen(
        data: (items) {
          if (items.isEmpty) return null;
          final subtotal = _calcSubtotal(items);
          final total = subtotal - _promoDiscount;
          return SafeArea(
            minimum: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: SizedBox(width: double.infinity, height: 6.h, child: ElevatedButton(
              onPressed: () => _proceedToCheckout(items),
              child: Text('Checkout • \$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
            )),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildCartContent(ThemeData theme, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(child: Padding(padding: EdgeInsets.all(8.w), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: 2.h),
          Text('Your cart is empty', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 1.h),
          Text('Browse items and add them to your cart.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          SizedBox(height: 3.h),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goToTab(0), child: const Text('Start Shopping'))),
        ],
      )));
    }

    final subtotal = _calcSubtotal(items);
    final totalItems = _calcTotalItems(items);
    final total = subtotal - _promoDiscount;

    return RefreshIndicator(
      onRefresh: () async => ref.read(cartNotifierProvider.notifier).loadCart(),
      child: ListView(children: [
        // Summary bar
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)))),
          child: Row(children: [
            Icon(Icons.shopping_cart, size: 20, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text('$totalItems item${totalItems != 1 ? 's' : ''} in cart',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('\$${subtotal.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
          ]),
        ),

        // Cart items
        ...items.map((item) => _buildCartItem(theme, item)),

        SizedBox(height: 2.h),

        // Order summary
        _buildOrderSummary(theme, subtotal, total),

        SizedBox(height: 12.h),
      ]),
    );
  }

  Widget _buildCartItem(ThemeData theme, Map<String, dynamic> item) {
    final id = _cartItemId(item);
    final name = _productName(item);
    final image = _productImage(item);
    final price = _productPrice(item);
    final origPrice = _originalPrice(item);
    final store = _storeName(item);
    final qty = _quantity(item);
    final available = _isAvailable(item);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: available ? theme.colorScheme.surface : theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: available ? theme.colorScheme.outline.withOpacity(0.15) : theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 20.w, height: 20.w, child: image != null && image.isNotEmpty
              ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder(theme))
              : _imagePlaceholder(theme)),
        ),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (store != null) ...[
            SizedBox(height: 0.3.h),
            Text(store, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          SizedBox(height: 0.5.h),
          Row(children: [
            if (origPrice != null) ...[
              Text('\$${origPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant)),
              SizedBox(width: 1.w),
            ],
            Text('\$${price.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700,
                    color: origPrice != null ? Colors.red : theme.colorScheme.primary)),
          ]),
          if (!available) ...[
            SizedBox(height: 0.5.h),
            Text('Unavailable', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
          ],
          SizedBox(height: 1.h),
          Row(children: [
            _qtyButton(theme, Icons.remove, qty > 1 ? () => _updateQuantity(id, qty - 1) : null),
            Padding(padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text('$qty', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            _qtyButton(theme, Icons.add, () => _updateQuantity(id, qty + 1)),
            const Spacer(),
            Text('\$${(price * qty).toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            SizedBox(width: 2.w),
            IconButton(icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                onPressed: () => _removeCartItem(id), tooltip: 'Remove'),
          ]),
        ])),
      ]),
    );
  }

  Widget _qtyButton(ThemeData theme, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap != null ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(color: theme.colorScheme.surfaceContainerHighest,
        child: Center(child: Icon(Icons.shopping_bag, color: theme.colorScheme.onSurfaceVariant)));
  }

  Widget _buildOrderSummary(ThemeData theme, double subtotal, double total) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),
        _summaryRow(theme, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
        if (_promoDiscount > 0)
          _summaryRow(theme, 'Discount ($_appliedPromoCode)', '-\$${_promoDiscount.toStringAsFixed(2)}', isDiscount: true),
        Divider(height: 3.h),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text('\$${total.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
        ]),
        SizedBox(height: 1.h),
        Text('Taxes and delivery fee calculated at checkout',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: 2.h),
        // Promo code input
        if (_appliedPromoCode == null)
          TextField(
            decoration: InputDecoration(
              hintText: 'Promo code',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: () {}),
            ),
            onSubmitted: (code) {
              if (code.trim().isNotEmpty) _onPromoCodeApplied(code.trim(), subtotal);
            },
          )
        else
          Row(children: [
            const Icon(Icons.discount, color: Colors.green, size: 18),
            SizedBox(width: 1.w),
            Text('$_appliedPromoCode applied', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: _onPromoCodeRemoved, child: const Text('Remove', style: TextStyle(color: Colors.red))),
          ]),
      ]),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value, {bool isDiscount = false}) {
    return Padding(padding: EdgeInsets.only(bottom: 1.h), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600, color: isDiscount ? Colors.green : null)),
      ],
    ));
  }
}