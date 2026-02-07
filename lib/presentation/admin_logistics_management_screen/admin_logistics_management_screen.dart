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

  // Filter states
  String _driverStatusFilter = 'all';
  String _orderPriorityFilter = 'all';

  // Real-time subscription
  RealtimeChannel? _driverLocationChannel;
  RealtimeChannel? _orderChannel;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default: San Francisco
    zoom: 12.0,
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

      setState(() {
        _isLoading = false;
      });
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
          ''').eq('is_active', true).order('is_online', ascending: false);

      _drivers =
          (response as List).map((json) => Driver.fromJson(json)).toList();
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

  void _setupMarkers() {
    final markers = <Marker>{};

    // Add driver markers
    for (final driver in _drivers) {
      if (driver.currentLocationLat != null &&
          driver.currentLocationLng != null) {
        final position =
            LatLng(driver.currentLocationLat!, driver.currentLocationLng!);

        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver.id}'),
            position: position,
            icon: _getDriverMarkerIcon(driver),
            onTap: () => _onDriverMarkerTapped(driver),
            infoWindow: InfoWindow(
              title: 'Driver ${driver.id.substring(0, 8)}',
              snippet: driver.isOnline ? 'Online' : 'Offline',
            ),
          ),
        );
      }
    }

    // Add order markers
    for (final order in _pendingOrders) {
      if (order.deliveryLat != null && order.deliveryLng != null) {
        final position = LatLng(order.deliveryLat!, order.deliveryLng!);

        markers.add(
          Marker(
            markerId: MarkerId('order_${order.id}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              order.isPriority
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueBlue,
            ),
            onTap: () => _onOrderMarkerTapped(order),
            infoWindow: InfoWindow(
              title: 'Order #${order.orderNumber}',
              snippet: order.isPriority ? 'Priority' : 'Standard',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  BitmapDescriptor _getDriverMarkerIcon(Driver driver) {
    if (!driver.isOnline) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    // Check if driver has active orders
    final hasActiveOrders = _pendingOrders.any((o) => o.driverId == driver.id);
    if (hasActiveOrders) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _subscribeToRealtimeUpdates() {
    // Subscribe to driver location updates
    _driverLocationChannel = _supabaseClient
        .channel('driver_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          callback: (payload) {
            _handleDriverLocationUpdate(payload.newRecord);
          },
        )
        .subscribe();

    // Subscribe to order updates
    _orderChannel = _supabaseClient
        .channel('pending_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _handleOrderUpdate(payload);
          },
        )
        .subscribe();
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    final updatedDriver = Driver.fromJson(data);
    final index = _drivers.indexWhere((d) => d.id == updatedDriver.id);

    if (index != -1) {
      setState(() {
        _drivers[index] = updatedDriver;
      });
      _setupMarkers();
    }
  }

  void _handleOrderUpdate(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert) {
      _loadPendingOrders().then((_) => _setupMarkers());
    } else if (payload.eventType == PostgresChangeEvent.update) {
      _loadPendingOrders().then((_) => _setupMarkers());
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      _loadPendingOrders().then((_) => _setupMarkers());
    }
  }

  void _onDriverMarkerTapped(Driver driver) {
    setState(() {
      _selectedDriver = driver;
    });

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
        title: Text('Order #${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order.status}'),
            SizedBox(height: 1.h),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            SizedBox(height: 1.h),
            Text('Address: ${order.deliveryAddress}'),
            if (order.isPriority)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (order.driverId == null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDriverSelectionDialog(order);
              },
              child: const Text('Assign Driver'),
            ),
        ],
      ),
    );
  }

  void _showOrderAssignmentDialog(Driver driver) {
    final availableOrders =
        _pendingOrders.where((o) => o.driverId == null).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Orders to Driver'),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: availableOrders.isEmpty
              ? const Center(child: Text('No available orders'))
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
                      title: Text('Order #${order.orderNumber}'),
                      subtitle: Text(
                        '\$${order.total.toStringAsFixed(2)} - ${order.deliveryAddress}',
                      ),
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
              setState(() {
                _selectedOrderIds.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _selectedOrderIds.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    await _assignOrdersToDriver(driver.id, _selectedOrderIds);
                  },
            child: Text('Assign ${_selectedOrderIds.length} Orders'),
          ),
        ],
      ),
    );
  }

  void _showDriverSelectionDialog(OrderModel order) {
    // FIX: Driver has no isVerified; approval is status-based.
    final availableDrivers =
        _drivers.where((d) => d.isOnline && d.isApproved).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Driver'),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: availableDrivers.isEmpty
              ? const Center(child: Text('No available drivers'))
              : ListView.builder(
                  itemCount: availableDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = availableDrivers[index];
                    final assignedCount = _pendingOrders
                        .where((o) => o.driverId == driver.id)
                        .length;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            driver.isOnline ? Colors.green : Colors.grey,
                        child: Text(
                          driver.id.substring(0, 2).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('Driver ${driver.id.substring(0, 8)}'),
                      subtitle: Text(
                        'Rating: ${driver.rating.toStringAsFixed(1)} | Orders: $assignedCount',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignOrdersToDriver(String driverId, List<String> orderIds) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assigning orders...')),
        );
      }

      for (final orderId in orderIds) {
        await _orderService.assignDriver(orderId, driverId);
      }

      setState(() {
        _selectedOrderIds.clear();
      });

      await _loadPendingOrders();
      _setupMarkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned ${orderIds.length} order(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign orders: $e'),
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
        title: const Text(
          'Logistics Management',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: Icon(
              _showMetrics ? Icons.close : Icons.analytics_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showMetrics = !_showMetrics;
              });
            },
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
                      Text(_error!),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _initializeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _initialPosition,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                    ),
                    Positioned(
                      top: 2.h,
                      left: 4.w,
                      right: 4.w,
                      child: QuickActionToolbarWidget(
                        onlineDriversCount:
                            _drivers.where((d) => d.isOnline).length,
                        totalDriversCount: _drivers.length,
                        pendingOrdersCount: _pendingOrders.length,
                        onRefresh: _initializeData,
                        onToggleOrderQueue: () {
                          setState(() {
                            _showOrderQueue = !_showOrderQueue;
                          });
                        },
                      ),
                    ),
                    if (_showOrderQueue)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: OrderQueuePanelWidget(
                          orders: _pendingOrders,
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
                          onClearSelection: () {
                            setState(() {
                              _selectedOrderIds.clear();
                            });
                          },
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: FilterControlsWidget(
          driverStatusFilter: _driverStatusFilter,
          orderPriorityFilter: _orderPriorityFilter,
          onDriverStatusChanged: (value) {
            setState(() {
              _driverStatusFilter = value;
            });
          },
          onOrderPriorityChanged: (value) {
            setState(() {
              _orderPriorityFilter = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    _initializeData();
  }

  void _showDriverSelectionForBatch() {
    // FIX: Driver has no isVerified; approval is status-based.
    final availableDrivers =
        _drivers.where((d) => d.isOnline && d.isApproved).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${_selectedOrderIds.length} Orders'),
        content: SizedBox(
          width: 80.w,
          height: 50.h,
          child: availableDrivers.isEmpty
              ? const Center(child: Text('No available drivers'))
              : ListView.builder(
                  itemCount: availableDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = availableDrivers[index];
                    final assignedCount = _pendingOrders
                        .where((o) => o.driverId == driver.id)
                        .length;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            driver.isOnline ? Colors.green : Colors.grey,
                        child: Text(
                          driver.id.substring(0, 2).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('Driver ${driver.id.substring(0, 8)}'),
                      subtitle: Text(
                        'Rating: ${driver.rating.toStringAsFixed(1)} | Current: $assignedCount orders',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        Navigator.pop(context);
                        await _assignOrdersToDriver(driver.id, _selectedOrderIds);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
