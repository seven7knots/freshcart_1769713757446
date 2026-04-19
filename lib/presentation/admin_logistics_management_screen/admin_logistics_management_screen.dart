import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/driver_model.dart';
import '../../models/order_model.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import './widgets/driver_marker_info_widget.dart';
import './widgets/filter_controls_widget.dart';
import './widgets/order_queue_panel_widget.dart';
import './widgets/performance_metrics_sidebar_widget.dart';
import './widgets/quick_action_toolbar_widget.dart';
import '../../l10n/generated/app_localizations.dart';

class AdminLogisticsManagementScreen extends StatefulWidget {
  const AdminLogisticsManagementScreen({super.key});

  @override
  State<AdminLogisticsManagementScreen> createState() =>
      _AdminLogisticsManagementScreenState();
}

class _AdminLogisticsManagementScreenState
    extends State<AdminLogisticsManagementScreen> {
  GoogleMapController? _mapController;
  final AdminService _adminService = AdminService();
  final OrderService _orderService = OrderService();
  final SupabaseClient _supabaseClient = SupabaseService.client;

  List<Driver> _drivers = [];
  List<OrderModel> _pendingOrders = [];
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  Driver? _selectedDriver;
  final List<String> _selectedOrderIds = [];
  bool _showOrderQueue = true;
  bool _showMetrics = false;

  String _driverStatusFilter = 'all';
  String _orderPriorityFilter = 'all';

  RealtimeChannel? _driverLocationChannel;
  RealtimeChannel? _orderChannel;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.89, 35.50),
    zoom: 10.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _driverLocationChannel?.unsubscribe();
    _orderChannel?.unsubscribe();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadDrivers(),
        _loadPendingOrders(),
      ]);

      _setupMarkers();
      _subscribeToRealtimeUpdates();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load logistics data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDrivers() async {
    try {
      final response = await _supabaseClient.from('drivers').select('''
            *,
            users!drivers_user_id_fkey (id, full_name, phone, avatar_url)
          ''')
          .eq('is_active', true)
          .eq('is_online', true)
          .order('is_online', ascending: false);

      // DART-SIDE FILTER: safety net in case RLS bypasses the DB-level eq() filters.
      // Only keep drivers that are genuinely online AND active. canTakeOrders
      // (isApproved && isActive && isOnline && isAvailable) is enforced at the
      // assignment layer via _assignableDrivers getter below.
      final allDrivers =
          (response as List).map((json) => Driver.fromJson(json)).toList();

      _drivers = allDrivers
          .where((d) => d.isOnline && d.isActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to load drivers: $e');
    }
  }

  Future<void> _loadPendingOrders() async {
    try {
      final response = await _supabaseClient
          .from('orders')
          .select('''
            *,
            stores (name, name_ar, address, latitude, longitude)
          ''')
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready'])
          .order('is_priority', ascending: false)
          .order('created_at', ascending: true);

      _pendingOrders =
          (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load pending orders: $e');
    }
  }

  // Only drivers that pass ALL four canTakeOrders checks are eligible:
  // isApproved && isActive && isOnline && isAvailable
  List<Driver> get _assignableDrivers =>
      _drivers.where((d) => d.canTakeOrders).toList();

  List<Driver> get _filteredDrivers {
    switch (_driverStatusFilter) {
      case 'online':
        return _drivers.where((d) => d.isOnline).toList();
      case 'offline':
        return _drivers.where((d) => !d.isOnline).toList();
      case 'busy':
        return _drivers
            .where((d) =>
                d.isOnline && _pendingOrders.any((o) => o.driverId == d.id))
            .toList();
      case 'available':
        return _drivers
            .where((d) =>
                d.isOnline &&
                !_pendingOrders.any((o) => o.driverId == d.id))
            .toList();
      case 'all':
      default:
        return _drivers;
    }
  }

  List<OrderModel> get _filteredOrders {
    switch (_orderPriorityFilter) {
      case 'priority':
        return _pendingOrders.where((o) => o.isPriority).toList();
      case 'standard':
        return _pendingOrders.where((o) => !o.isPriority).toList();
      case 'unassigned':
        return _pendingOrders.where((o) => o.driverId == null).toList();
      case 'assigned':
        return _pendingOrders.where((o) => o.driverId != null).toList();
      case 'all':
      default:
        return _pendingOrders;
    }
  }

  void _setupMarkers() {
    final markers = <Marker>{};

    for (final driver in _filteredDrivers) {
      if (driver.currentLocationLat != null &&
          driver.currentLocationLng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver.id}'),
            position:
                LatLng(driver.currentLocationLat!, driver.currentLocationLng!),
            icon: _getDriverMarkerIcon(driver),
            onTap: () => _onDriverMarkerTapped(driver),
            infoWindow: InfoWindow(
              title: 'Driver ${driver.id.substring(0, 8)}',
              snippet: driver.isOnline ? AppLocalizations.of(context)!.online2 : AppLocalizations.of(context)!.offline2,
            ),
          ),
        );
      }
    }

    for (final order in _filteredOrders) {
      if (order.deliveryLat != null && order.deliveryLng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('order_${order.id}'),
            position: LatLng(order.deliveryLat!, order.deliveryLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              order.isPriority
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueBlue,
            ),
            onTap: () => _onOrderMarkerTapped(order),
            infoWindow: InfoWindow(
              title: 'Order #${order.orderNumber}',
              snippet: order.isPriority ? AppLocalizations.of(context)!.priority2 : AppLocalizations.of(context)!.standard2,
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  BitmapDescriptor _getDriverMarkerIcon(Driver driver) {
    if (!driver.isOnline) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    final hasActiveOrders =
        _pendingOrders.any((o) => o.driverId == driver.id);
    return hasActiveOrders
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _subscribeToRealtimeUpdates() {
    _driverLocationChannel = _supabaseClient
        .channel('driver_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          callback: (payload) =>
              _handleDriverLocationUpdate(payload.newRecord),
        )
        .subscribe();

    _orderChannel = _supabaseClient
        .channel('pending_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) => _handleOrderUpdate(payload),
        )
        .subscribe();
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    final updatedDriver = Driver.fromJson(data);
    final index = _drivers.indexWhere((d) => d.id == updatedDriver.id);

    if (index != -1) {
      if (updatedDriver.isOnline && updatedDriver.isActive) {
        // Driver still qualifies — update in place
        setState(() => _drivers[index] = updatedDriver);
      } else {
        // Driver went offline — remove from list immediately
        setState(() => _drivers.removeAt(index));
      }
      _setupMarkers();
    } else if (updatedDriver.isOnline && updatedDriver.isActive) {
      // Driver just came online — add them
      setState(() => _drivers.add(updatedDriver));
      _setupMarkers();
    }
  }

  void _handleOrderUpdate(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update ||
        payload.eventType == PostgresChangeEvent.delete) {
      _loadPendingOrders().then((_) => _setupMarkers());
    }
  }

  void _onDriverMarkerTapped(Driver driver) {
    setState(() => _selectedDriver = driver);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverMarkerInfoWidget(
        driver: driver,
        assignedOrdersCount:
            _pendingOrders.where((o) => o.driverId == driver.id).length,
        onAssignOrders: () {
          Navigator.pop(context);
          _showOrderAssignmentDialog(driver);
        },
      ),
    );
  }

  void _onOrderMarkerTapped(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.orderNumber}', maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order.status}', maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text('Total: \$${order.total.toStringAsFixed(2)}', maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Text('Address: ${order.deliveryAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
            if (order.isPriority)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text('PRIORITY',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (order.driverId == null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDriverSelectionDialog(order);
              },
              child: Text(AppLocalizations.of(context)!.assignDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  void _showOrderAssignmentDialog(Driver driver) {
    // Hard block — cannot assign to offline/unapproved driver
    if (!driver.canTakeOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.cannotAssignOrdersDriverIsOffline, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final availableOrders =
        _pendingOrders.where((o) => o.driverId == null).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.assignOrdersToDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Flexible(child: Text(
                  'Online · Driver ${driver.id.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: availableOrders.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noUnassignedOrdersAvailable, maxLines: 1, overflow: TextOverflow.ellipsis))
              : ListView.builder(
                  itemCount: availableOrders.length,
                  itemBuilder: (context, index) {
                    final order = availableOrders[index];
                    final isSelected = _selectedOrderIds.contains(order.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedOrderIds.add(order.id);
                          } else {
                            _selectedOrderIds.remove(order.id);
                          }
                        });
                        Navigator.pop(context);
                        _showOrderAssignmentDialog(driver);
                      },
                      title: Text('Order #${order.orderNumber}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '\$${order.total.toStringAsFixed(2)} · ${order.deliveryAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      secondary: order.isPriority
                          ? const Icon(Icons.priority_high, color: Colors.red)
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedOrderIds.clear());
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ElevatedButton(
            onPressed: _selectedOrderIds.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    await _assignOrdersToDriver(
                        driver.id, _selectedOrderIds);
                  },
            child: Text('Assign ${_selectedOrderIds.length} Orders', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // Only show online + approved drivers — _assignableDrivers guarantees this
  void _showDriverSelectionDialog(OrderModel order) {
    final eligibleDrivers = _assignableDrivers;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: eligibleDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 48, color: Colors.grey.shade400),
                      SizedBox(height: 2.h),
                      Text(
                        AppLocalizations.of(context)!.noDriversOnline,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Text(
                        'Wait for a driver to come online\nbefore assigning orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: eligibleDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = eligibleDrivers[index];
                    final assignedCount = _pendingOrders
                        .where((o) => o.driverId == driver.id)
                        .length;

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              driver.fullName.isNotEmpty
                                  ? driver.fullName
                                      .substring(0, 2)
                                      .toUpperCase()
                                  : driver.id.substring(0, 2).toUpperCase(),
                              style:
                                  TextStyle(color: Colors.green.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(driver.fullName.isNotEmpty
                          ? driver.fullName
                          : 'Driver ${driver.id.substring(0, 8)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'Rating: ${driver.rating.toStringAsFixed(1)} · $assignedCount active order${assignedCount != 1 ? 's' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        Navigator.pop(context);
                        await _assignOrdersToDriver(driver.id, [order.id]);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _assignOrdersToDriver(
      String driverId, List<String> orderIds) async {
    // Final guard before any DB write — verify driver is still online right now
    final driver = _drivers.firstWhere(
      (d) => d.id == driverId,
      orElse: () => throw Exception('Driver not found in local list'),
    );

    if (!driver.canTakeOrders) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment blocked — driver is no longer available', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigning orders...', maxLines: 1, overflow: TextOverflow.ellipsis)),
        );
      }

      for (final orderId in orderIds) {
        await _orderService.assignDriver(orderId, driverId);
      }

      setState(() => _selectedOrderIds.clear());
      await _loadPendingOrders();
      _setupMarkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully assigned ${orderIds.length} order(s)', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign orders: $e', maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMarkersInView();
  }

  void _fitMarkersInView() {
    if (_mapController != null && _markers.isNotEmpty) {
      final positions = _markers.map((m) => m.position).toList();
      final bounds = _calculateBounds(positions);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.logisticsManagement,
          style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_driverStatusFilter != 'all' ||
                      _orderPriorityFilter != 'all')
                  ? Colors.orange
                  : Colors.black,
            ),
            onPressed: _showFilterDialog,
            tooltip: AppLocalizations.of(context)!.filterDriversOrders,
          ),
          IconButton(
            icon: Icon(
              _showMetrics ? Icons.close : Icons.analytics_outlined,
              color: Colors.black,
            ),
            onPressed: () => setState(() => _showMetrics = !_showMetrics),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _initializeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      SizedBox(height: 2.h),
                      Text(_error!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SizedBox.expand(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: _initialPosition,
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                      ),
                    ),
                    if (_driverStatusFilter != 'all' ||
                        _orderPriorityFilter != 'all')
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 0.8.h),
                          color: Colors.orange.withOpacity(0.9),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  'Filters: ${_driverStatusFilter != 'all' ? 'Drivers: $_driverStatusFilter' : ''}${_driverStatusFilter != 'all' && _orderPriorityFilter != 'all' ? ' | ' : ''}${_orderPriorityFilter != 'all' ? 'Orders: $_orderPriorityFilter' : ''}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _driverStatusFilter = 'all';
                                    _orderPriorityFilter = 'all';
                                  });
                                  _setupMarkers();
                                },
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: (_driverStatusFilter != 'all' ||
                              _orderPriorityFilter != 'all')
                          ? 5.h
                          : 2.h,
                      left: 4.w,
                      right: 4.w,
                      child: QuickActionToolbarWidget(
                        onlineDriversCount: _filteredDrivers
                            .where((d) => d.isOnline)
                            .length,
                        totalDriversCount: _filteredDrivers.length,
                        pendingOrdersCount: _filteredOrders.length,
                        onRefresh: _initializeData,
                        onToggleOrderQueue: () => setState(
                            () => _showOrderQueue = !_showOrderQueue),
                      ),
                    ),
                    if (_showOrderQueue)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: OrderQueuePanelWidget(
                          orders: _filteredOrders,
                          selectedOrderIds: _selectedOrderIds,
                          onOrderSelected: (orderId) {
                            setState(() {
                              if (_selectedOrderIds.contains(orderId)) {
                                _selectedOrderIds.remove(orderId);
                              } else {
                                _selectedOrderIds.add(orderId);
                              }
                            });
                          },
                          onBatchAssign: () {
                            if (_selectedOrderIds.isNotEmpty) {
                              _showDriverSelectionForBatch();
                            }
                          },
                          onClearSelection: () =>
                              setState(() => _selectedOrderIds.clear()),
                        ),
                      ),
                    if (_showMetrics)
                      Positioned(
                        top: 10.h,
                        right: 0,
                        bottom: _showOrderQueue ? 35.h : 0,
                        child: PerformanceMetricsSidebarWidget(
                          drivers: _drivers,
                          orders: _pendingOrders,
                        ),
                      ),
                  ],
                ),
    );
  }

  void _showFilterDialog() {
    String tempDriverFilter = _driverStatusFilter;
    String tempOrderFilter = _orderPriorityFilter;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.filterOptions, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: FilterControlsWidget(
            driverStatusFilter: tempDriverFilter,
            orderPriorityFilter: tempOrderFilter,
            onDriverStatusChanged: (value) =>
                setDialogState(() => tempDriverFilter = value),
            onOrderPriorityChanged: (value) =>
                setDialogState(() => tempOrderFilter = value),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _driverStatusFilter = 'all';
                  _orderPriorityFilter = 'all';
                });
                _setupMarkers();
              },
              child: Text(AppLocalizations.of(context)!.reset, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _driverStatusFilter = tempDriverFilter;
                  _orderPriorityFilter = tempOrderFilter;
                });
                _setupMarkers();
              },
              child: Text(AppLocalizations.of(context)!.apply, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // Batch assign also uses _assignableDrivers — no offline drivers ever shown
  void _showDriverSelectionForBatch() {
    final eligibleDrivers = _assignableDrivers;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${_selectedOrderIds.length} Orders', maxLines: 1, overflow: TextOverflow.ellipsis),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: eligibleDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 48, color: Colors.grey.shade400),
                      SizedBox(height: 2.h),
                      Text(
                        AppLocalizations.of(context)!.noDriversOnline,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 1.h),
                      Text(
                        'Wait for a driver to come online\nbefore assigning orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: eligibleDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = eligibleDrivers[index];
                    final assignedCount = _pendingOrders
                        .where((o) => o.driverId == driver.id)
                        .length;

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              driver.fullName.isNotEmpty
                                  ? driver.fullName
                                      .substring(0, 2)
                                      .toUpperCase()
                                  : driver.id.substring(0, 2).toUpperCase(),
                              style:
                                  TextStyle(color: Colors.green.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(driver.fullName.isNotEmpty
                          ? driver.fullName
                          : 'Driver ${driver.id.substring(0, 8)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'Rating: ${driver.rating.toStringAsFixed(1)} · $assignedCount active order${assignedCount != 1 ? 's' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        Navigator.pop(context);
                        await _assignOrdersToDriver(
                            driver.id, _selectedOrderIds);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}