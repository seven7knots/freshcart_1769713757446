# KJ Delivery - Setup Instructions

## 🚨 CRITICAL: Code Generation Required

This project uses **Freezed** for data models. Before running the app, you MUST generate the required files.

### Step 1: Install Dependencies

```bash
flutter pub get
```

### Step 2: Generate Freezed Files

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This command will generate:
- `.freezed.dart` files for all models
- `.g.dart` files for JSON serialization

**Expected output**: 12 model files will be generated (24 new files total)

### Step 3: Run the App

```bash
flutter run
```

## What Was Created

### 📊 Data Models (Freezed)

All models are immutable and include JSON serialization:

- `UserModel` - User profiles with wallet balance
- `StoreModel` - Store information with ratings
- `ProductModel` - Products with pricing and stock
- `OrderModel` - Orders with status tracking
- `OrderItemModel` - Individual order items
- `DriverModel` - Driver profiles and vehicle info
- `DeliveryModel` - Delivery tracking
- `WalletModel` - User wallet
- `TransactionModel` - Financial transactions
- `SubscriptionPlanModel` - Subscription plans
- `PromoCodeModel` - Discount codes
- `NotificationModel` - In-app notifications

### 🔧 Service Classes

CRUD operations for all tables:

- `UserService` - User profile operations
- `StoreService` - Store management
- `ProductService` - Product catalog
- `OrderService` - Order creation and tracking
- `WalletService` - Wallet and transactions
- `DatabaseService` - Cart operations (enhanced)

### 🔄 Riverpod Providers

State management for:

- User data and wallet balance
- Stores (all, featured, by category)
- Products (by store, featured, search)
- Orders (history, active order)
- Wallet and transactions

## Database Schema

Your Supabase database has **40+ tables** including:

### Core
- users, user_addresses, stores, products, orders, order_items

### Delivery
- drivers, deliveries, driver_location_history, driver_earnings

### Payment
- wallets, transactions, payment_gateway_logs, withdrawal_requests

### Features
- subscriptions, promo_codes, notifications, services, marketplace

### AI & System
- ai_logs, meal_plans, system_settings, audit_logs

## Usage Examples

### Display User Profile

```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => Text(user?.fullName ?? 'Guest'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Display Stores

```dart
class StoresScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(allStoresProvider);

    return storesAsync.when(
      data: (stores) => ListView.builder(
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return ListTile(
            title: Text(store.name),
            subtitle: Text(store.category ?? ''),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Create Order

```dart
Future<void> placeOrder(WidgetRef ref) async {
  final orderService = ref.read(orderServiceProvider);

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
    items: [...],
    paymentMethod: 'cash', // or 'wallet' or 'card'
  );
}
```

## Payment Methods

1. **Cash on Delivery** - ✅ Fully functional
2. **Wallet Payment** - ✅ Deducts from user balance
3. **Card Payment** - ⏳ Placeholder (requires gateway)

## Country & Currency

- **Country**: Lebanon (LB)
- **Currency**: USD (primary)

## Next Steps

1. ✅ Run `flutter pub run build_runner build --delete-conflicting-outputs`
2. 🔄 Update existing screens to use Riverpod providers
3. 📡 Add real-time subscriptions for order tracking
4. 💳 Configure payment gateway for card payments
5. 📱 Add push notifications

## Documentation

See `SUPABASE_INTEGRATION.md` for:
- Complete API reference
- All available methods
- Detailed usage examples
- Database schema details

## Troubleshooting

### Build Errors

If you see errors about missing types:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Errors

All models, services, and providers are exported in `lib/core/app_export.dart`

### Database Errors

Check:
1. Supabase URL and keys in environment variables
2. RLS policies in Supabase dashboard
3. User authentication status

## Support

For issues:
1. Check Supabase dashboard for table structures
2. Review RLS policies
3. Check browser console for API errors
4. Verify environment variables