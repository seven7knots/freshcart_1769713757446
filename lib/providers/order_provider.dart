import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/driver_deliveries_provider.dart';
import '../../providers/merchant_orders_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final userOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getUserOrders();
});

final activeOrderProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getActiveOrder();
});

final orderByIdProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final orderService = ref.watch(orderServiceProvider);
  final orderModel = await orderService.getOrderById(orderId);
  return orderModel.toJson();
});

// Provider for order tracking
final orderTrackingProvider = ChangeNotifierProvider<OrderTrackingProvider>(
  (ref) => OrderTrackingProvider(),
);

// Provider for merchant orders
final merchantOrdersProvider = ChangeNotifierProvider<MerchantOrdersProvider>(
  (ref) => MerchantOrdersProvider(),
);

// Provider for driver deliveries
final driverDeliveriesProvider =
    ChangeNotifierProvider<DriverDeliveriesProvider>(
  (ref) => DriverDeliveriesProvider(),
);
