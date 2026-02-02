# KJ Delivery - Supabase Integration Guide

## Overview

This Flutter application is now fully integrated with your existing Supabase database containing 40+ tables for a comprehensive delivery platform.

## Database Schema

Your Supabase database includes:

### Core Tables
- **users** - Customer/merchant/driver/admin accounts
- **user_addresses** - Multiple saved addresses per user
- **stores** - Store locations with categories and operating hours
- **products** - Items for sale with prices, images, stock
- **orders** - Order tracking with status management
- **order_items** - Individual items in each order
- **order_status_history** - Complete timeline of order changes

### Delivery System
- **drivers** - Driver profiles with vehicle info and documents
- **deliveries** - Delivery assignments with tracking
- **driver_location_history** - Real-time GPS tracking
- **driver_earnings** - Driver income tracking

### Payment System
- **wallets** - User wallet balances
- **transactions** - All financial transactions
- **payment_gateway_logs** - Payment attempt logging
- **withdrawal_requests** - Driver/merchant payout requests
- **merchant_settlements** - Merchant payment periods

### Subscription System
- **subscription_plans** - Available plans (Free, Basic, Premium)
- **subscriptions** - User subscription status

### Promotions & Marketing
- **promo_codes** - Discount codes with rules
- **ad_campaigns** - Merchant advertising
- **qr_codes** - Scannable codes for promotions
- **push_campaigns** - Mass notification campaigns
- **referrals** - User referral tracking

### Services Marketplace
- **services** - Non-delivery services (taxi, towing, etc.)
- **service_bookings** - Service reservations

### User Marketplace
- **marketplace_listings** - User-to-user selling
- **marketplace_messages** - Buyer-seller communication

### Notifications & AI
- **notifications** - In-app notifications
- **ai_logs** - AI interaction logging
- **meal_plans** - AI-generated meal plans
- **ai_recommendations** - System suggestions

### System Tables
- **system_settings** - App configuration
- **audit_logs** - Admin action tracking
- **delivery_zones** - Geographic delivery areas

## Generated Models

All models are created using **Freezed** for immutability and **json_serializable** for JSON conversion:

### Core Models
- `UserModel` - lib/models/user_model.dart
- `StoreModel` - lib/models/store_model.dart
- `ProductModel` - lib/models/product_model.dart
- `OrderModel` - lib/models/order_model.dart
- `OrderItemModel` - lib/models/order_item_model.dart

### Delivery Models
- `DriverModel` - lib/models/driver_model.dart
- `DeliveryModel` - lib/models/delivery_model.dart

### Payment Models
- `WalletModel` - lib/models/wallet_model.dart
- `TransactionModel` - lib/models/transaction_model.dart

### Other Models
- `SubscriptionPlanModel` - lib/models/subscription_plan_model.dart
- `PromoCodeModel` - lib/models/promo_code_model.dart
- `NotificationModel` - lib/models/notification_model.dart

## Service Classes

All services provide CRUD operations for their respective tables:

### UserService (lib/services/user_service.dart)
```dart
- getCurrentUserProfile() - Get current user data
- getUserById(userId) - Get user by ID
- updateUserProfile(...) - Update user profile
- getWalletBalance() - Get user wallet balance
```

### StoreService (lib/services/store_service.dart)
```dart
- getAllStores() - Get all active stores
- getStoreById(storeId) - Get store details
- searchStores(query) - Search stores
- getStoresByCategory(category) - Filter by category
```

### ProductService (lib/services/product_service.dart)
```dart
- getProductsByStore(storeId) - Get products for a store
- getProductById(productId) - Get product details
- searchProducts(query) - Search products
- getFeaturedProducts() - Get featured products
- getProductByBarcode(barcode) - Scan barcode
```

### OrderService (lib/services/order_service.dart)
```dart
- createOrder(...) - Create new order
- getOrderById(orderId) - Get order with items
- getUserOrders() - Get user's order history
- updateOrderStatus(orderId, status) - Update order
- cancelOrder(orderId, reason) - Cancel order
- getActiveOrder() - Get current active order
```

### WalletService (lib/services/wallet_service.dart)
```dart
- getUserWallet() - Get wallet details
- getWalletBalance() - Get current balance
- getTransactionHistory() - Get transaction list
- topUpWallet(amount) - Add funds (requires payment gateway)
```

### DatabaseService (lib/services/database_service.dart)
```dart
- getCartItems() - Get user's cart
- addToCart(...) - Add product to cart
- updateCartItemQuantity(itemId, quantity) - Update quantity
- removeCartItem(itemId) - Remove from cart
- clearCart() - Clear all cart items
- getCartItemCount() - Get cart count
- createOrder(...) - Create order from cart
```

## Riverpod Providers

State management using Riverpod:

### User Providers (lib/providers/user_provider.dart)
```dart
currentUserProvider - FutureProvider<UserModel?>
walletBalanceProvider - FutureProvider<double>
```

### Store Providers (lib/providers/store_provider.dart)
```dart
allStoresProvider - FutureProvider<List<StoreModel>>
featuredStoresProvider - FutureProvider<List<StoreModel>>
storeByIdProvider - FutureProvider.family<StoreModel?, String>
storesByCategoryProvider - FutureProvider.family<List<StoreModel>, String>
```

### Product Providers (lib/providers/product_provider.dart)
```dart
productsByStoreProvider - FutureProvider.family<List<ProductModel>, String>
productByIdProvider - FutureProvider.family<ProductModel?, String>
featuredProductsProvider - FutureProvider<List<ProductModel>>
```

### Order Providers (lib/providers/order_provider.dart)
```dart
userOrdersProvider - FutureProvider<List<Map<String, dynamic>>>
activeOrderProvider - FutureProvider<Map<String, dynamic>?>
orderByIdProvider - FutureProvider.family<Map<String, dynamic>, String>
```

### Wallet Providers (lib/providers/wallet_provider.dart)
```dart
userWalletProvider - FutureProvider<WalletModel?>
transactionHistoryProvider - FutureProvider<List<TransactionModel>>
```

## Usage Examples

### 1. Display User Profile
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return Text('Not logged in');
        return Column(
          children: [
            Text(user.fullName ?? 'No name'),
            Text(user.email ?? 'No email'),
            Text('Balance: \$${user.walletBalance}'),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 2. Display Stores List
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_provider.dart';

class StoresListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(allStoresProvider);

    return storesAsync.when(
      data: (stores) => ListView.builder(
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return ListTile(
            leading: store.imageUrl != null
                ? Image.network(store.imageUrl!)
                : Icon(Icons.store),
            title: Text(store.name),
            subtitle: Text(store.category ?? ''),
            trailing: Text('${store.rating}/5'),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 3. Display Products for a Store
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';

class ProductsScreen extends ConsumerWidget {
  final String storeId;

  const ProductsScreen({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByStoreProvider(storeId));

    return productsAsync.when(
      data: (products) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: Column(
              children: [
                if (product.imageUrl != null)
                  Image.network(product.imageUrl!),
                Text(product.name),
                Text('\$${product.salePrice ?? product.price}'),
                ElevatedButton(
                  onPressed: () {
                    // Add to cart logic
                  },
                  child: Text('Add to Cart'),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 4. Create Order
```dart
import '../services/order_service.dart';

Future<void> placeOrder(BuildContext context, WidgetRef ref) async {
  final orderService = ref.read(orderServiceProvider);

  try {
    final order = await orderService.createOrder(
      storeId: 'store-id',
      deliveryAddress: '123 Main St',
      deliveryLat: 33.8886,
      deliveryLng: 35.4955,
      subtotal: 50.0,
      deliveryFee: 5.0,
      serviceFee: 2.0,
      tax: 3.0,
      total: 60.0,
      items: [
        {
          'product_id': 'product-id',
          'product_name': 'Pizza',
          'quantity': 2,
          'unit_price': 25.0,
          'total_price': 50.0,
        },
      ],
      paymentMethod: 'cash',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed: ${order.orderNumber}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to place order: $e')),
    );
  }
}
```

### 5. Display Order History
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return ordersAsync.when(
      data: (orders) => ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final store = order['stores'] as Map<String, dynamic>?;
          final items = order['order_items'] as List<dynamic>;

          return Card(
            child: ListTile(
              title: Text(store?['name'] ?? 'Unknown Store'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order['order_number']}'),
                  Text('Status: ${order['status']}'),
                  Text('Total: \$${order['total']}'),
                  Text('Items: ${items.length}'),
                ],
              ),
              trailing: Text(order['status']),
            ),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## Payment Methods

The system supports three payment methods:

1. **Cash on Delivery** - Fully functional
2. **Wallet Payment** - Deducts from user's wallet balance
3. **Card Payment** - Placeholder (requires payment gateway configuration)

## Code Generation

After creating or modifying models, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `.freezed.dart` files for immutable models
- `.g.dart` files for JSON serialization

## Next Steps

### To Complete Integration:

1. **Run Code Generation**:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Update Existing Screens**:
   - Replace mock data with Riverpod providers
   - Use service classes for data operations
   - Implement proper loading and error states

3. **Add Real-Time Features**:
   - Order status updates
   - Driver location tracking
   - Live notifications

4. **Configure Payment Gateway**:
   - Integrate payment provider (Stripe, PayPal, etc.)
   - Update WalletService.topUpWallet()
   - Implement card payment flow

5. **Add Additional Models** (as needed):
   - MerchantModel
   - ServiceModel
   - MarketplaceListingModel
   - etc.

## Database Schema Reference

All tables use:
- **snake_case** in database (e.g., `user_id`, `created_at`)
- **camelCase** in Dart models (e.g., `userId`, `createdAt`)

JSON serialization automatically handles the conversion using `@JsonKey(name: 'snake_case_name')`.

## Country & Currency

- **Country**: Lebanon (LB)
- **Primary Currency**: USD
- All monetary values use USD by default

## Support

For issues or questions about the Supabase integration:
1. Check the Supabase dashboard for table structures
2. Review RLS policies for permission issues
3. Check browser console for API errors
4. Verify environment variables are set correctly