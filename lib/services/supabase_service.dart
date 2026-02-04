import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not configured.');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => client.auth.currentUser != null;

  // Note: AuthProvider is the authoritative role source (users.role).
  static bool get isAdmin =>
      client.auth.currentUser?.appMetadata['role'] == 'admin';

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.freshcart.app://callback/',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<List<Map<String, dynamic>>> getStores(
      {String? categoryId}) async {
    final query = client.from('stores').select('*, categories(name)');
    if (categoryId != null) query.eq('category_id', categoryId);
    return await query.order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>?> createStore({
    required String name,
    required String categoryId,
    String? description,
    String? imageUrl,
    required String ownerId,
  }) async {
    return await client.from('stores').insert({
      'name': name,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'owner_id': ownerId,
    }).select('*, categories(name)').single();
  }

  static Future<void> deleteStore(String storeId) async =>
      await client.from('stores').delete().eq('id', storeId);

  static Future<Map<String, dynamic>?> updateStore(
    String storeId, {
    String? name,
    String? categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (description != null) updates['description'] = description;
    if (imageUrl != null) updates['image_url'] = imageUrl;

    return await client
        .from('stores')
        .update(updates)
        .eq('id', storeId)
        .select('*, categories(name)')
        .single();
  }

  static Future<List<Map<String, dynamic>>> getProducts({String? storeId}) async {
    final query = client.from('products').select('*, stores(name)');
    if (storeId != null) query.eq('store_id', storeId);
    return await query.order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>?> createProduct({
    required String name,
    required String storeId,
    double? price,
    String? imageUrl,
    String? description,
  }) async {
    return await client.from('products').insert({
      'name': name,
      'store_id': storeId,
      'price': price,
      'image_url': imageUrl,
      'description': description,
    }).select('*, stores(name)').single();
  }

  static Future<void> deleteProduct(String productId) async =>
      await client.from('products').delete().eq('id', productId);

  static Future<Map<String, dynamic>?> updateProduct(
    String productId, {
    String? name,
    double? price,
    String? imageUrl,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (price != null) updates['price'] = price;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (description != null) updates['description'] = description;

    return await client
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select('*, stores(name)')
        .single();
  }

  static Future<List<Map<String, dynamic>>> getCategories() async =>
      await client.from('categories').select().order('name');

  static Future<List<Map<String, dynamic>>> getStoresByCategory(
          String categoryId) async =>
      await client
          .from('stores')
          .select('*, categories(name)')
          .eq('category_id', categoryId)
          .order('name');

  static Future<List<Map<String, dynamic>>> getCarouselAds() async =>
      await client.from('carousel_ads').select('*, stores(name)').order('position');

  static Future<Map<String, dynamic>?> createCarouselAd({
    required String title,
    required String imageUrl,
    String? storeId,
    String? linkUrl,
    int position = 0,
  }) async {
    return await client.from('carousel_ads').insert({
      'title': title,
      'image_url': imageUrl,
      'store_id': storeId,
      'linkUrl': linkUrl,
      'position': position,
    }).select('*, stores(name)').single();
  }

  static Future<void> deleteCarouselAd(String adId) async =>
      await client.from('carousel_ads').delete().eq('id', adId);

  static Future<List<Map<String, dynamic>>> getMerchants() async => await client
      .from('merchants')
      .select('*, profiles(email)')
      .order('created_at', ascending: false);

  static Future<String> uploadImage(File file, {String folder = 'images'}) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await client.storage.from(folder).upload(fileName, file);
    return client.storage.from(folder).getPublicUrl(fileName);
  }

  static Future<void> deleteImage(String folder, String fileName) async {
    await client.storage.from(folder).remove([fileName]);
  }

  static Future<String> runtimeHealthCheck() async {
    try {
      final sb = Supabase.instance.client;
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      debugPrint('[SB-RT] Client ready. URL=$supabaseUrl');
      final data = await sb.from('merchants').select('id,user_id').limit(1);
      final list = data as List;
      debugPrint('[SB-RT] ✅ Query OK. merchants rows fetched=${list.length}');
      return '[SB-RT] ✅ Supabase connected!\nURL: $supabaseUrl\nQuery OK: ${list.length} row(s) fetched';
    } on PostgrestException catch (e) {
      debugPrint(
          '[SB-RT] ❌ PostgREST error: code=${e.code} message=${e.message} details=${e.details}');
      return '[SB-RT] ❌ PostgREST Error\nCode: ${e.code}\nMessage: ${e.message}';
    } on AuthException catch (e) {
      debugPrint('[SB-RT] ❌ Auth error: ${e.message}');
      return '[SB-RT] ❌ Auth Error\n${e.message}';
    } catch (e) {
      debugPrint('[SB-RT] ❌ Unknown error: $e');
      return '[SB-RT] ❌ Unknown Error\n$e';
    }
  }
}
