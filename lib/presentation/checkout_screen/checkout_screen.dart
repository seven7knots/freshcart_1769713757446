import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_address_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/supabase_service.dart';
import '../map_location_picker/map_location_picker_screen.dart';

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

  int _currentStep = 0; // 0=Delivery, 1=Confirm (cash only — no payment step)
  bool _isProcessingOrder = false;
  bool _isLoadingUser = true;
  String _customerName = '';
  String _addressLabel = 'HOME';
  List<Map<String, dynamic>> _savedAddresses = [];
  int _selectedAddressIndex = -1;

  // ── Delivery Fee State ───────────────────────────────────────
  double? _deliveryFee;
  bool _isCalculatingFee = false;
  String? _feeError;
  double? _lastDistanceKm;
  double? _deliveryLat;
  double? _deliveryLng;

  // ── Config ───────────────────────────────────────────────────
  // TODO: Replace with your actual Google Maps API key
  static const String _googleMapsApiKey = 'AIzaSyCXDutfJxPiziGezC4GXLIsOQKaTWU5Vca';
  static const double _warehouseLat = 33.7684; // Aley center
  static const double _warehouseLng = 35.5960;
  static const double _baseFee = 2.20;
  static const double _maxDistKm = 100.0;

  // Band rates: rate × full distance (0–25 km)
  static const _bands = [
    _Band(8, 0.70),
    _Band(15, 0.55),
    _Band(25, 0.40),
  ];

  // Cumulative rates: each rate applies only to km within that band (25+ km)
  // Anchor at 25 km = $12.20
  static const _cumul = [
    _Cumul(25, 35, 0.78),
    _Cumul(35, 50, 0.30),
    _Cumul(50, 65, 0.22),
    _Cumul(65, 80, 0.16),
    _Cumul(80, 100, 0.10),
  ];

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

  // ============================================================
  // USER DATA
  // ============================================================

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
      } catch (_) {}
    } finally {
      if (mounted) { setState(() => _isLoadingUser = false); _calcFee(); }
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
      await SupabaseService.client.from('users')
          .update({'saved_addresses': _savedAddresses}).eq('id', user.id);
    } catch (e) { debugPrint('Save address error: $e'); }
  }

  // ============================================================
  // MAP PICKER
  // ============================================================

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
        _selectedAddressIndex = -1; // mark as custom/new
      });
      _calcFee();
    }
  }

  // ============================================================
  // DELIVERY FEE FORMULA
  // ============================================================

  /// Banded pricing with floor-hold transitions.
  /// 0-25km: fee = baseFee + rate × fullDistance (floor at each boundary)
  /// 25-100km: cumulative bands from $12.20 anchor
  static double _computeFee(double km) {
    if (km <= 0) return _baseFee;

    // ── 0-25km: rate × full distance + floor protection ──
    if (km <= 25) {
      // Find band rate
      double rate = _bands.last.rate;
      for (final b in _bands) {
        if (km <= b.maxKm) { rate = b.rate; break; }
      }
      double fee = _baseFee + rate * km;

      // Floor: fee never drops below previous band's endpoint
      for (int i = 0; i < _bands.length - 1; i++) {
        if (km > _bands[i].maxKm) {
          final floor = _baseFee + _bands[i].rate * _bands[i].maxKm;
          if (fee < floor) fee = floor;
        }
      }
      return fee;
    }

    // ── 25-100km: cumulative from $12.20 anchor ──
    double fee = _baseFee + 0.40 * 25; // $12.20
    for (final c in _cumul) {
      if (km <= c.startKm) break;
      final inBand = (km < c.endKm ? km : c.endKm.toDouble()) - c.startKm;
      if (inBand > 0) fee += c.rate * inBand;
    }
    return fee;
  }

  Future<void> _calcFee() async {
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() { _deliveryFee = null; _feeError = null; _lastDistanceKm = null; });
      return;
    }
    setState(() { _isCalculatingFee = true; _feeError = null; });

    try {
      double? cLat = _deliveryLat;
      double? cLng = _deliveryLng;

      // If no direct coordinates, try saved address
      if (cLat == null && cLng == null &&
          _selectedAddressIndex >= 0 && _selectedAddressIndex < _savedAddresses.length) {
        final a = _savedAddresses[_selectedAddressIndex];
        cLat = (a['lat'] as num?)?.toDouble();
        cLng = (a['lng'] as num?)?.toDouble();
      }

      double distKm;
      if (cLat != null && cLng != null && _googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY') {
        distKm = await _gmapsDistance(_warehouseLat, _warehouseLng, cLat, cLng);
      } else if (cLat != null && cLng != null) {
        distKm = _haversine(_warehouseLat, _warehouseLng, cLat, cLng) * 1.35;
      } else {
        setState(() {
          _deliveryFee = _baseFee; _isCalculatingFee = false; _lastDistanceKm = null;
          _feeError = 'Using base fee — set exact location for accurate pricing';
        });
        return;
      }

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
        _lastDistanceKm = null; _feeError = 'Could not calculate exact fee, using base rate';
      });
    }
  }

  Future<double> _gmapsDistance(double oLat, double oLng, double dLat, double dLng) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$oLat,$oLng&destinations=$dLat,$dLng&mode=driving&key=$_googleMapsApiKey');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('API error: ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') throw Exception('API status: ${data['status']}');
    final el = ((data['rows'] as List)[0] as Map<String, dynamic>)['elements'] as List;
    if (el.isEmpty || el[0]['status'] != 'OK') throw Exception('No route');
    return (((el[0] as Map<String, dynamic>)['distance'] as Map<String, dynamic>)['value'] as int) / 1000.0;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1), dLng = _rad(lng2 - lng1);
    final a = _sin2(dLat / 2) + _cos2(_rad(lat1)) * _cos2(_rad(lat2)) * _sin2(dLng / 2);
    return R * 2 * _atan2(_sqrt(a), _sqrt(1 - a));
  }

  double _rad(double d) => d * 3.141592653589793 / 180.0;
  double _sin2(double x) { double r = x, t = x; for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i) * (2*i+1)); r += t; } return r; }
  double _cos2(double x) { double r = 1, t = 1.0; for (int i = 1; i <= 10; i++) { t *= -x * x / ((2*i-1) * (2*i)); r += t; } return r; }
  double _sqrt(double x) { if (x <= 0) return 0; double g = x / 2; for (int i = 0; i < 20; i++) {
    g = (g + x / g) / 2;
  } return g; }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  double _atan(double x) { double r = x, t = x; for (int i = 1; i <= 15; i++) { t *= -x * x * (2*i-1) / (2*i+1); r += t / (2*i+1); } return r; }

  // ============================================================
  // PRICING
  // ============================================================

  double _subtotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (s, item) {
      final p = item['products'] as Map<String, dynamic>?;
      if (p == null) return s;
      final price = (p['sale_price'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0.0;
      return s + price * (item['quantity'] as int? ?? 1);
    });
  }

  double _total(double sub) => sub + (_deliveryFee ?? 0.0);

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> _placeOrder(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    if (_deliveryFee == null || _isCalculatingFee) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery fee still calculating, please wait'), backgroundColor: Colors.orange));
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a delivery address'), backgroundColor: Colors.orange));
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number'), backgroundColor: Colors.orange));
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
        'items': orderItems,
        'distance_km': _lastDistanceKm,
      }).select().single();

      await ref.read(cartNotifierProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Order placed successfully!'), backgroundColor: Colors.green.shade600));
        Navigator.of(context).pushReplacementNamed(AppRoutes.orderTracking, arguments: response);
      }
    } catch (e) {
      debugPrint('Order error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessingOrder = false);
    }
  }

  List<Map<String, dynamic>> get _cartItems {
    final cart = ref.watch(cartNotifierProvider);
    return cart.when(data: (i) => i, loading: () => [], error: (_, __) => []);
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _cartItems;

    if (items.isEmpty && !_isProcessingOrder) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: theme.colorScheme.outline),
          SizedBox(height: 2.h),
          Text('Your cart is empty', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
          SizedBox(height: 2.h),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continue Shopping')),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Delivery Details' : 'Confirm Order'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.5.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(children: List.generate(2, (i) => Expanded(child: Container(
              height: 3, margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                color: i <= _currentStep ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)),
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

  // ── Delivery Step ────────────────────────────────────────────

  Widget _deliveryStep(ThemeData theme, List<Map<String, dynamic>> items) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_savedAddresses.isNotEmpty) ...[
          Text('Saved Addresses', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2), width: sel ? 2 : 1)),
                child: Row(children: [
                  Icon((addr['label'] as String? ?? 'HOME') == 'WORK' ? Icons.work_outline : Icons.home_outlined,
                      color: sel ? theme.colorScheme.primary : theme.colorScheme.outline),
                  SizedBox(width: 3.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((addr['label'] as String? ?? 'HOME').toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: sel ? theme.colorScheme.primary : null)),
                    Text(addr['address'] as String? ?? '', style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  if (sel) Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ]),
              ),
            );
          }),
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h), padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text('Pick on Map', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _selectedAddressIndex = -1; _addressCtrl.clear(); _addressDetailCtrl.clear(); _addressLabel = 'HOME'; }); _calcFee(); },
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h), padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _selectedAddressIndex == -1 ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedAddressIndex == -1 ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_location_alt_outlined, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text('Enter new address', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],

        if (_savedAddresses.isEmpty || _selectedAddressIndex == -1) ...[
          Text('Delivery Address', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 1.h),
          TextField(controller: _addressCtrl, onChanged: (_) => _calcFee(),
              decoration: InputDecoration(hintText: 'Full address', prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: Text(_deliveryLat != null ? 'Change on Map' : 'Pick on Map'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          TextField(controller: _addressDetailCtrl,
              decoration: InputDecoration(hintText: 'Floor, apt, building (optional)', prefixIcon: const Icon(Icons.apartment_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          SizedBox(height: 1.5.h),
          Row(children: ['HOME', 'WORK', 'OTHER'].map((l) => Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(label: Text(l), selected: _addressLabel == l,
                onSelected: (s) { if (s) setState(() => _addressLabel = l); }),
          )).toList()),
        ],

        SizedBox(height: 2.h),
        Text('Phone Number', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 1.h),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: '+961 XX XXX XXX', prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),

        SizedBox(height: 2.h),
        Text('Delivery Instructions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 1.h),
        TextField(controller: _instructionsCtrl, maxLines: 3,
            decoration: InputDecoration(hintText: 'Ring doorbell, leave at door, etc.',
                prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.note_outlined)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),

        SizedBox(height: 2.h),
        _feePreview(theme),
        SizedBox(height: 1.5.h),

        // Cash on delivery notice
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.payments_outlined, color: Colors.green.shade700, size: 24),
            SizedBox(width: 3.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cash on Delivery', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade700)),
              Text('Pay the driver when your order arrives. Please have the exact amount ready.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _feePreview(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
      child: Row(children: [
        Icon(Icons.delivery_dining, color: theme.colorScheme.primary, size: 28),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Delivery Fee', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
          if (_isCalculatingFee)
            Text('Calculating...', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))
          else if (_deliveryFee != null) ...[
            Text('\$${_deliveryFee!.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            if (_lastDistanceKm != null)
              Text('${_lastDistanceKm!.toStringAsFixed(1)} km from warehouse',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10.sp)),
          ] else if (_feeError != null)
            Text(_feeError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontSize: 10.sp))
          else
            Text('Enter address to calculate', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ])),
        if (_isCalculatingFee) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
      ]),
    );
  }

  // ── Confirm Step ─────────────────────────────────────────────

  Widget _confirmStep(ThemeData theme, List<Map<String, dynamic>> items) {
    final sub = _subtotal(items);
    final tot = _total(sub);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _summaryCard(theme, 'Delivery', Icons.location_on_outlined, [
          _addressCtrl.text,
          if (_addressDetailCtrl.text.isNotEmpty) _addressDetailCtrl.text,
          _phoneCtrl.text,
        ]),
        SizedBox(height: 2.h),
        _summaryCard(theme, 'Payment', Icons.payments_outlined, ['Cash on Delivery']),
        SizedBox(height: 2.h),

        Text('Order Items (${items.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: 1.h),
        ...items.map((item) {
          final p = item['products'] as Map<String, dynamic>?;
          final name = p?['name'] as String? ?? 'Unknown';
          final qty = item['quantity'] as int? ?? 1;
          final price = (p?['sale_price'] as num?)?.toDouble() ?? (p?['price'] as num?)?.toDouble() ?? 0.0;
          return Padding(padding: EdgeInsets.only(bottom: 1.h), child: Row(children: [
            Expanded(child: Text('$qty × $name', style: theme.textTheme.bodySmall)),
            Text('\$${(price * qty).toStringAsFixed(2)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ]));
        }),

        Divider(height: 3.h),
        _priceRow(theme, 'Subtotal', '\$${sub.toStringAsFixed(2)}'),
        if (_isCalculatingFee) _priceRow(theme, 'Delivery Fee', 'Calculating...')
        else if (_deliveryFee != null) _priceRow(theme, 'Delivery Fee', '\$${_deliveryFee!.toStringAsFixed(2)}')
        else _priceRow(theme, 'Delivery Fee', 'TBD'),
        if (_feeError != null) Padding(padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text(_feeError!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontSize: 10.sp))),
        if (_lastDistanceKm != null) Padding(padding: EdgeInsets.only(bottom: 0.5.h),
            child: Text('${_lastDistanceKm!.toStringAsFixed(1)} km distance',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 10.sp))),
        _priceRow(theme, 'Tax', 'Free (Cash)', isFree: true),
        Divider(height: 2.h),
        _priceRow(theme, 'Total', '\$${tot.toStringAsFixed(2)}', isTotal: true),

        if (_instructionsCtrl.text.trim().isNotEmpty) ...[
          SizedBox(height: 2.h),
          _summaryCard(theme, 'Instructions', Icons.note_outlined, [_instructionsCtrl.text.trim()]),
        ],
        SizedBox(height: 2.h),
      ]),
    );
  }

  Widget _summaryCard(ThemeData theme, String title, IconData icon, List<String> lines) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        SizedBox(width: 3.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
          ...lines.map((l) => Text(l, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ])),
      ]),
    );
  }

  Widget _priceRow(ThemeData theme, String label, String value, {bool isTotal = false, bool isFree = false}) {
    return Padding(padding: EdgeInsets.only(bottom: 0.8.h), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: isTotal ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800) : theme.textTheme.bodySmall),
        Text(value, style: isTotal
            ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)
            : theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: isFree ? Colors.green : null)),
      ],
    ));
  }

  // ── Bottom Bar ───────────────────────────────────────────────

  Widget _bottomBar(ThemeData theme, List<Map<String, dynamic>> items) {
    String btnText; VoidCallback? onPress;
    switch (_currentStep) {
      case 0:
        btnText = 'Review Order';
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
              : Text(btnText, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700)),
        ))),
      ])),
    );
  }
}

// ── Pricing band helpers ─────────────────────────────────────────
class _Band { final double maxKm, rate; const _Band(this.maxKm, this.rate); }
class _Cumul { final int startKm, endKm; final double rate; const _Cumul(this.startKm, this.endKm, this.rate); }