import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AdsService {
  final SupabaseClient _client = SupabaseService.client;

  // ========== AD MANAGEMENT ==========

  Future<List<Map<String, dynamic>>> getActiveAdsForContext({
    String targetType = 'global_home',
    String? targetId,
  }) async {
    try {
      final response = await _client.rpc('get_active_ads_for_context', params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get active ads: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAds({
    String? status,
    String? format,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('ads').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (format != null) {
        query = query.eq('format', format);
      }

      final response =
          await query.order('display_order').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all ads: $e');
    }
  }

  Future<Map<String, dynamic>?> getAdById(String adId) async {
    try {
      final response =
          await _client.from('ads').select().eq('id', adId).maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to get ad: $e');
    }
  }

  Future<Map<String, dynamic>> createAd({
    required String title,
    String? description,
    required String format,
    required String imageUrl,
    List<String>? images,
    required String linkType,
    String? linkTargetId,
    String? externalUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool isRecurring = false,
    List<int>? recurringDays,
    int displayOrder = 0,
    int autoPlayInterval = 4000,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('ads')
          .insert({
            'title': title,
            'description': description,
            'format': format,
            'status': 'draft',
            'image_url': imageUrl,
            'images': images ?? [],
            'link_type': linkType,
            'link_target_id': linkTargetId,
            'external_url': externalUrl,
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'is_recurring': isRecurring,
            'recurring_days': recurringDays ?? [],
            'display_order': displayOrder,
            'auto_play_interval': autoPlayInterval,
            'created_by': userId,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create ad: $e');
    }
  }

  Future<Map<String, dynamic>> updateAd(
    String adId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('ads')
          .update(updates)
          .eq('id', adId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update ad: $e');
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      await _client.from('ads').delete().eq('id', adId);
    } catch (e) {
      throw Exception('Failed to delete ad: $e');
    }
  }

  Future<void> updateAdStatus(String adId, String status) async {
    try {
      await _client.from('ads').update({'status': status}).eq('id', adId);
    } catch (e) {
      throw Exception('Failed to update ad status: $e');
    }
  }

  Future<void> bulkUpdateAdStatus(List<String> adIds, String status) async {
    try {
      await _client.from('ads').update({'status': status}).inFilter('id', adIds);
    } catch (e) {
      throw Exception('Failed to bulk update ad status: $e');
    }
  }

  // Optional helper for reorder UI
  Future<void> updateAdDisplayOrder(String adId, int displayOrder) async {
    try {
      await _client.from('ads').update({'display_order': displayOrder}).eq(
            'id',
            adId,
          );
    } catch (e) {
      throw Exception('Failed to update ad display order: $e');
    }
  }

  // ========== TARGETING RULES ==========

  Future<List<Map<String, dynamic>>> getTargetingRules(String adId) async {
    try {
      final response =
          await _client.from('ad_targeting_rules').select().eq('ad_id', adId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get targeting rules: $e');
    }
  }

  Future<Map<String, dynamic>> addTargetingRule({
    required String adId,
    required String targetType,
    String? targetId,
    List<String>? userRoles,
    int? minOrderCount,
    double? locationRadiusKm,
  }) async {
    try {
      final response = await _client
          .from('ad_targeting_rules')
          .insert({
            'ad_id': adId,
            'target_type': targetType,
            'target_id': targetId,
            'user_roles': userRoles ?? [],
            'min_order_count': minOrderCount,
            'location_radius_km': locationRadiusKm,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add targeting rule: $e');
    }
  }

  Future<void> deleteTargetingRule(String ruleId) async {
    try {
      await _client.from('ad_targeting_rules').delete().eq('id', ruleId);
    } catch (e) {
      throw Exception('Failed to delete targeting rule: $e');
    }
  }

  Future<void> deleteAllTargetingRules(String adId) async {
    try {
      await _client.from('ad_targeting_rules').delete().eq('ad_id', adId);
    } catch (e) {
      throw Exception('Failed to delete targeting rules: $e');
    }
  }

  // ========== ANALYTICS ==========

  Future<void> trackImpression(String adId, {String? contextPage}) async {
    try {
      await _client.rpc('track_ad_impression', params: {
        'p_ad_id': adId,
        'p_context_page': contextPage,
      });
    } catch (_) {
      // Silent fail for analytics
    }
  }

  Future<void> trackClick(String adId, {String? contextPage}) async {
    try {
      await _client.rpc('track_ad_click', params: {
        'p_ad_id': adId,
        'p_context_page': contextPage,
      });
    } catch (_) {
      // Silent fail for analytics
    }
  }

  Future<List<Map<String, dynamic>>> getAnalyticsSummary({
    String? adId,
    int days = 30,
  }) async {
    try {
      final response = await _client.rpc('get_ad_analytics_summary', params: {
        'p_ad_id': adId,
        'p_days': days,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get analytics summary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDetailedAnalytics({
    required String adId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('ad_analytics').select().eq('ad_id', adId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get detailed analytics: $e');
    }
  }

  // ========== IMAGE UPLOAD ==========

  Future<String> uploadAdImage(File file) async {
    if (kIsWeb) {
      throw UnsupportedError('uploadAdImage(File) is not supported on web.');
    }

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await _client.storage.from('ads-images').upload(fileName, file);

      return _client.storage.from('ads-images').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload ad image: $e');
    }
  }

  Future<List<String>> uploadAdImages(List<File> files) async {
    if (kIsWeb) {
      throw UnsupportedError('uploadAdImages(List<File>) is not supported on web.');
    }

    try {
      final urls = <String>[];
      for (final file in files) {
        final url = await uploadAdImage(file);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload ad images: $e');
    }
  }

  /// Deletes an object from the `ads-images` bucket using its PUBLIC URL.
  /// This fixes the bug where only the last segment was removed (which fails when
  /// the object path is `userId/filename`).
  Future<void> deleteAdImage(String imageUrl) async {
    try {
      final objectPath = _extractStorageObjectPathFromPublicUrl(
        imageUrl,
        bucket: 'ads-images',
      );

      if (objectPath == null || objectPath.isEmpty) {
        throw Exception('Could not resolve storage object path from imageUrl');
      }

      await _client.storage.from('ads-images').remove([objectPath]);
    } catch (e) {
      throw Exception('Failed to delete ad image: $e');
    }
  }

  String? _extractStorageObjectPathFromPublicUrl(
    String publicUrl, {
    required String bucket,
  }) {
    try {
      final uri = Uri.parse(publicUrl);

      // Supabase public URL pattern:
      // .../storage/v1/object/public/<bucket>/<objectPath>
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1) return null;

      final objectSegments = segments.sublist(bucketIndex + 1);
      if (objectSegments.isEmpty) return null;

      return objectSegments.join('/');
    } catch (_) {
      return null;
    }
  }
}
