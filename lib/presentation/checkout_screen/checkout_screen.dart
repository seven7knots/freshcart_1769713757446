import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/main_layout_wrapper.dart';
import './widgets/checkout_progress_widget.dart';
import './widgets/delivery_address_widget.dart';
import './widgets/delivery_time_widget.dart';
import './widgets/order_summary_widget.dart';
import './widgets/special_instructions_widget.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _instructionsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final int _currentStep = 0;
  bool _isOrderSummaryExpanded = false;
  int _selectedTimeSlotIndex = 0;
  bool _isProcessingOrder = false;
  String? _orderError;

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoadingCart = true;

  @override
  void initState() {
    super.initState();
    // Track begin checkout
    _trackBeginCheckout();
    AnalyticsService.logScreenView(screenName: 'checkout_screen');
  }

  Future<void> _trackBeginCheckout() async {
    // Wait for cart to load then track
    Future.delayed(const Duration(milliseconds: 500), () {
      final cart = ref.read(cartNotifierProvider);
      cart.whenData((cartData) {
        if (cartData.isNotEmpty) {
          final subtotal = cartData.fold(0.0, (sum, item) {
            final product = item['products'] as Map<String, dynamic>;
            final price = (product['sale_price'] ?? product['price']) ?? 0.0;
            final quantity = item['quantity'] ?? 1;
            return sum + (price * quantity);
          });
          AnalyticsService.logBeginCheckout(
            cartTotal: subtotal,
            itemCount: cartData.length,
            items: cartData.map((item) {
              final product = item['products'] as Map<String, dynamic>;
              return {
                'id': item['product_id'],
                'name': product['name'] ?? 'Unknown Product',
                'price': (product['sale_price'] ?? product['price']) ?? 0.0,
                'quantity': item['quantity'] ?? 1,
              };
            }).toList(),
          );
        }
      });
    });
  }

  final Map<String, dynamic> _selectedAddress = {
    "type": "HOME",
    "name": "John Doe",
    "address": "1234 Oak Street, Apartment 5B, San Francisco, CA 94102",
    "landmark": "Blue Coffee Shop",
    "phone": "+1 (555) 123-4567",
  };

  final List<Map<String, dynamic>> _timeSlots = [
    {
      "label": "Standard",
      "time": "Today, 2-4 PM",
      "type": "standard",
      "fee": 0.0,
    },
    {
      "label": "Express",
      "time": "Today, 1-2 PM",
      "type": "express",
      "fee": 4.99,
    },
    {
      "label": "Standard",
      "time": "Tomorrow, 9-11 AM",
      "type": "standard",
      "fee": 0.0,
    },
    {
      "label": "Standard",
      "time": "Tomorrow, 2-4 PM",
      "type": "standard",
      "fee": 0.0,
    },
  ];

  final List<String> _checkoutSteps = [
    "Review",
    "Address",
    "Payment",
    "Confirm",
  ];

  @override
  void dispose() {
    _instructionsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _cartItems.fold(
      0.0,
      (sum, item) =>
          sum + ((item['price'] as double) * (item['quantity'] as int)),
    );
  }

  double get _deliveryFee {
    return _timeSlots[_selectedTimeSlotIndex]['fee'] as double;
  }

  double get _discount => 5.50;

  double get _total => _subtotal + _deliveryFee - _discount;

  @override
  Widget build(BuildContext context) {
    // Load cart items from provider
    final cartAsync = ref.watch(cartNotifierProvider);

    cartAsync.whenData((cartData) {
      if (_isLoadingCart) {
        setState(() {
          _cartItems = cartData.map((item) {
            final product = item['products'] as Map<String, dynamic>;
            return {
              'id': item['id'],
              'product_id': item['product_id'],
              'name': product['name'] ?? 'Unknown Product',
              'price': (product['sale_price'] ?? product['price']) ?? 0.0,
              'quantity': item['quantity'] ?? 1,
              'image': product['image_url'] ??
                  (product['images'] != null &&
                          (product['images'] as List).isNotEmpty
                      ? product['images'][0]
                      : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'),
              'semanticLabel': '${product['name']} product image',
            };
          }).toList();
          _isLoadingCart = false;
        });
      }
    });

    // Get the current tab index from MainLayoutWrapper
    final parentState = MainLayoutWrapper.of(context);
    final currentTabIndex =
        parentState?.currentIndex ?? 2; // Default to Cart tab

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        'Checkout',
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      pinned: true,
                      floating: false,
                      snap: false,
                      elevation: 0,
                      backgroundColor:
                          AppTheme.lightTheme.scaffoldBackgroundColor,
                      foregroundColor:
                          AppTheme.lightTheme.colorScheme.onSurface,
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
          ),
          _buildPlaceOrderButton(),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          // Update parent tab index and pop detail screen
          parentState?.updateTabIndex(index);
          if (index != currentTabIndex) {
            Navigator.pop(context);
          }
        },
        variant: BottomBarVariant.primary,
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home-screen';
      case 1:
        return '/search-screen';
      case 2:
        return '/shopping-cart-screen';
      case 3:
        return '/order-history-screen';
      case 4:
        return '/profile-screen';
      default:
        return '/home-screen';
    }
  }

  Widget _buildMainContent() {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Checkout Progress Widget
                  CheckoutProgressWidget(
                    currentStep: _currentStep,
                    steps: const ['Delivery', 'Payment', 'Confirm'],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          SizedBox(height: 1.h),

                          // Order Summary
                          OrderSummaryWidget(
                            cartItems: _cartItems,
                            subtotal: _subtotal,
                            deliveryFee: _deliveryFee,
                            discount: _discount,
                            total: _total,
                            onEditCart: _handleEditCart,
                            isExpanded: _isOrderSummaryExpanded,
                            onToggleExpansion: () {
                              setState(() {
                                _isOrderSummaryExpanded =
                                    !_isOrderSummaryExpanded;
                              });
                            },
                          ),

                          // Delivery Address
                          DeliveryAddressWidget(
                            selectedAddress: _selectedAddress,
                            onChangeAddress: _handleChangeAddress,
                          ),

                          // Delivery Time
                          DeliveryTimeWidget(
                            timeSlots: _timeSlots,
                            selectedSlotIndex: _selectedTimeSlotIndex,
                            onSlotSelected: (index) {
                              setState(() {
                                _selectedTimeSlotIndex = index;
                              });
                              HapticFeedback.lightImpact();
                            },
                          ),

                          // Special Instructions
                          SpecialInstructionsWidget(
                            controller: _instructionsController,
                            maxLength: 200,
                          ),

                          SizedBox(height: 2.h),

                          // Security Indicators
                          _buildSecurityIndicators(context),

                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityIndicators(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'security',
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Secured by 256-bit SSL encryption',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditCart() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/shopping-cart-screen');
  }

  void _handleChangeAddress() {
    HapticFeedback.lightImpact();
    _showAddressModal();
  }

  Future<void> _placeOrder() async {
    if (_isProcessingOrder) return;

    setState(() {
      _isProcessingOrder = true;
      _orderError = null;
    });

    try {
      final orderService = OrderService();

      // Prepare items for server validation
      final items = _cartItems.map((item) {
        return {'product_id': item['product_id'], 'quantity': item['quantity']};
      }).toList();

      // Call server-authoritative RPC (server calculates totals)
      final order = await orderService.createOrder(
        storeId: _cartItems.first['store_id'] ?? '',
        deliveryAddress: _selectedAddress['address'] as String,
        deliveryLat: 33.8886, // TODO: Get from address selection
        deliveryLng: 35.4955,
        items: items,
        deliveryInstructions: _instructionsController.text.isNotEmpty
            ? _instructionsController.text
            : null,
        customerPhone: _selectedAddress['phone'] as String?,
      );

      if (mounted) {
        // Clear cart
        await ref.read(cartNotifierProvider.notifier).clearCart();

        // Navigate to order tracking
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.orderTracking,
          arguments: {'orderId': order.id},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _orderError = e.toString().replaceAll('Exception: ', '');
        _isProcessingOrder = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_orderError ?? 'Failed to place order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Select Delivery Address',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Center(
                child: Text(
                  'Address selection modal content',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
          ),
          child: _isProcessingOrder
              ? SizedBox(
                  height: 2.h,
                  width: 2.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
