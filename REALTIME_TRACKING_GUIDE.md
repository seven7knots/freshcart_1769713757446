# Real-Time Order Tracking Implementation

This document describes the real-time order tracking implementation using Supabase streams.

## Features Implemented

### 1. Customer Order Tracking
- **Real-time order status updates**: Customers receive live updates when order status changes (confirmed, preparing, ready, picked_up, in_transit, delivered)
- **Real-time driver location tracking**: Customers can see driver's location updates on the map as they approach
- **Local notifications**: Automatic notifications when order status changes
- **SMS notifications**: WhatsApp messages via Twilio for important status updates

### 2. Merchant New Order Alerts
- **Real-time new order notifications**: Merchants receive instant alerts when new orders arrive
- **Order details**: Full order information including items, customer details, and total
- **Sound and visual alerts**: Prominent notifications to ensure orders aren't missed
- **SMS notifications**: WhatsApp messages to merchant phone for new orders

### 3. Driver Delivery Assignments
- **Real-time delivery assignments**: Drivers receive instant notifications when assigned to a delivery
- **Delivery details**: Complete order and pickup/delivery location information
- **SMS notifications**: WhatsApp messages to driver phone for new assignments

## Usage

### Customer - Track Order

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    
    // Subscribe to order updates
    final orderId = 'your-order-id';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderTrackingProvider.notifier).subscribeToOrderUpdates(orderId);
    });
  }

  @override
  void dispose() {
    // Unsubscribe when leaving screen
    ref.read(orderTrackingProvider.notifier).unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(orderTrackingProvider);
    final currentOrder = trackingState.currentOrder;
    final driverLocation = trackingState.driverLocation;

    return Scaffold(
      body: Column(
        children: [
          // Display order status
          Text('Status: ${currentOrder?.status}'),
          
          // Display driver location if available
          if (driverLocation != null)
            Text('Driver at: ${driverLocation['latitude']}, ${driverLocation['longitude']}'),
        ],
      ),
    );
  }
}
```

### Merchant - Monitor New Orders

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';

class MerchantDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends ConsumerState<MerchantDashboard> {
  @override
  void initState() {
    super.initState();
    
    // Subscribe to new orders for your store
    final storeId = 'your-store-id';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(merchantOrdersProvider.notifier).subscribeToNewOrders(storeId);
    });
  }

  @override
  void dispose() {
    ref.read(merchantOrdersProvider.notifier).unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(merchantOrdersProvider);
    final pendingOrders = ordersState.pendingOrders;

    return Scaffold(
      body: ListView.builder(
        itemCount: pendingOrders.length,
        itemBuilder: (context, index) {
          final order = pendingOrders[index];
          return ListTile(
            title: Text('Order #${order['order_number']}'),
            subtitle: Text('Total: \$${order['total']}'),
          );
        },
      ),
    );
  }
}
```

### Driver - Monitor Delivery Assignments

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  @override
  void initState() {
    super.initState();
    
    // Subscribe to delivery assignments
    final driverId = 'your-driver-id';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverDeliveriesProvider.notifier).subscribeToDeliveryAssignments(driverId);
    });
  }

  @override
  void dispose() {
    ref.read(driverDeliveriesProvider.notifier).unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesState = ref.watch(driverDeliveriesProvider);
    final assignedDeliveries = deliveriesState.assignedDeliveries;

    return Scaffold(
      body: ListView.builder(
        itemCount: assignedDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = assignedDeliveries[index];
          final order = delivery['orders'] as Map<String, dynamic>?;
          return ListTile(
            title: Text('Delivery #${order?['order_number']}'),
            subtitle: Text('Status: ${delivery['status']}'),
          );
        },
      ),
    );
  }
}
```

## Database Tables Used

### orders
- Tracks order status changes
- Contains customer, store, and driver information
- Status field: pending, confirmed, preparing, ready, picked_up, in_transit, delivered, cancelled

### driver_location_history
- Stores driver location updates during delivery
- Linked to delivery_id for tracking specific deliveries
- Contains latitude, longitude, accuracy, speed, and heading

### deliveries
- Links orders to drivers
- Tracks delivery status: assigned, accepted, arriving_pickup, at_pickup, picked_up, in_transit, arriving_delivery, delivered, failed

## Supabase Realtime Subscriptions

The implementation uses Supabase's PostgreSQL Change Data Capture (CDC) to listen for database changes:

```dart
// Subscribe to order status changes
_client
  .channel('order_status_$orderId')
  .onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'orders',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: orderId,
    ),
    callback: (payload) {
      // Handle order update
    },
  )
  .subscribe();
```

## Twilio SMS Notifications

The edge function `send-booking-notification` handles SMS notifications via Twilio WhatsApp:

**Supported notification types:**
- `order_status_update`: Customer order status changes
- `merchant_new_order`: New order alerts for merchants
- `driver_delivery_assignment`: New delivery assignments for drivers
- `service_booking_update`: Service booking updates

**Environment variables required:**
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_WHATSAPP_NUMBER`

## Best Practices

1. **Always unsubscribe**: Call `unsubscribe()` in the `dispose()` method to prevent memory leaks
2. **Handle errors gracefully**: Display user-friendly error messages
3. **Show loading states**: Indicate when data is being fetched
4. **Optimize subscriptions**: Only subscribe to data you need
5. **Test thoroughly**: Test all real-time scenarios including network interruptions

## Troubleshooting

### Subscriptions not working
- Ensure Supabase Realtime is enabled for your tables
- Check that RLS policies allow the user to read the data
- Verify the filter conditions match your data

### SMS not sending
- Verify Twilio credentials are correct
- Check that the phone number format is correct (E.164 format)
- Ensure the Twilio WhatsApp number is approved

### Memory leaks
- Always call `unsubscribe()` in `dispose()`
- Don't create multiple subscriptions for the same data
- Use `ChangeNotifierProvider` with proper disposal
