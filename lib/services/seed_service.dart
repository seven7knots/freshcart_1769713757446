import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class SeedService {
  static final _client = SupabaseService.client;
  static const String _seedVersion = 'v1.0.0';

  /// Check if demo data is properly seeded by verifying actual row counts
  static Future<bool> isDemoDataSeeded() async {
    try {
      // Check app_settings for seed version
      final seedVersionRecord = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'demo_seed_version')
          .maybeSingle();

      if (seedVersionRecord == null) {
        debugPrint('[SEED] No demo_seed_version found in app_settings');
        return false;
      }

      // Verify actual row counts in core tables
      final productCount = await _client.from('products').count();

      final storeCount = await _client.from('stores').count();

      final categoryCount = await _client.from('categories').count();

      final hasMinimumData =
          productCount >= 20 && storeCount >= 4 && categoryCount >= 7;

      debugPrint(
          '[SEED] Row counts - Products: $productCount, Stores: $storeCount, Categories: $categoryCount');
      debugPrint('[SEED] Has minimum data: $hasMinimumData');

      return hasMinimumData;
    } catch (e) {
      debugPrint('[SEED] Error checking seed status: $e');
      return false;
    }
  }

  /// Get summary counts of all seeded data
  static Future<Map<String, int>> getSummaryCounts() async {
    try {
      final users = await _client.from('users').count();

      final stores = await _client.from('stores').count();

      final products = await _client.from('products').count();

      final categories = await _client.from('categories').count();

      final listings = await _client.from('marketplace_listings').count();

      final orders = await _client.from('orders').count();

      final conversations = await _client.from('conversations').count();

      final messages = await _client.from('messages').count();

      return {
        'users': users,
        'stores': stores,
        'products': products,
        'categories': categories,
        'listings': listings,
        'orders': orders,
        'conversations': conversations,
        'messages': messages,
      };
    } catch (e) {
      debugPrint('[SEED] Error getting summary counts: $e');
      return {};
    }
  }

  /// Reset demo data by deleting demo-tagged rows
  static Future<Map<String, dynamic>> resetDemoData() async {
    try {
      debugPrint('[SEED] Starting demo data reset via RPC...');

      // Call the RPC function with authenticated session
      final response = await _client.rpc('reset_demo_data');

      debugPrint('[SEED] ✓ RPC reset_demo_data() completed');
      debugPrint('[SEED] Response: $response');

      // Parse the returned JSON counts
      final counts = response as Map<String, dynamic>? ?? {};

      return {
        'success': true,
        'message': 'Demo data reset successfully via RPC',
        'counts': counts,
      };
    } on PostgrestException catch (e) {
      final errorMsg = 'RPC reset failed: ${e.message} (Code: ${e.code})';
      debugPrint('[SEED] ❌ PostgrestException: $errorMsg');
      return {
        'success': false,
        'message': errorMsg,
        'errorDetails': e.details ?? '',
      };
    } catch (e) {
      final errorMsg = 'RPC reset failed: $e';
      debugPrint('[SEED] ❌ Error: $errorMsg');
      return {
        'success': false,
        'message': errorMsg,
        'errorDetails': e.toString(),
      };
    }
  }

  /// Idempotent seeding routine - safe to run multiple times
  static Future<Map<String, dynamic>> seedDemoData() async {
    try {
      debugPrint('[SEED] Starting demo data seeding...');

      // Check if already properly seeded
      final alreadySeeded = await isDemoDataSeeded();
      if (alreadySeeded) {
        debugPrint(
            '[SEED] Demo data already seeded with minimum rows. Skipping...');
        final counts = await getSummaryCounts();
        return {
          'success': true,
          'message':
              'Demo data already seeded. Core tables have expected minimum rows.',
          'counts': counts,
        };
      }

      // 1. Seed Users (with auth.users entries)
      final userIds = await _seedUsers();
      debugPrint('[SEED] ✓ Users seeded: ${userIds.length}');

      // 2. Seed Categories
      final categoryIds = await _seedCategories();
      debugPrint('[SEED] ✓ Categories seeded: ${categoryIds.length}');

      // 3. Seed Stores
      final storeIds = await _seedStores(userIds);
      debugPrint('[SEED] ✓ Stores seeded: ${storeIds.length}');

      // 4. Seed Products
      final productIds = await _seedProducts(storeIds, categoryIds);
      debugPrint('[SEED] ✓ Products seeded: ${productIds.length}');

      // 5. Seed Marketplace Listings
      final listingIds = await _seedMarketplaceListings(userIds, categoryIds);
      debugPrint('[SEED] ✓ Marketplace listings seeded: ${listingIds.length}');

      // 6. Seed Ads
      await _seedAds(storeIds, productIds);
      debugPrint('[SEED] ✓ Ads seeded');

      // 7. Seed Orders
      final orderIds = await _seedOrders(userIds, storeIds, productIds);
      debugPrint('[SEED] ✓ Orders seeded: ${orderIds.length}');

      // 8. Seed Conversations & Messages
      await _seedConversationsAndMessages(userIds, listingIds);
      debugPrint('[SEED] ✓ Conversations & messages seeded');

      // 9. Mark as seeded in app_settings
      await _client.from('app_settings').upsert({
        'key': 'demo_seed_version',
        'value': _seedVersion,
        'description': 'Demo data seed version tracker',
      });
      debugPrint('[SEED] ✓ Seed version marker set');

      // Get final counts
      final counts = await getSummaryCounts();

      debugPrint('[SEED] ✅ All demo data seeded successfully!');
      return {
        'success': true,
        'message':
            'Demo data seeded successfully! All screens now have content.',
        'counts': counts,
      };
    } on PostgrestException catch (e) {
      final errorMsg =
          'Seeding failed: ${e.message} (Code: ${e.code}, Details: ${e.details})';
      debugPrint('[SEED] ❌ PostgrestException: $errorMsg');
      return {
        'success': false,
        'message': errorMsg,
        'error': e.message,
        'errorCode': e.code,
        'errorDetails': e.details,
      };
    } catch (e, stackTrace) {
      final errorMsg = 'Seeding failed: $e';
      debugPrint('[SEED] ❌ Error: $errorMsg');
      debugPrint('[SEED] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': errorMsg,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, String>> _seedUsers() async {
    final userIds = <String, String>{};

    // Admin user
    final adminAuthId = await _createAuthUser(
      'admin@sevenknots.com',
      'Admin123!',
    );
    await _client.from('users').upsert({
      'id': adminAuthId,
      'email': 'admin@sevenknots.com',
      'phone': '+9611234567',
      'full_name': 'Admin User',
      'role': 'admin',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 1000.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
      'is_demo': true,
    }, onConflict: 'email');
    userIds['admin'] = adminAuthId;

    // Customer 1
    final customer1Id = await _createAuthUser(
      'customer1@demo.com',
      'Customer123!',
    );
    await _client.from('users').upsert({
      'id': customer1Id,
      'email': 'customer1@demo.com',
      'phone': '+9611234501',
      'full_name': 'Sarah Johnson',
      'role': 'customer',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 250.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      'default_address': 'Beirut Central District, Lebanon',
      'location_lat': 33.8938,
      'location_lng': 35.5018,
      'is_demo': true,
    }, onConflict: 'email');
    userIds['customer1'] = customer1Id;

    // Customer 2
    final customer2Id = await _createAuthUser(
      'customer2@demo.com',
      'Customer123!',
    );
    await _client.from('users').upsert({
      'id': customer2Id,
      'email': 'customer2@demo.com',
      'phone': '+9611234502',
      'full_name': 'Michael Chen',
      'role': 'customer',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 180.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1507003211169-00dcc994a43e?w=400',
      'default_address': 'Hamra Street, Beirut, Lebanon',
      'location_lat': 33.8959,
      'location_lng': 35.4826,
      'is_demo': true,
    }, onConflict: 'email');
    userIds['customer2'] = customer2Id;

    // Driver 1
    final driver1Id = await _createAuthUser(
      'driver1@demo.com',
      'Driver123!',
    );
    await _client.from('users').upsert({
      'id': driver1Id,
      'email': 'driver1@demo.com',
      'phone': '+9611234503',
      'full_name': 'Ahmed Hassan',
      'role': 'driver',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 450.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      'is_demo': true,
    }, onConflict: 'email');
    userIds['driver1'] = driver1Id;

    // Driver 2
    final driver2Id = await _createAuthUser(
      'driver2@demo.com',
      'Driver123!',
    );
    await _client.from('users').upsert({
      'id': driver2Id,
      'email': 'driver2@demo.com',
      'phone': '+9611234504',
      'full_name': 'Karim Nasser',
      'role': 'driver',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 320.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      'is_demo': true,
    }, onConflict: 'email');
    userIds['driver2'] = driver2Id;

    // Merchant 1
    final merchant1Id = await _createAuthUser(
      'merchant1@demo.com',
      'Merchant123!',
    );
    await _client.from('users').upsert({
      'id': merchant1Id,
      'email': 'merchant1@demo.com',
      'phone': '+9611234505',
      'full_name': 'Restaurant Owner Ali',
      'role': 'merchant',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 2500.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      'is_demo': true,
    }, onConflict: 'email');
    userIds['merchant1'] = merchant1Id;

    // Merchant 2
    final merchant2Id = await _createAuthUser(
      'merchant2@demo.com',
      'Merchant123!',
    );
    await _client.from('users').upsert({
      'id': merchant2Id,
      'email': 'merchant2@demo.com',
      'phone': '+9611234506',
      'full_name': 'Grocery Store Manager',
      'role': 'merchant',
      'is_verified': true,
      'email_verified': true,
      'phone_verified': true,
      'wallet_balance': 1800.00,
      'profile_image_url':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400',
      'is_demo': true,
    }, onConflict: 'email');
    userIds['merchant2'] = merchant2Id;

    return userIds;
  }

  static Future<String> _createAuthUser(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.user!.id;
    } catch (e) {
      // User might already exist, try to get ID
      debugPrint('[SEED] Auth user creation skipped for $email: $e');
      final existing = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }
      rethrow;
    }
  }

  static Future<Map<String, String>> _seedCategories() async {
    final categories = [
      {
        'name': 'Food & Dining',
        'name_ar': 'الطعام والمطاعم',
        'type': 'product',
        'icon': 'restaurant',
        'sort_order': 1
      },
      {
        'name': 'Groceries',
        'name_ar': 'البقالة',
        'type': 'product',
        'icon': 'shopping_cart',
        'sort_order': 2
      },
      {
        'name': 'Pharmacy',
        'name_ar': 'الصيدلية',
        'type': 'product',
        'icon': 'local_pharmacy',
        'sort_order': 3
      },
      {
        'name': 'Electronics',
        'name_ar': 'الإلكترونيات',
        'type': 'marketplace',
        'icon': 'devices',
        'sort_order': 4
      },
      {
        'name': 'Furniture',
        'name_ar': 'الأثاث',
        'type': 'marketplace',
        'icon': 'chair',
        'sort_order': 5
      },
      {
        'name': 'Cleaning Services',
        'name_ar': 'خدمات التنظيف',
        'type': 'service',
        'icon': 'cleaning_services',
        'sort_order': 6
      },
      {
        'name': 'Home Repair',
        'name_ar': 'إصلاح المنازل',
        'type': 'service',
        'icon': 'build',
        'sort_order': 7
      },
    ];

    final result = await _client.from('categories').insert(categories).select();
    final categoryIds = <String, String>{};
    for (var i = 0; i < result.length; i++) {
      categoryIds[categories[i]['name'] as String] = result[i]['id'] as String;
    }
    return categoryIds;
  }

  static Future<Map<String, String>> _seedStores(
      Map<String, String> userIds) async {
    final stores = [
      {
        'merchant_id': userIds['merchant1'],
        'name': 'Mediterranean Delights',
        'name_ar': 'مأكولات البحر المتوسط',
        'category': 'food',
        'description': 'Authentic Lebanese and Mediterranean cuisine',
        'image_url':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        'banner_url':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200',
        'address': 'Verdun Street, Beirut',
        'location_lat': 33.8704,
        'location_lng': 35.4826,
        'is_featured': true,
        'minimum_order': 15.00,
        'average_prep_time_minutes': 25,
        'is_demo': true,
      },
      {
        'merchant_id': userIds['merchant1'],
        'name': 'Quick Bites Cafe',
        'name_ar': 'مقهى الوجبات السريعة',
        'category': 'food',
        'description': 'Fast food and sandwiches',
        'image_url':
            'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=800',
        'banner_url':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200',
        'address': 'Hamra, Beirut',
        'location_lat': 33.8959,
        'location_lng': 35.4826,
        'is_featured': false,
        'minimum_order': 10.00,
        'average_prep_time_minutes': 15,
        'is_demo': true,
      },
      {
        'merchant_id': userIds['merchant2'],
        'name': 'Fresh Market Grocery',
        'name_ar': 'سوق الطازج',
        'category': 'grocery',
        'description': 'Fresh produce and daily essentials',
        'image_url':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
        'banner_url':
            'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200',
        'address': 'Achrafieh, Beirut',
        'location_lat': 33.8886,
        'location_lng': 35.5157,
        'is_featured': true,
        'minimum_order': 20.00,
        'average_prep_time_minutes': 30,
        'is_demo': true,
      },
      {
        'merchant_id': userIds['merchant2'],
        'name': 'Health Plus Pharmacy',
        'name_ar': 'صيدلية هيلث بلس',
        'category': 'pharmacy',
        'description': 'Medications and health products',
        'image_url':
            'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800',
        'banner_url':
            'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=1200',
        'address': 'Raouche, Beirut',
        'location_lat': 33.8938,
        'location_lng': 35.4782,
        'is_featured': false,
        'minimum_order': 5.00,
        'average_prep_time_minutes': 20,
        'is_demo': true,
      },
    ];

    final result = await _client.from('stores').insert(stores).select();
    final storeIds = <String, String>{};
    for (var i = 0; i < result.length; i++) {
      storeIds[stores[i]['name'] as String] = result[i]['id'] as String;
    }
    return storeIds;
  }

  static Future<List<String>> _seedProducts(
      Map<String, String> storeIds, Map<String, String> categoryIds) async {
    final products = [
      // Mediterranean Delights products
      {
        'store_id': storeIds['Mediterranean Delights'],
        'name': 'Chicken Shawarma Plate',
        'name_ar': 'صحن شاورما دجاج',
        'description': 'Grilled chicken with garlic sauce, pickles, and fries',
        'price': 12.50,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=600',
        'is_featured': true,
        'stock_quantity': 50,
      },
      {
        'store_id': storeIds['Mediterranean Delights'],
        'name': 'Falafel Wrap',
        'name_ar': 'لفة فلافل',
        'description': 'Crispy falafel with tahini and vegetables',
        'price': 6.00,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',
        'is_featured': false,
        'stock_quantity': 80,
      },
      {
        'store_id': storeIds['Mediterranean Delights'],
        'name': 'Hummus Bowl',
        'name_ar': 'صحن حمص',
        'description': 'Creamy hummus with olive oil and pita bread',
        'price': 5.50,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1595587637401-f8f5e1e3c9b7?w=600',
        'stock_quantity': 60,
      },
      {
        'store_id': storeIds['Mediterranean Delights'],
        'name': 'Mixed Grill Platter',
        'name_ar': 'صحن مشاوي مشكلة',
        'description': 'Lamb, chicken, and kafta with grilled vegetables',
        'price': 22.00,
        'sale_price': 19.00,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=600',
        'is_featured': true,
        'stock_quantity': 30,
      },
      {
        'store_id': storeIds['Mediterranean Delights'],
        'name': 'Tabbouleh Salad',
        'name_ar': 'سلطة تبولة',
        'description': 'Fresh parsley salad with tomatoes and bulgur',
        'price': 7.00,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
        'stock_quantity': 40,
      },
      // Quick Bites products
      {
        'store_id': storeIds['Quick Bites Cafe'],
        'name': 'Beef Burger',
        'name_ar': 'برغر لحم',
        'description': 'Juicy beef patty with cheese and special sauce',
        'price': 9.00,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
        'is_featured': true,
        'stock_quantity': 70,
      },
      {
        'store_id': storeIds['Quick Bites Cafe'],
        'name': 'Chicken Caesar Salad',
        'name_ar': 'سلطة سيزر بالدجاج',
        'description': 'Grilled chicken with romaine and parmesan',
        'price': 8.50,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=600',
        'stock_quantity': 50,
      },
      {
        'store_id': storeIds['Quick Bites Cafe'],
        'name': 'French Fries',
        'name_ar': 'بطاطا مقلية',
        'description': 'Crispy golden fries',
        'price': 3.50,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600',
        'stock_quantity': 100,
      },
      {
        'store_id': storeIds['Quick Bites Cafe'],
        'name': 'Iced Coffee',
        'name_ar': 'قهوة مثلجة',
        'description': 'Cold brew with milk',
        'price': 4.00,
        'category': 'Food & Dining',
        'image_url':
            'https://images.unsplash.com/photo-1517487881594-2787fef5ebf7?w=600',
        'stock_quantity': 90,
      },
      // Fresh Market products
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Fresh Tomatoes (1kg)',
        'name_ar': 'طماطم طازجة (١ كغ)',
        'description': 'Locally grown ripe tomatoes',
        'price': 2.50,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=600',
        'stock_quantity': 200,
      },
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Organic Bananas (1kg)',
        'name_ar': 'موز عضوي (١ كغ)',
        'description': 'Fresh organic bananas',
        'price': 3.00,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600',
        'stock_quantity': 150,
      },
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Fresh Milk (1L)',
        'name_ar': 'حليب طازج (١ لتر)',
        'description': 'Full cream fresh milk',
        'price': 2.00,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=600',
        'stock_quantity': 100,
      },
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Whole Wheat Bread',
        'name_ar': 'خبز قمح كامل',
        'description': 'Freshly baked whole wheat bread',
        'price': 1.50,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
        'stock_quantity': 80,
      },
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Free Range Eggs (12pcs)',
        'name_ar': 'بيض طبيعي (١٢ حبة)',
        'description': 'Farm fresh free range eggs',
        'price': 4.50,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=600',
        'stock_quantity': 120,
      },
      {
        'store_id': storeIds['Fresh Market Grocery'],
        'name': 'Olive Oil (500ml)',
        'name_ar': 'زيت زيتون (٥٠٠ مل)',
        'description': 'Extra virgin olive oil',
        'price': 8.00,
        'category': 'Groceries',
        'image_url':
            'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600',
        'stock_quantity': 60,
      },
      // Health Plus Pharmacy products
      {
        'store_id': storeIds['Health Plus Pharmacy'],
        'name': 'Paracetamol 500mg',
        'name_ar': 'باراسيتامول ٥٠٠ ملغ',
        'description': 'Pain relief and fever reducer',
        'price': 3.00,
        'category': 'Pharmacy',
        'image_url':
            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600',
        'stock_quantity': 200,
      },
      {
        'store_id': storeIds['Health Plus Pharmacy'],
        'name': 'Vitamin C Tablets',
        'name_ar': 'أقراص فيتامين سي',
        'description': 'Immune system support',
        'price': 5.50,
        'category': 'Pharmacy',
        'image_url':
            'https://images.unsplash.com/photo-1550572017-4950f8b9e0f6?w=600',
        'stock_quantity': 150,
      },
      {
        'store_id': storeIds['Health Plus Pharmacy'],
        'name': 'First Aid Kit',
        'name_ar': 'حقيبة إسعافات أولية',
        'description': 'Complete first aid supplies',
        'price': 15.00,
        'category': 'Pharmacy',
        'image_url':
            'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=600',
        'stock_quantity': 50,
      },
      {
        'store_id': storeIds['Health Plus Pharmacy'],
        'name': 'Hand Sanitizer (250ml)',
        'name_ar': 'معقم يدين (٢٥٠ مل)',
        'description': 'Antibacterial hand sanitizer',
        'price': 4.00,
        'category': 'Pharmacy',
        'image_url':
            'https://images.unsplash.com/photo-1584744982491-665216d95f8b?w=600',
        'stock_quantity': 180,
      },
      {
        'store_id': storeIds['Health Plus Pharmacy'],
        'name': 'Face Masks (50pcs)',
        'name_ar': 'كمامات وجه (٥٠ حبة)',
        'description': 'Disposable protective face masks',
        'price': 6.00,
        'category': 'Pharmacy',
        'image_url':
            'https://images.unsplash.com/photo-1584634731339-252c581abfc5?w=600',
        'stock_quantity': 100,
      },
    ];

    // Add is_demo flag to all products
    for (var product in products) {
      product['is_demo'] = true;
    }

    final result = await _client.from('products').insert(products).select();
    return result.map((p) => p['id'] as String).toList();
  }

  static Future<List<String>> _seedMarketplaceListings(
      Map<String, String> userIds, Map<String, String> categoryIds) async {
    final listings = [
      {
        'user_id': userIds['customer1'],
        'title': 'iPhone 13 Pro - Like New',
        'description':
            'Barely used iPhone 13 Pro, 256GB, Pacific Blue. Includes original box and accessories.',
        'listing_type': 'product',
        'category': 'Electronics',
        'price': 850.00,
        'is_negotiable': true,
        'condition': 'like_new',
        'location': 'Beirut Central District',
        'location_lat': 33.8938,
        'location_lng': 35.5018,
        'images': [
          'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=600'
        ],
      },
      {
        'user_id': userIds['customer2'],
        'title': 'Modern Sofa Set - 3 Seater',
        'description':
            'Comfortable grey fabric sofa in excellent condition. Moving sale.',
        'listing_type': 'product',
        'category': 'Furniture',
        'price': 450.00,
        'is_negotiable': true,
        'condition': 'good',
        'location': 'Hamra, Beirut',
        'location_lat': 33.8959,
        'location_lng': 35.4826,
        'images': [
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600'
        ],
      },
      {
        'user_id': userIds['customer1'],
        'title': 'Professional House Cleaning',
        'description':
            'Experienced cleaner offering deep cleaning services. Eco-friendly products.',
        'listing_type': 'service',
        'category': 'Cleaning Services',
        'price': 30.00,
        'is_negotiable': false,
        'location': 'Beirut Area',
        'location_lat': 33.8938,
        'location_lng': 35.5018,
        'images': [
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600'
        ],
      },
      {
        'user_id': userIds['merchant1'],
        'title': 'MacBook Pro 2021 M1',
        'description':
            '14-inch MacBook Pro with M1 Pro chip, 16GB RAM, 512GB SSD. Perfect condition.',
        'listing_type': 'product',
        'category': 'Electronics',
        'price': 1800.00,
        'is_negotiable': true,
        'condition': 'excellent',
        'location': 'Verdun, Beirut',
        'location_lat': 33.8704,
        'location_lng': 35.4826,
        'images': [
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600'
        ],
      },
      {
        'user_id': userIds['customer2'],
        'title': 'Plumbing & Repair Services',
        'description':
            'Licensed plumber available for all home repair needs. 10+ years experience.',
        'listing_type': 'service',
        'category': 'Home Repair',
        'price': 40.00,
        'is_negotiable': false,
        'location': 'Greater Beirut',
        'location_lat': 33.8886,
        'location_lng': 35.5157,
        'images': [
          'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=600'
        ],
      },
      {
        'user_id': userIds['merchant2'],
        'title': 'Dining Table with 6 Chairs',
        'description':
            'Solid wood dining set in great condition. Table extends to seat 8.',
        'listing_type': 'product',
        'category': 'Furniture',
        'price': 600.00,
        'is_negotiable': true,
        'condition': 'good',
        'location': 'Achrafieh, Beirut',
        'location_lat': 33.8886,
        'location_lng': 35.5157,
        'images': [
          'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=600'
        ],
      },
      {
        'user_id': userIds['customer1'],
        'title': 'Samsung 55" 4K Smart TV',
        'description':
            'Crystal UHD 4K TV with HDR. Excellent picture quality, barely used.',
        'listing_type': 'product',
        'category': 'Electronics',
        'price': 550.00,
        'is_negotiable': true,
        'condition': 'like_new',
        'location': 'Beirut',
        'location_lat': 33.8938,
        'location_lng': 35.5018,
        'images': [
          'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=600'
        ],
      },
      {
        'user_id': userIds['merchant1'],
        'title': 'Electrician Services',
        'description':
            'Certified electrician for installations, repairs, and maintenance.',
        'listing_type': 'service',
        'category': 'Home Repair',
        'price': 35.00,
        'is_negotiable': false,
        'location': 'Beirut & Suburbs',
        'location_lat': 33.8704,
        'location_lng': 35.4826,
        'images': [
          'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=600'
        ],
      },
      {
        'user_id': userIds['customer2'],
        'title': 'Office Desk & Chair Set',
        'description':
            'Ergonomic office furniture. Desk with drawers and adjustable chair.',
        'listing_type': 'product',
        'category': 'Furniture',
        'price': 280.00,
        'is_negotiable': true,
        'condition': 'good',
        'location': 'Hamra',
        'location_lat': 33.8959,
        'location_lng': 35.4826,
        'images': [
          'https://images.unsplash.com/photo-1595515106969-1ce29566ff1c?w=600'
        ],
      },
      {
        'user_id': userIds['merchant2'],
        'title': 'Deep Cleaning & Sanitization',
        'description':
            'Professional deep cleaning service for homes and offices. COVID-safe.',
        'listing_type': 'service',
        'category': 'Cleaning Services',
        'price': 50.00,
        'is_negotiable': false,
        'location': 'All Beirut',
        'location_lat': 33.8886,
        'location_lng': 35.5157,
        'images': [
          'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=600'
        ],
      },
    ];

    // Add is_demo flag to all listings
    for (var listing in listings) {
      listing['is_demo'] = true;
    }

    final result =
        await _client.from('marketplace_listings').insert(listings).select();
    return result.map((l) => l['id'] as String).toList();
  }

  static Future<void> _seedAds(
      Map<String, String> storeIds, List<String> productIds) async {
    final ads = [
      {
        'title': 'Grand Opening Sale!',
        'description': 'Get 20% off on all items this week',
        'ad_type': 'banner',
        'target_type': 'store',
        'target_id': storeIds['Mediterranean Delights'],
        'image_url':
            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200',
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
        'priority': 1,
      },
      {
        'title': 'Fresh Groceries Daily',
        'description': 'Farm to table in 24 hours',
        'ad_type': 'carousel',
        'target_type': 'store',
        'target_id': storeIds['Fresh Market Grocery'],
        'image_url':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200',
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
        'priority': 2,
      },
      {
        'title': 'Health & Wellness',
        'description': 'Your trusted pharmacy partner',
        'ad_type': 'banner',
        'target_type': 'store',
        'target_id': storeIds['Health Plus Pharmacy'],
        'image_url':
            'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=1200',
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
        'priority': 3,
      },
      {
        'title': 'Quick Bites Special',
        'description': 'Lunch combo deals starting at \$8',
        'ad_type': 'popup',
        'target_type': 'store',
        'target_id': storeIds['Quick Bites Cafe'],
        'image_url':
            'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=1200',
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'is_active': true,
        'priority': 4,
      },
      {
        'title': 'Featured Products',
        'description': 'Discover our top picks',
        'ad_type': 'carousel',
        'target_type': 'product',
        'target_id': productIds.isNotEmpty ? productIds[0] : null,
        'image_url':
            'https://images.unsplash.com/photo-1505935428862-770b6f24f629?w=1200',
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_active': true,
        'priority': 5,
      },
    ];

    await _client.from('ads').insert(ads);
  }

  static Future<List<String>> _seedOrders(Map<String, String> userIds,
      Map<String, String> storeIds, List<String> productIds) async {
    final orders = [
      {
        'customer_id': userIds['customer1'],
        'store_id': storeIds['Mediterranean Delights'],
        'driver_id': userIds['driver1'],
        'status': 'delivered',
        'subtotal': 25.50,
        'delivery_fee': 3.00,
        'total_amount': 28.50,
        'delivery_address': 'Beirut Central District, Lebanon',
        'delivery_lat': 33.8938,
        'delivery_lng': 35.5018,
        'payment_method': 'cash',
        'payment_status': 'paid',
        'notes': 'Please ring doorbell',
      },
      {
        'customer_id': userIds['customer2'],
        'store_id': storeIds['Quick Bites Cafe'],
        'driver_id': userIds['driver2'],
        'status': 'in_transit',
        'subtotal': 17.50,
        'delivery_fee': 2.50,
        'total_amount': 20.00,
        'delivery_address': 'Hamra Street, Beirut, Lebanon',
        'delivery_lat': 33.8959,
        'delivery_lng': 35.4826,
        'payment_method': 'card',
        'payment_status': 'paid',
      },
      {
        'customer_id': userIds['customer1'],
        'store_id': storeIds['Fresh Market Grocery'],
        'driver_id': userIds['driver1'],
        'status': 'preparing',
        'subtotal': 32.00,
        'delivery_fee': 4.00,
        'total_amount': 36.00,
        'delivery_address': 'Beirut Central District, Lebanon',
        'delivery_lat': 33.8938,
        'delivery_lng': 35.5018,
        'payment_method': 'wallet',
        'payment_status': 'paid',
      },
      {
        'customer_id': userIds['customer2'],
        'store_id': storeIds['Health Plus Pharmacy'],
        'status': 'pending',
        'subtotal': 12.50,
        'delivery_fee': 2.00,
        'total_amount': 14.50,
        'delivery_address': 'Hamra Street, Beirut, Lebanon',
        'delivery_lat': 33.8959,
        'delivery_lng': 35.4826,
        'payment_method': 'cash',
        'payment_status': 'pending',
      },
      {
        'customer_id': userIds['customer1'],
        'store_id': storeIds['Mediterranean Delights'],
        'driver_id': userIds['driver2'],
        'status': 'picked_up',
        'subtotal': 41.00,
        'delivery_fee': 3.50,
        'total_amount': 44.50,
        'delivery_address': 'Beirut Central District, Lebanon',
        'delivery_lat': 33.8938,
        'delivery_lng': 35.5018,
        'payment_method': 'card',
        'payment_status': 'paid',
        'notes': 'Extra napkins please',
      },
    ];

    final result = await _client.from('orders').insert(orders).select();
    final orderIds = result.map((o) => o['id'] as String).toList();

    // Seed order items for each order
    for (var i = 0; i < orderIds.length && i < productIds.length; i++) {
      await _client.from('order_items').insert([
        {
          'order_id': orderIds[i],
          'product_id': productIds[i * 2 % productIds.length],
          'quantity': 2,
          'unit_price': 12.50,
          'subtotal': 25.00,
        },
        if (productIds.length > i * 2 + 1)
          {
            'order_id': orderIds[i],
            'product_id': productIds[i * 2 + 1],
            'quantity': 1,
            'unit_price': 8.50,
            'subtotal': 8.50,
          },
      ]);
    }

    return orderIds;
  }

  static Future<void> _seedConversationsAndMessages(
      Map<String, String> userIds, List<String> listingIds) async {
    final conversations = [
      {
        'listing_id': listingIds.isNotEmpty ? listingIds[0] : null,
        'buyer_id': userIds['customer2'],
        'seller_id': userIds['customer1'],
        'last_message': 'Is this still available?',
      },
      {
        'listing_id': listingIds.length > 1 ? listingIds[1] : null,
        'buyer_id': userIds['customer1'],
        'seller_id': userIds['customer2'],
        'last_message': 'Can you deliver to Achrafieh?',
      },
      {
        'listing_id': listingIds.length > 2 ? listingIds[2] : null,
        'buyer_id': userIds['merchant1'],
        'seller_id': userIds['customer1'],
        'last_message': 'What areas do you service?',
      },
    ];

    final result =
        await _client.from('conversations').insert(conversations).select();

    // Seed messages for each conversation
    for (var i = 0; i < result.length; i++) {
      final conv = result[i];
      await _client.from('messages').insert([
        {
          'conversation_id': conv['id'],
          'sender_id': conv['buyer_id'],
          'content': conversations[i]['last_message'],
          'is_read': true,
        },
        {
          'conversation_id': conv['id'],
          'sender_id': conv['seller_id'],
          'content': 'Yes, it is! Feel free to ask any questions.',
          'is_read': false,
        },
      ]);
    }
  }
}
