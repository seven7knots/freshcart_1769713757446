import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL or SUPABASE_ANON_KEY not configured. '
        'Provide these environment variables at build time.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Runtime verification: tries to read 1 row from `public.merchants`.
  /// Returns a user-friendly status message for UI display.
  static Future<String> runtimeHealthCheck() async {
    try {
      final client = Supabase.instance.client;
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

      debugPrint('[SB-RT] Client ready. URL=$supabaseUrl');

      final data = await client.from('merchants').select('id,user_id').limit(1);

      final list = data as List;
      debugPrint('[SB-RT] ✅ Query OK. merchants rows fetched=${list.length}');
      if (list.isNotEmpty) {
        debugPrint('[SB-RT] First row => ${list.first}');
        return '[SB-RT] ✅ Supabase connected!\nURL: $supabaseUrl\nQuery OK: ${list.length} row(s) fetched';
      } else {
        debugPrint('[SB-RT] merchants table is empty (still OK).');
        return '[SB-RT] ✅ Supabase connected!\nURL: $supabaseUrl\nmerchants table is empty (OK)';
      }
    } on PostgrestException catch (e) {
      debugPrint(
        '[SB-RT] ❌ PostgREST error: code=${e.code} message=${e.message} details=${e.details}',
      );
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
