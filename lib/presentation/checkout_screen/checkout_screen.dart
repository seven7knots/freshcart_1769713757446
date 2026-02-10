import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../providers/cart_provider.dart';
import '../../services/supabase_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressDetailController = TextEditingController();

  int _currentStep = 0; // 0=Delivery, 1=Payment, 2=Confirm
  bool _isProcessingOrder = false;
  bool _isLoadingUser = true;

  // User info
  String _customerName = '';
  String _addressLabel = 'HOME';

  // Saved addresses
  List<Map<String, dynamic>> _savedAddresses = [];
  int _selectedAddressIndex = -1; // -1 = custom/new

  // Payment
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'wallet'

  // Delivery fee (dynamic — calculated based on distance from warehouse)
  double? _deliveryFee; // null = not yet calculated
  bool _isCalculatingFee = false;
  String? _feeError;

  // Warehouse base location (configure per store or globally)
  // TODO: Fetch from store/delivery_zones table
  static const double _warehouseLat = 33.8547; // Default: Baabda area
  static const double _warehouseLng = 35.5462;
  static const double _baseFee = 1.00; // Base fee (minimum)
  static const double _perKmRate = 0.50; // Fee per km — PLACEHOLDER, replace with your formula

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD USER DATA + SAVED ADDRESSES
  // ============================================================

  Future<void> _loadUserInfo() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) { setState(() => _isLoadingUser = false); return; }

      final userData = await SupabaseService.client
          .from('users')
          .select('full_name, phone, address, saved_addresses')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null && mounted) {
        _customerName = userData['full_name'] as String? ?? '';
        _phoneController.text = userData['phone'] as String? ?? '';

        // Load saved addresses (JSON array in DB)
        final savedRaw = userData['saved_addresses'];
        if (savedRaw != null && savedRaw is List) {
          _savedAddresses = List<Map<String, dynamic>>.from(
              savedRaw.map((a) => Map<String, dynamic>.from(a as Map)));
        }

        // If no saved addresses, use the single address field
        if (_savedAddresses.isEmpty && userData['address'] != null && (userData['address'] as String).isNotEmpty) {
          _savedAddresses = [
            {'label': 'HOME', 'address': userData['address'], 'detail': '', 'is_default': true},
          ];
        }

        // Auto-select default address
        if (_savedAddresses.isNotEmpty) {
          final defaultIdx = _savedAddresses.indexWhere((a) => a['is_default'] == true);
          _selectedAddressIndex = defaultIdx >= 0 ? defaultIdx : 0;
          _applySelectedAddress();
        }
      }
    } catch (e) {
      // saved_addresses column may not exist — just use single address
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          final userData = await SupabaseService.client
              .from('users').select('full_name, phone, address')
              .eq('id', user.id).maybeSingle();
          if (userData != null && mounted) {
            _customerName = userData['full_name'] as String? ?? '';
            _phoneController.text = userData['phone'] as String? ?? '';
            _addressController.text = userData['address'] as String? ?? '';
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoadingUser = false);
      _calculateDeliveryFee(); // Calculate fee with loaded address
    }
  }

  void _applySelectedAddress() {
    if (_selectedAddressIndex >= 0 && _selectedAddressIndex < _savedAddresses.length) {
      final addr = _savedAddresses[_selectedAddressIndex];
      _addressController.text = addr['address'] as String? ?? '';
      _addressDetailController.text = addr['detail'] as String? ?? '';
      _addressLabel = addr['label'] as String? ?? 'HOME';
    }
    _calculateDeliveryFee(); // Recalculate when address changes
  }

  // ============================================================
  // SAVE NEW ADDRESS
  // ============================================================

  Future<void> _saveCurrentAddress() async {
    if (_addressController.text.trim().isEmpty) return;

    final newAddr = {
      'label': _addressLabel,
      'address': _addressController.text.trim(),
      'detail': _addressDetailController.text.trim(),
      'is_default': _savedAddresses.isEmpty,
    };

    // Check if this address already exists
    final exists = _savedAddresses.any((a) =>
        a['address'] == newAddr['address'] && a['label'] == newAddr['label']);
    if (exists) return;

    _savedAddresses.add(newAddr);

    // Try to save to DB
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client.from('users').update({
          'saved_addresses': _savedAddresses,
        }).eq('id', userId);
      }
    } catch (_) {
      // saved_addresses column may not exist, that's ok
    }
  }

  // ============================================================
  // DELIVERY FEE CALCULATION
  // ============================================================

  /// Calculate delivery fee based on distance from warehouse to customer.
  /// Currently uses Haversine formula for straight-line distance.
  /// TODO: Replace with Google Maps Directions API for road distance
  /// TODO: Plug in your custom pricing formula when ready
  Future<void> _calculateDeliveryFee() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() { _deliveryFee = null; _feeError = null; });
      return;
    }

    setState(() { _isCalculatingFee = true; _feeError = null; });

    try {
      // For now: use a default customer location based on address
      // TODO: Replace with Google Maps Geocoding API to get lat/lng from address
      // OR use a map picker widget for exact location
      double customerLat = 33.8886; // Default Baabda
      double customerLng = 35.4955;

      // If we have saved coordinates for this address, use them
      if (_selectedAddressIndex >= 0 && _selectedAddressIndex < _savedAddresses.length) {
        final addr = _savedAddresses[_selectedAddressIndex];
        customerLat = (addr['lat'] as num?)?.toDouble() ?? customerLat;
        customerLng = (addr['lng'] as num?)?.toDouble() ?? customerLng;
      }

      // Calculate distance using Haversine formula (straight-line km)
      // TODO: Replace with Google Maps Directions API for actual road distance
      final distanceKm = _haversineDistance(
        _warehouseLat, _warehouseLng,
        customerLat, customerLng,
      );

      // Calculate fee
      // TODO: Replace this with your custom formula when ready
      // Current formula: baseFee + (distance * perKmRate)
      // Example: $1.00 + (5km * $0.50/km) = $3.50
      final fee = _baseFee + (distanceKm * _perKmRate);

      setState(() {
        _deliveryFee = double.parse(fee.toStringAsFixed(2)); // Round to 2 decimals
        _isCalculatingFee = false;
      });
    } catch (e) {
      setState(() {
        _deliveryFee = _baseFee; // Fallback to base fee
        _isCalculatingFee = false;
        _feeError = 'Could not calculate exact fee, using base rate';
      });
    }
  }

  /// Haversine formula — straight-line distance in km between two coordinates.
  /// Placeholder until Google Maps Directions API gives actual road distance.
  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);

  // ============================================================
  // PRICING
  // ============================================================

  double _calcSubtotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final product = item['products'] as Map<String, dynamic>?;
      if (product == null) return sum;
      final price = (product['sale_price'] as num?)?.toDouble() ??
          (product['price'] as num?)?.toDouble() ?? 0.0;
      final qty = item['quantity'] as int? ?? 1;
      return sum + (price * qty);
    });
  }

  /// Tax only applies for online payments (wallet/Whish Money), not for cash
  double _calcTax(double subtotal) {
    if (_selectedPaymentMethod == 'wallet') {
      return subtotal * 0.11; // 11% VAT
    }
    return 0.0; // No tax for cash on delivery
  }

  double _calcTotal(double subtotal) {
    return subtotal + (_deliveryFee ?? 0.0) + _calcTax(subtotal);
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> _placeOrder(List<Map<String, dynamic>> cartItems) async {
    if (cartItems.isEmpty) return;
    if (_deliveryFee == null || _isCalculatingFee) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery fee is still being calculated, please wait'), backgroundColor: Colors.orange));
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a delivery address'), backgroundColor: Colors.red));
      setState(() => _currentStep = 0);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number'), backgroundColor: Colors.red));
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final subtotal = _calcSubtotal(cartItems);
      final tax = _calcTax(subtotal);
      final total = _calcTotal(subtotal);

      // Get store_id from first cart item
      final firstProduct = cartItems.first['products'] as Map<String, dynamic>?;
      final storeId = cartItems.first['store_id'] as String? ??
          firstProduct?['store_id'] as String? ?? '';

      // Full delivery address
      final fullAddress = _addressDetailController.text.trim().isNotEmpty
          ? '${_addressController.text.trim()}, ${_addressDetailController.text.trim()}'
          : _addressController.text.trim();

      // Save address if new
      await _saveCurrentAddress();

      // Create order
      final orderResponse = await SupabaseService.client.from('orders').insert({
        'customer_id': userId,
        'store_id': storeId,
        'status': 'pending',
        'subtotal': subtotal,
        'delivery_fee': _deliveryFee ?? 0.0,
        'service_fee': 0.0,
        'tax': tax,
        'discount': 0.0,
        'tip': 0.0,
        'total': total,
        'currency': 'USD',
        'payment_method': _selectedPaymentMethod, // 'cash' or 'wallet'
        'payment_status': 'pending',
        'delivery_address': fullAddress,
        'delivery_lat': 33.8886, // TODO: get from map picker
        'delivery_lng': 35.4955,
        'delivery_instructions': _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim() : null,
        'customer_phone': _phoneController.text.trim(),
      }).select().single();

      final orderId = orderResponse['id'] as String;

      // Create order items
      final orderItems = cartItems.map((cartItem) {
        final product = cartItem['products'] as Map<String, dynamic>? ?? {};
        final price = (product['sale_price'] as num?)?.toDouble() ??
            (product['price'] as num?)?.toDouble() ?? 0.0;
        final qty = cartItem['quantity'] as int? ?? 1;
        return {
          'order_id': orderId,
          'product_id': cartItem['product_id'],
          'product_name': product['name'] ?? 'Unknown',
          'product_name_ar': product['name_ar'],
          'product_image': product['image_url'],
          'quantity': qty,
          'unit_price': price,
          'total_price': price * qty,
          'currency': 'USD',
          'options_selected': cartItem['options_selected'] ?? [],
          'special_instructions': cartItem['special_instructions'],
        };
      }).toList();

      await SupabaseService.client.from('order_items').insert(orderItems);

      // Clear cart
      await ref.read(cartNotifierProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.orderTracking,
            arguments: {'orderId': orderId});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Checkout', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : cartState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading cart: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shopping_cart_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
                    SizedBox(height: 2.h),
                    Text('Your cart is empty', style: theme.textTheme.titleLarge),
                    SizedBox(height: 2.h),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                  ]));
                }
                return Column(children: [
                  _buildProgressBar(theme),
                  Expanded(child: _buildStepContent(theme, items)),
                  _buildBottomButton(theme, items),
                ]);
              },
            ),
    );
  }

  // ============================================================
  // PROGRESS BAR
  // ============================================================

  Widget _buildProgressBar(ThemeData theme) {
    final steps = ['Delivery', 'Payment', 'Confirm'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isComplete = i < _currentStep;
        return Expanded(child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(child: isComplete
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
                : Text('${i + 1}', style: TextStyle(color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600, fontSize: 12))),
          ),
          if (i < steps.length - 1)
            Expanded(child: Container(height: 2,
                color: isComplete ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3))),
        ]));
      })),
    );
  }

  Widget _buildStepContent(ThemeData theme, List<Map<String, dynamic>> items) {
    switch (_currentStep) {
      case 0: return _buildDeliveryStep(theme, items);
      case 1: return _buildPaymentStep(theme, items);
      case 2: return _buildConfirmStep(theme, items);
      default: return const SizedBox.shrink();
    }
  }

  // ============================================================
  // STEP 1: DELIVERY
  // ============================================================

  Widget _buildDeliveryStep(ThemeData theme, List<Map<String, dynamic>> items) {
    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildMiniOrderSummary(theme, items),
        SizedBox(height: 3.h),

        // Saved addresses (if any)
        if (_savedAddresses.isNotEmpty) ...[
          Text('Saved Addresses', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 1.5.h),
          ...List.generate(_savedAddresses.length, (i) {
            final addr = _savedAddresses[i];
            final isSelected = _selectedAddressIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() { _selectedAddressIndex = i; _applySelectedAddress(); });
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 2 : 1),
                ),
                child: Row(children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 20),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
                    decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text((addr['label'] as String? ?? 'HOME').toUpperCase(),
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: theme.colorScheme.error)),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(child: Text(addr['address'] as String? ?? '',
                      style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            );
          }),
          // New address option
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedAddressIndex = -1;
                _addressController.clear();
                _addressDetailController.clear();
                _addressLabel = 'HOME';
              });
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _selectedAddressIndex == -1 ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _selectedAddressIndex == -1 ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(_selectedAddressIndex == -1 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _selectedAddressIndex == -1 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 20),
                SizedBox(width: 2.w),
                Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: 1.w),
                Text('Use a new address', style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SizedBox(height: 2.h),
        ],

        // Address form (always visible if no saved addresses, or if "new address" selected)
        if (_savedAddresses.isEmpty || _selectedAddressIndex == -1) ...[
          Text('Delivery Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 1.5.h),
          // Address label chips
          Row(children: ['HOME', 'WORK', 'OTHER'].map((label) {
            final isSelected = _addressLabel == label;
            return Padding(padding: EdgeInsets.only(right: 2.w), child: ChoiceChip(
              label: Text(label, style: TextStyle(fontSize: 11.sp)),
              selected: isSelected,
              onSelected: (_) => setState(() => _addressLabel = label),
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            ));
          }).toList()),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Street Address *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _addressDetailController,
            decoration: const InputDecoration(labelText: 'Building, Floor, Apartment (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.apartment)),
          ),
          SizedBox(height: 2.h),
        ],

        // Phone number (always shown)
        Text('Phone Number', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 1.h),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone), hintText: '+961 XX XXX XXX'),
        ),
        SizedBox(height: 3.h),

        // Special instructions
        Text('Special Instructions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 1.h),
        TextField(
          controller: _instructionsController,
          maxLines: 3, maxLength: 200,
          decoration: const InputDecoration(hintText: 'e.g. Ring the doorbell, leave at the door...', border: OutlineInputBorder()),
        ),
        SizedBox(height: 4.h),
      ],
    ));
  }

  // ============================================================
  // STEP 2: PAYMENT
  // ============================================================

  Widget _buildPaymentStep(ThemeData theme, List<Map<String, dynamic>> items) {
    final subtotal = _calcSubtotal(items);

    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildMiniOrderSummary(theme, items),
        SizedBox(height: 3.h),

        Text('Payment Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),

        // Cash on Delivery
        _buildPaymentOption(theme: theme, id: 'cash', icon: Icons.money,
          title: 'Cash on Delivery', subtitle: 'Pay the driver when your order arrives • No tax',
          iconColor: Colors.green),
        SizedBox(height: 1.5.h),

        // Whish Money
        _buildPaymentOption(theme: theme, id: 'wallet', icon: Icons.account_balance_wallet,
          title: 'Whish Money', subtitle: 'Pay via Whish Money mobile wallet • 11% VAT applies',
          iconColor: Colors.blue),

        SizedBox(height: 3.h),

        // Tax info note
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: _selectedPaymentMethod == 'cash'
                ? Colors.green.withOpacity(0.05)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _selectedPaymentMethod == 'cash'
                ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 20, color: _selectedPaymentMethod == 'cash' ? Colors.green : Colors.blue),
            SizedBox(width: 2.w),
            Expanded(child: Text(
              _selectedPaymentMethod == 'cash'
                  ? 'No tax applied for cash on delivery. Please have the exact amount ready for the driver.'
                  : 'A 11% VAT of \$${_calcTax(subtotal).toStringAsFixed(2)} will be added. You will receive a Whish Money payment request after placing the order.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )),
          ]),
        ),
      ],
    ));
  }

  Widget _buildPaymentOption({
    required ThemeData theme, required String id, required IconData icon,
    required String title, required String subtitle, required Color iconColor,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2), width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(width: 12.w, height: 12.w,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24)),
          SizedBox(width: 3.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 0.3.h),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, size: 24),
        ]),
      ),
    );
  }

  // ============================================================
  // STEP 3: CONFIRM
  // ============================================================

  Widget _buildConfirmStep(ThemeData theme, List<Map<String, dynamic>> items) {
    final subtotal = _calcSubtotal(items);
    final tax = _calcTax(subtotal);
    final total = _calcTotal(subtotal);
    final fullAddress = _addressDetailController.text.trim().isNotEmpty
        ? '${_addressController.text.trim()}, ${_addressDetailController.text.trim()}'
        : _addressController.text.trim();

    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Review', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),

        // Items
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Items (${items.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 1.h),
            ...items.map((item) {
              final product = item['products'] as Map<String, dynamic>? ?? {};
              final name = product['name'] as String? ?? 'Unknown';
              final price = (product['sale_price'] as num?)?.toDouble() ??
                  (product['price'] as num?)?.toDouble() ?? 0.0;
              final qty = item['quantity'] as int? ?? 1;
              return Padding(padding: EdgeInsets.only(bottom: 0.8.h), child: Row(children: [
                Text('${qty}x', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                SizedBox(width: 2.w),
                Expanded(child: Text(name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('\$${(price * qty).toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]));
            }),
          ]),
        ),
        SizedBox(height: 2.h),

        // Delivery info
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.location_on, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text('Delivery Address', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(onTap: () => setState(() => _currentStep = 0),
                child: Text('Edit', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
            ]),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(_addressLabel, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: theme.colorScheme.error)),
            ),
            SizedBox(height: 0.5.h),
            if (_customerName.isNotEmpty) Text(_customerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(fullAddress, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(_phoneController.text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        SizedBox(height: 2.h),

        // Payment info
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.payment, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text('Payment', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(onTap: () => setState(() => _currentStep = 1),
                child: Text('Edit', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
            ]),
            SizedBox(height: 1.h),
            Row(children: [
              Icon(_selectedPaymentMethod == 'cash' ? Icons.money : Icons.account_balance_wallet,
                  size: 20, color: _selectedPaymentMethod == 'cash' ? Colors.green : Colors.blue),
              SizedBox(width: 2.w),
              Text(_selectedPaymentMethod == 'cash' ? 'Cash on Delivery' : 'Whish Money',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (_selectedPaymentMethod == 'cash') ...[
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('No Tax', style: TextStyle(fontSize: 9.sp, color: Colors.green, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ]),
        ),
        SizedBox(height: 2.h),

        // Price breakdown
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
          child: Column(children: [
            _priceRow(theme, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            if (_isCalculatingFee)
              _priceRow(theme, 'Delivery Fee', 'Calculating...')
            else if (_deliveryFee != null)
              _priceRow(theme, 'Delivery Fee', '\$${_deliveryFee!.toStringAsFixed(2)}')
            else
              _priceRow(theme, 'Delivery Fee', 'TBD'),
            if (_feeError != null)
              Padding(padding: EdgeInsets.only(bottom: 0.5.h),
                child: Text(_feeError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontSize: 10.sp))),
            if (tax > 0) _priceRow(theme, 'Tax (11% VAT)', '\$${tax.toStringAsFixed(2)}'),
            if (tax == 0) _priceRow(theme, 'Tax', 'Free (Cash)', isFree: true),
            Divider(height: 3.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('\$${total.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            ]),
          ]),
        ),
        SizedBox(height: 4.h),
      ],
    ));
  }

  Widget _priceRow(ThemeData theme, String label, String value, {bool isFree = false}) {
    return Padding(padding: EdgeInsets.only(bottom: 1.h), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600, color: isFree ? Colors.green : null)),
      ],
    ));
  }

  // ============================================================
  // MINI ORDER SUMMARY
  // ============================================================

  Widget _buildMiniOrderSummary(ThemeData theme, List<Map<String, dynamic>> items) {
    final subtotal = _calcSubtotal(items);
    final total = _calcTotal(subtotal);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15))),
      child: Row(children: [
        Icon(Icons.shopping_bag, size: 20, color: theme.colorScheme.primary),
        SizedBox(width: 2.w),
        Text('${items.length} item${items.length != 1 ? 's' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('Total: \$${total.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
      ]),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton(ThemeData theme, List<Map<String, dynamic>> items) {
    final subtotal = _calcSubtotal(items);
    final total = _calcTotal(subtotal);

    String buttonText;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = 'Continue to Payment';
        onPressed = () {
          if (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in address and phone number'), backgroundColor: Colors.red));
            return;
          }
          HapticFeedback.lightImpact();
          _calculateDeliveryFee(); // Recalculate with current address
          setState(() => _currentStep = 1);
        };
        break;
      case 1:
        buttonText = 'Review Order';
        onPressed = () { HapticFeedback.lightImpact(); setState(() => _currentStep = 2); };
        break;
      case 2:
        buttonText = 'Place Order • \$${total.toStringAsFixed(2)}';
        onPressed = _isProcessingOrder ? null : () => _placeOrder(items);
        break;
      default:
        buttonText = 'Continue';
        onPressed = () {};
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(child: Row(children: [
        if (_currentStep > 0)
          Padding(padding: EdgeInsets.only(right: 2.w), child: IconButton(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
          )),
        Expanded(child: SizedBox(height: 6.h, child: ElevatedButton(
          onPressed: onPressed,
          child: _isProcessingOrder
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
              : Text(buttonText, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
        ))),
      ])),
    );
  }
}