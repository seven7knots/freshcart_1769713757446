// ============================================================
// FILE: lib/services/supabase_service.dart
// ============================================================
// FIXED:
// - Changed default bucket from 'images' to 'uploads'
// - uploadImageBytes now uses subfolder path: {folder}/{userId}/{timestamp}.{ext}
//   This matches the RLS policies that check storage.foldername(name)
// - Added explicit contentType for proper MIME handling
// ============================================================

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
  static bool get isLoggedIn => currentUser != null;

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.kjdelivery.app://callback/',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================================
  // STORES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getStores({String? categoryId}) async {
    var query = client.from('stores').select(
      '*, '
      'category:categories!stores_category_id_fkey(name), '
      'subcategory:categories!stores_subcategory_id_fkey(name)',
    );
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    final res = await query.order('created_at', ascending: false);
    return _asListOfMaps(res);
  }

  static Future<Map<String, dynamic>?> createStore({
    required String name,
    required String categoryId,
    String? description,
    String? imageUrl,
    String? merchantId,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'owner_user_id': uid,
      if (merchantId != null) 'merchant_id': merchantId,
      'is_active': true,
      'is_demo': false,
      'is_accepting_orders': true,
    }..removeWhere((k, v) => v == null);

    final res = await client
        .from('stores')
        .insert(payload)
        .select(
          '*, '
          'category:categories!stores_category_id_fkey(name), '
          'subcategory:categories!stores_subcategory_id_fkey(name)',
        )
        .single();

    return Map<String, dynamic>.from(res);
  }

  static Future<void> deleteStore(String storeId) async {
    await client.from('stores').delete().eq('id', storeId);
  }

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

    if (updates.isEmpty) return null;

    updates['updated_at'] = DateTime.now().toIso8601String();

    final res = await client
        .from('stores')
        .update(updates)
        .eq('id', storeId)
        .select(
          '*, '
          'category:categories!stores_category_id_fkey(name), '
          'subcategory:categories!stores_subcategory_id_fkey(name)',
        )
        .single();

    return Map<String, dynamic>.from(res);
  }

  static Future<List<Map<String, dynamic>>> getStoresByCategory(String categoryId) async {
    final res = await client
        .from('stores')
        .select(
          '*, '
          'category:categories!stores_category_id_fkey(name), '
          'subcategory:categories!stores_subcategory_id_fkey(name)',
        )
        .eq('category_id', categoryId)
        .order('name');

    return _asListOfMaps(res);
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getProducts({String? storeId}) async {
    var query = client.from('products').select('*, stores(name)');
    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }
    final res = await query.order('created_at', ascending: false);
    return _asListOfMaps(res);
  }

  static Future<Map<String, dynamic>?> createProduct({
    required String name,
    required String storeId,
    double? price,
    String? imageUrl,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'store_id': storeId,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'is_active': true,
    }..removeWhere((k, v) => v == null);

    final res = await client.from('products').insert(payload).select().single();
    return Map<String, dynamic>.from(res);
  }

  static Future<void> deleteProduct(String productId) async {
    await client.from('products').delete().eq('id', productId);
  }

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

    if (updates.isEmpty) return null;

    updates['updated_at'] = DateTime.now().toIso8601String();

    final res = await client
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select('*, stores(name)')
        .single();

    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await client.from('categories').select().order('name');
    return _asListOfMaps(res);
  }

  // ============================================================
  // CAROUSEL ADS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getCarouselAds() async {
    final res = await client
        .from('carousel_ads')
        .select('*, stores(name)')
        .order('position');

    return _asListOfMaps(res);
  }

  static Future<Map<String, dynamic>?> createCarouselAd({
    required String title,
    required String imageUrl,
    String? storeId,
    String? linkUrl,
    int position = 0,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'image_url': imageUrl,
      'store_id': storeId,
      'link_url': linkUrl,
      'position': position,
    }..removeWhere((k, v) => v == null);

    final res = await client
        .from('carousel_ads')
        .insert(payload)
        .select('*, stores(name)')
        .single();

    return Map<String, dynamic>.from(res);
  }

  static Future<void> deleteCarouselAd(String adId) async {
    await client.from('carousel_ads').delete().eq('id', adId);
  }

  // ============================================================
  // MERCHANTS (ADMIN/INFO)
  // ============================================================

  static Future<List<Map<String, dynamic>>> getMerchants() async {
    final res = await client
        .from('merchants')
        .select('*, users(email, full_name)')
        .order('created_at', ascending: false);

    return _asListOfMaps(res);
  }

  // ============================================================
  // STORAGE UPLOADS
  // ============================================================

  /// Upload bytes to Supabase Storage.
  ///
  /// FIXED:
  /// - Default bucket changed from 'images' to 'uploads'
  /// - Now uses subfolder path: {folder}/{userId}/{timestamp}.{ext}
  ///   This matches the RLS policies that check storage.foldername(name)
  /// - Added explicit contentType for proper MIME handling
  static Future<String> uploadImageBytes(
    Uint8List bytes, {
    String bucket = 'uploads',
    String? folder,
    String? extension,
    String? contentType,
  }) async {
    final ext = (extension ?? 'jpg').replaceAll('.', '').toLowerCase();
    final uid = currentUser?.id ?? 'anon';
    final ts = DateTime.now().millisecondsSinceEpoch;

    // Map extension to proper MIME type
    String mimeType;
    switch (ext) {
      case 'jpg': case 'jpeg': mimeType = 'image/jpeg';
      case 'png': mimeType = 'image/png';
      case 'gif': mimeType = 'image/gif';
      case 'webp': mimeType = 'image/webp';
      default: mimeType = 'image/jpeg';
    }

    // Use subfolder path: folder/userId/timestamp.ext
    final effectiveFolder = folder ?? 'general';
    final fileName = '$effectiveFolder/$uid/$ts.$ext';

    debugPrint('[SUPABASE_UPLOAD] Bucket: $bucket, Path: $fileName, Size: ${bytes.length}, MIME: $mimeType');

    await client.storage.from(bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType ?? mimeType,
          ),
        );

    final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);
    debugPrint('[SUPABASE_UPLOAD] ✅ Public URL: $publicUrl');
    return publicUrl;
  }

  /// Delete a stored object by path
  static Future<void> deleteImage(String bucket, String fileName) async {
    await client.storage.from(bucket).remove([fileName]);
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

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

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  static List<Map<String, dynamic>> _asListOfMaps(dynamic res) {
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }
}