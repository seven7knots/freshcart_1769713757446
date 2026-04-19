import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_address_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/supabase_service.dart';
import '../map_location_picker/map_location_picker_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _instructionsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();

  // SESSION 39: Delivery preferences from user_delivery_preferences table
  Map<String, dynamic>? _deliveryPrefs;

  int _currentStep = 0;
  bool _isProcessingOrder = false;
  bool _isLoadingUser = true;
  String _customerName = '';
  String _addressLabel = 'HOME';
  List<Map<String, dynamic>> _savedAddresses = [];
  int _selectedAddressIndex = -1;

  double? _deliveryFee;
  bool _isCalculatingFee = false;
  String? _feeError;
  double? _lastDistanceKm;
  double? _deliveryLat;
  double? _deliveryLng;

  static const double _warehouseLat = 33.80743;
  static const double _warehouseLng = 35.59797;
  static const double _maxDistKm = 100.0;
  static const double _baseFee = 2.50;
  static const double _roadFactor = 1.35;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) { setState(() => _isLoadingUser = false); return; }
      final ud = await SupabaseService.client.from('users')
          .select('full_name, phone, address, saved_addresses')
          .eq('id', user.id).maybeSingle();
      if (ud != null && mounted) {
        _customerName = ud['full_name'] as String? ?? '';
        _phoneCtrl.text = ud['phone'] as String? ?? '';
        final raw = ud['saved_addresses'];
        if (raw != null && raw is List) {
          _savedAddresses = List<Map<String, dynamic>>.from(
              raw.map((a) => Map<String, dynamic>.from(a as Map)));
        }
        if (_savedAddresses.isNotEmpty) {
          _selectedAddressIndex = 0;
          _applyAddress();
        } else {
          _addressCtrl.text = ud['address'] as String? ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return;
        final ud = await SupabaseService.client.from('users')
            .select('full_name, phone, address').eq('id', user.id).maybeSingle();
        if (ud != null && mounted) {
          _customerName = ud['full_name'] as String? ?? '';
          _phoneCtrl.text = ud['phone'] as String? ?? '';
          _addressCtrl.text = ud['address'] as String? ?? '';
        }
      } catch (e) { debugPrint('[CHECKOUT_SCREEN] Silent error: $e'); }
    } finally {
      if (mounted) { setState(() => _isLoadingUser = false); _calcFee(); _loadDeliveryPreferences(); }
    }
  }

  // SESSION 39: Load saved delivery preferences
  Future<void> _loadDeliveryPreferences() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;
      final result = await SupabaseService.client
          .from('user_delivery_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (result != null && mounted) {
        setState(() => _deliveryPrefs = result);
        // Auto-populate instructions if empty
        if (_instructionsCtrl.text.trim().isEmpty) {
          final parts = <String>[];
          if (result['leave_at_door'] == true) parts.add('Leave at door');
          if (result['ring_doorbell'] == true) parts.add('Ring doorbell');
          if (result['call_on_arrival'] == true) parts.add('Call on arrival');
          if (result['contactless_delivery'] == true) parts.add('Contactless delivery');
          final timeSlot = result['preferred_time_slot'] as String?;
          if (timeSlot != null && timeSlot != 'anytime') {
            parts.add('Preferred time: $timeSlot');
          }
          final savedInstructions = result['delivery_instructions'] as String? ?? '';
          if (savedInstructions.isNotEmpty) parts.add(savedInstructions);
          final handling = result['special_handling'] as String? ?? '';
          if (handling.isNotEmpty) parts.add('Handling: $handling');
          if (parts.isNotEmpty) {
            _instructionsCtrl.text = parts.join('. ');
          }
        }
      }
    } catch (e) {
      debugPrint('[CHECKOUT] Error loading delivery prefs: \$e');
    }
  }

  void _applyAddress() {
    if (_selectedAddressIndex >= 0 && _selectedAddressIndex < _savedAddresses.length) {
      final a = _savedAddresses[_selectedAddressIndex];
      _addressCtrl.text = a['address'] as String? ?? '';
      _addressDetailCtrl.text = a['detail'] as String? ?? '';
      _addressLabel = a['label'] as String? ?? 'HOME';
      _deliveryLat = (a['lat'] as num?)?.toDouble();
      _deliveryLng = (a['lng'] as num?)?.toDouble();
    }
    _calcFee();
  }

  Future<void> _saveAddress() async {
    if (_addressCtrl.text.trim().isEmpty) return;
    final na = {
      'address': _addressCtrl.text.trim(),
      'detail': _addressDetailCtrl.text.trim(),
      'label': _addressLabel,
      'lat': _deliveryLat,
      'lng': _deliveryLng,
    };
    if (_savedAddresses.any((a) => a['address'] == na['address'])) return;
    _savedAddresses.add(na);
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;
      final updates = <String, dynamic>{'saved_addresses': _savedAddresses};
      // Persist phone to user profile on first checkout
      final phone = _phoneCtrl.text.trim();
      if (phone.isNotEmpty) {
        updates['phone'] = phone;
      }
      await SupabaseService.client.from('users')
          .update(updates).eq('id', user.id);
    } catch (e) { debugPrint('Save address error: $e'); }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalMapPickerScreen(
          mode: MapPickerMode.delivery,
          initialLat: _deliveryLat,
          initialLng: _deliveryLng,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _addressCtrl.text = result.address;
        _deliveryLat = result.lat;
        _deliveryLng = result.lng;
        _selectedAddressIndex = -1;
      });
      _calcFee();
    }
  }

  static double _computeFee(double km) {
    if (km <= 0) return _baseFee;
    if (km <= 3.0) return _baseFee;

    double fee = _baseFee;

    if (km > 3.0) {
      final tier1Km = (km > 15.0 ? 15.0 : km) - 3.0;
      fee += tier1Km * 0.60;
    }
    if (km > 15.0) {
      final tier2Km = (km > 25.0 ? 25.0 : km) - 15.0;
      fee += tier2Km * 0.50;
    }
    if (km > 25.0) {
      final tier3Km = (km > 100.0 ? 100.0 : km) - 25.0;
      fee += tier3Km * 0.30;
    }

    return fee;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _degToRad(double deg) => deg * pi / 180.0;

  Future<void> _calcFee() async {
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() { _deliveryFee = null; _feeError = null; _lastDistanceKm = null; });
      return;
    }
    setState(() { _isCalculatingFee = true; _feeError = null; });

    try {
      double? cLat = _deliveryLat;
      double? cLng = _deliveryLng;

      if (cLat == null && cLng == null &&
          _selectedAddressIndex >= 0 && _selectedAddressIndex < _savedAddresses.length) {
        final a = _savedAddresses[_selectedAddressIndex];
        cLat = (a['lat'] as num?)?.toDouble();
        cLng = (a['lng'] as num?)?.toDouble();
      }

      if (cLat == null || cLng == null) {
        setState(() {
          _deliveryFee = _baseFee; _isCalculatingFee = false; _lastDistanceKm = null;
          _feeError = AppLocalizations.of(context)!.usingBaseFeeSetExactLocation;
        });
        return;
      }

      final straightLine = _haversine(_warehouseLat, _warehouseLng, cLat, cLng);
      final distKm = straightLine * _roadFactor;

      if (distKm > _maxDistKm) {
        setState(() {
          _deliveryFee = null; _isCalculatingFee = false; _lastDistanceKm = distKm;
          _feeError = 'Location is ${distKm.toStringAsFixed(1)} km away — outside delivery range';
        });
        return;
      }

      final fee = _computeFee(distKm);
      setState(() {
        _deliveryFee = double.parse(fee.toStringAsFixed(2));
        _isCalculatingFee = false; _lastDistanceKm = distKm; _feeError = null;
      });
    } catch (e) {
      debugPrint('Fee calc error: $e');
      setState(() {
        _deliveryFee = _baseFee; _isCalculatingFee = false;
        _lastDistanceKm = null; _feeError = AppLocalizations.of(context)!.couldNotCalculateExactFeeUsing;
      });
    }
  }

  double _subtotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (s, item) {
      final p = item['products'] as Map<String, dynamic>?;
      if (p == null) return s;
      final price = (p['sale_price'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0.0;
      return s + price * (item['quantity'] as int? ?? 1);
    });
  }

  double _total(double sub) => sub + (_deliveryFee ?? 0.0);

  Future<void> _placeOrder(List<Map<String, dynamic>> items) async {
    if (_isProcessingOrder) return;
    if (items.isEmpty) return;
    if (_deliveryFee == null || _isCalculatingFee) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.deliveryFeeStillCalculatingPleaseWait, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange));
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterADeliveryAddress, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange));
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterAPhoneNumber, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isProcessingOrder = true);
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final sub = _subtotal(items);
      final tot = _total(sub);

      double? dLat = _deliveryLat;
      double? dLng = _deliveryLng;

      final orderItems = items.map((item) {
        final p = item['products'] as Map<String, dynamic>?;
        return {
          'product_id': item['product_id'],
          'quantity': item['quantity'] ?? 1,
          'unit_price': (p?['sale_price'] as num?)?.toDouble() ?? (p?['price'] as num?)?.toDouble() ?? 0.0,
          'product_name': p?['name'] ?? 'Unknown',
        };
      }).toList();

      String? storeId;
      if (items.isNotEmpty) {
        storeId = (items.first['products'] as Map<String, dynamic>?)?['store_id'] as String?;
      }

      await _saveAddress();

      final response = await SupabaseService.client.from('orders').insert({
        'user_id': user.id,
        'store_id': storeId,
        'status': 'pending',
        'subtotal': sub,
        'delivery_fee': _deliveryFee,
        'tax': 0.0,
        'total': tot,
        'payment_method': 'cash',
        'payment_status': 'pending',
        'delivery_address': _addressCtrl.text.trim(),
        'delivery_address_detail': _addressDetailCtrl.text.trim(),
        'delivery_lat': dLat,
        'delivery_lng': dLng,
        'phone': _phoneCtrl.text.trim(),
        'instructions': _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim(),
        'delivery_instructions': _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim(),
        'special_instructions': _deliveryPrefs?['special_handling'],
        'items': orderItems,
        'distance_km': _lastDistanceKm,
      }).select().single();

      final orderId = response['id'] as String;
      if (orderItems.isNotEmpty) {
        final itemRows = orderItems.map((item) => {
          'order_id': orderId,
          'product_id': item['product_id'],
          'product_name': item['product_name'] ?? 'Unknown',
          'quantity': item['quantity'] ?? 1,
          'unit_price': item['unit_price'] ?? 0.0,
          'total_price': ((item['unit_price'] as num?) ?? 0.0) * ((item['quantity'] as num?) ?? 1),
          'currency': 'USD',
        }).toList();
        await SupabaseService.client.from('order_items').insert(itemRows);
      }
      await ref.read(cartNotifierProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.orderPlacedSuccessfully, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.green.shade600));
        Navigator.of(context).pushReplacementNamed(AppRoutes.orderTracking, arguments: response);
      }
    } catch (e) {
      debugPrint('Order error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}', maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessingOrder = false);
    }
  }

  List<Map<String, dynamic>> get _cartItems {
    final cart = ref.watch(cartNotifierProvider);
    return cart.when(data: (i) => i, loading: () => [], error: (_, __) => []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _cartItems;

    if (items.isEmpty && !_isProcessingOrder) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.checkout, maxLines: 1, overflow: TextOverflow.ellipsis)),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: theme.colorScheme.outline),
          SizedBox(height: 2.h),
          Text(AppLocalizations.of(context)!.yourCartIsEmpty, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.continueShopping, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? AppLocalizations.of(context)!.deliveryDetails : AppLocalizations.of(context)!.confirmOrder, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.5.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(children: List.generate(2, (i) => Expanded(child: Container(
              height: 3, margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                color: i <= _currentStep ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
            )))),
          ),
        ),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _currentStep == 0 ? _deliveryStep(theme, items) : _confirmStep(theme, items)),
      bottomNavigationBar: _bottomBar(theme, items),
    );
  }

  Widget _deliveryStep(ThemeData theme, List<Map<String, dynamic>> items) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Saved addresses list ──────────────────────────────
        if (_savedAddresses.isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.savedAddresses, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          ...List.generate(_savedAddresses.length, (i) {
            final addr = _savedAddresses[i];
            final sel = _selectedAddressIndex == i;
            return GestureDetector(
              onTap: () { setState(() => _selectedAddressIndex = i); _applyAddress(); },
              child: Container(
                margin: EdgeInsets.only(bottom: 1.h), padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: sel ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2), width: sel ? 2 : 1)),
                child: Row(children: [
                  Icon((addr['label'] as String? ?? 'HOME') == 'WORK' ? Icons.work_outline : Icons.home_outlined,
                      color: sel ? theme.colorScheme.primary : theme.colorScheme.outline),
                  SizedBox(width: 3.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((addr['label'] as String? ?? 'HOME').toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: sel ? theme.colorScheme.primary : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(addr['address'] as String? ?? '', style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  if (sel) Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ]),
              ),
            );
          }),

          // ── Pick on Map button (replaces "Enter new address") ──
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h), padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Flexible(child: Text(AppLocalizations.of(context)!.pickOnMap, style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        ],

        // ── Manual address form (only shown when no saved addresses) ──
        if (_savedAddresses.isEmpty) ...[
          Text(AppLocalizations.of(context)!.deliveryAddress, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 1.h),
          TextField(controller: _addressCtrl, onChanged: (_) => _calcFee(),
              decoration: InputDecoration(hintText: AppLocalizations.of(context)!.fullAddress, prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: Text(_deliveryLat != null ? AppLocalizations.of(context)!.changeOnMap : AppLocalizations.of(context)!.pickOnMap2, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          TextField(controller: _addressDetailCtrl,
              decoration: InputDecoration(hintText: AppLocalizations.of(context)!.floorAptBuildingOptional, prefixIcon: Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          SizedBox(height: 1.5.h),
          Row(children: ['HOME', 'WORK', 'OTHER'].map((l) => Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(label: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis), selected: _addressLabel == l,
                onSelected: (s) { if (s) setState(() => _addressLabel = l); }),
          )).toList()),
        ],

        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context)!.phoneNumber, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.phoneNumberPlaceholder,
                helperText: _phoneCtrl.text.isEmpty ? "We'll use this to contact you about your orders." : null,
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),

        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context)!.deliveryInstructions, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        TextField(controller: _instructionsCtrl, maxLines: 3,
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.ringDoorbellLeaveAtDoorEtc,
                prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.note_outlined)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),

        SizedBox(height: 2.h),
        _feePreview(theme),
        SizedBox(height: 1.5.h),

        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.payments_outlined, color: Colors.green.shade700, size: 24),
            SizedBox(width: 3.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.cashOnDelivery, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(AppLocalizations.of(context)!.payTheDriverWhenYourOrder,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _feePreview(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
      child: Row(children: [
        Icon(Icons.delivery_dining, color: theme.colorScheme.primary, size: 28),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context)!.deliveryFee, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_isCalculatingFee)
            Text(AppLocalizations.of(context)!.calculating, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis)
          else if (_deliveryFee != null) ...[
            Text('\$${_deliveryFee!.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_lastDistanceKm != null)
              Text('${_lastDistanceKm!.toStringAsFixed(1)} km from warehouse',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
          ] else if (_feeError != null)
            Text(_feeError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis)
          else
            Text(AppLocalizations.of(context)!.enterAddressToCalculate, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        if (_isCalculatingFee) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
      ]),
    );
  }

  Widget _confirmStep(ThemeData theme, List<Map<String, dynamic>> items) {
    final sub = _subtotal(items);
    final tot = _total(sub);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _summaryCard(theme, AppLocalizations.of(context)!.delivery, Icons.location_on_outlined, [
          _addressCtrl.text,
          if (_addressDetailCtrl.text.isNotEmpty) _addressDetailCtrl.text,
          _phoneCtrl.text,
        ]),
        SizedBox(height: 2.h),
        _summaryCard(theme, AppLocalizations.of(context)!.payment, Icons.payments_outlined, ['Cash on Delivery']),
        SizedBox(height: 2.h),

        Text('Order Items (${items.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 1.h),
        ...items.map((item) {
          final p = item['products'] as Map<String, dynamic>?;
          final name = p?['name'] as String? ?? AppLocalizations.of(context)!.unknown;
          final qty = item['quantity'] as int? ?? 1;
          final price = (p?['sale_price'] as num?)?.toDouble() ?? (p?['price'] as num?)?.toDouble() ?? 0.0;
          return Padding(padding: EdgeInsets.only(bottom: 1.h), child: Row(children: [
            Expanded(child: Text('$qty × $name', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Flexible(child: Text('\$${(price * qty).toStringAsFixed(2)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]));
        }),

        Divider(height: 3.h),
        _priceRow(theme, AppLocalizations.of(context)!.subtotal, '\$${sub.toStringAsFixed(2)}'),
        if (_isCalculatingFee) _priceRow(theme, AppLocalizations.of(context)!.deliveryFee, AppLocalizations.of(context)!.calculating)
        else if (_deliveryFee != null) _priceRow(theme, AppLocalizations.of(context)!.deliveryFee, '\$${_deliveryFee!.toStringAsFixed(2)}')
        else _priceRow(theme, AppLocalizations.of(context)!.deliveryFee, 'TBD'),
        if (_feeError != null) Padding(padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text(_feeError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (_lastDistanceKm != null) Padding(padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text('${_lastDistanceKm!.toStringAsFixed(1)} km distance',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
        _priceRow(theme, AppLocalizations.of(context)!.tax, 'Free (Cash)', isFree: true),
        Divider(height: 2.h),
        _priceRow(theme, AppLocalizations.of(context)!.total, '\$${tot.toStringAsFixed(2)}', isTotal: true),

        if (_instructionsCtrl.text.trim().isNotEmpty) ...[
          SizedBox(height: 2.h),
          _summaryCard(theme, AppLocalizations.of(context)!.instructions, Icons.note_outlined, [_instructionsCtrl.text.trim()]),
        ],
        SizedBox(height: 2.h),
      ]),
    );
  }

  Widget _summaryCard(ThemeData theme, String title, IconData icon, List<String> lines) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ...lines.map((l) => Text(l, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ])),
      ]),
    );
  }

  Widget _priceRow(ThemeData theme, String label, String value, {bool isTotal = false, bool isFree = false}) {
    return Padding(padding: EdgeInsets.only(bottom: 0.8.h), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: isTotal ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800) : theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Flexible(child: Text(value, style: isTotal
            ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)
            : theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: isFree ? Colors.green : null), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    ));
  }

  Widget _bottomBar(ThemeData theme, List<Map<String, dynamic>> items) {
    String btnText; VoidCallback? onPress;
    switch (_currentStep) {
      case 0:
        btnText = AppLocalizations.of(context)!.reviewOrder;
        onPress = _addressCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty ? null : () {
          HapticFeedback.lightImpact(); _calcFee(); setState(() => _currentStep = 1);
        };
        break;
      case 1:
        final tot = _total(_subtotal(items));
        btnText = 'Place Order — \$${tot.toStringAsFixed(2)}';
        onPress = _isProcessingOrder || _deliveryFee == null || _isCalculatingFee ? null : () => _placeOrder(items);
        break;
      default: btnText = 'Continue'; onPress = () {};
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(child: Row(children: [
        if (_currentStep > 0) Padding(padding: EdgeInsets.only(right: 2.w), child: IconButton(
          onPressed: () => setState(() => _currentStep--), icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surface,
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))))),
        Expanded(child: SizedBox(height: 6.h, child: ElevatedButton(
          onPressed: onPress,
          child: _isProcessingOrder
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
              : Text(btnText, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ))),
      ])),
    );
  }
}