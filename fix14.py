import re

path = r'C:\dev\kj_delivery_fresh\lib\services\location_service.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = '''  /// Reverse geocode lat/lng → formatted address string
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': googleApiKey,
          'language': 'en',
        },
        options: _androidOptions,
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['formatted_address'] as String? ?? 'Unknown';
        }
      }
      return 'Unknown location';
    } catch (e) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
  }'''

new = '''  /// Reverse geocode lat/lng → formatted address string
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final key = googleApiKey;
      debugPrint('[GEOCODE] reverseGeocode called: $lat, $lng');
      debugPrint('[GEOCODE] API key present: ${key.isNotEmpty} (length=${key.length})');
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': key,
          'language': 'en',
        },
        options: _androidOptions,
      );

      debugPrint('[GEOCODE] status: ${response.statusCode}');
      debugPrint('[GEOCODE] status field: ${response.data['status']}');
      if (response.statusCode == 200) {
        final status = response.data['status'] as String?;
        if (status != 'OK') {
          debugPrint('[GEOCODE] ERROR status: $status  error_message: ${response.data['error_message']}');
          return 'Unknown location';
        }
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final addr = results[0]['formatted_address'] as String? ?? 'Unknown';
          debugPrint('[GEOCODE] Success: $addr');
          return addr;
        }
      }
      debugPrint('[GEOCODE] No results returned');
      return 'Unknown location';
    } catch (e) {
      debugPrint('[GEOCODE] Exception: $e');
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
  }'''

if old in content:
    content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('fix14.py applied successfully')
else:
    print('ERROR: old block not found - check for encoding/whitespace differences')
