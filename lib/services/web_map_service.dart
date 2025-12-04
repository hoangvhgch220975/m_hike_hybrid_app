// lib/services/web_map_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for handling integration with Web-based map (Leaflet map from GitHub Pages)
///
/// This service is responsible for parsing and validating data from
/// the JavaScript channel of the WebView map.
class WebMapService {
  /// Parse location data from JavaScript message
  ///
  /// [message] - Raw JSON string from MapPickerChannel
  ///
  /// Returns: Map containing location data or null if parsing fails
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "lat": 21.028511,
  ///   "lon": 105.804817,
  ///   "name": "Hanoi, Vietnam",
  ///   "distance": 5.23
  /// }
  /// ```
  Map<String, dynamic>? parseMapPickerMessage(String message) {
    try {
      final data = json.decode(message);

      // Validate required fields
      if (!data.containsKey('lat') || !data.containsKey('lon')) {
        print('❌ Missing required fields: lat or lon');
        return null;
      }

      // Parse và validate latitude
      final lat = _parseCoordinate(data['lat'], 'latitude');
      if (lat == null) return null;

      // Parse và validate longitude
      final lon = _parseCoordinate(data['lon'], 'longitude');
      if (lon == null) return null;

      // Parse name
      final name = data['name']?.toString() ?? '';

      // Parse distance (optional)
      double? distance;
      if (data['distance'] != null) {
        if (data['distance'] is String) {
          distance = double.tryParse(data['distance'].toString());
        } else if (data['distance'] is num) {
          distance = (data['distance'] as num).toDouble();
        }
      }

      return {
        'latitude': lat,
        'longitude': lon,
        'location': name.isNotEmpty ? name : 'Unknown Location',
        'distance': distance,
      };
    } catch (e) {
      print('❌ Error parsing map picker message: $e');
      return null;
    }
  }

  /// Parse coordinate value (lat or lon)
  double? _parseCoordinate(dynamic value, String type) {
    try {
      double coord;

      if (value is num) {
        coord = value.toDouble();
      } else if (value is String) {
        coord = double.parse(value);
      } else {
        print('❌ Invalid $type type: ${value.runtimeType}');
        return null;
      }

      // Validate range
      if (type == 'latitude') {
        if (coord < -90 || coord > 90) {
          print('❌ Latitude out of range: $coord');
          return null;
        }
      } else if (type == 'longitude') {
        if (coord < -180 || coord > 180) {
          print('❌ Longitude out of range: $coord');
          return null;
        }
      }

      return coord;
    } catch (e) {
      print('❌ Error parsing $type: $e');
      return null;
    }
  }

  /// Validate location data completeness
  ///
  /// Check whether location data contains all required fields
  bool validateLocationData(Map<String, dynamic> data) {
    if (!data.containsKey('latitude') || data['latitude'] == null) {
      return false;
    }
    if (!data.containsKey('longitude') || data['longitude'] == null) {
      return false;
    }
    if (!data.containsKey('location') || data['location'] == null) {
      return false;
    }
    return true;
  }

  /// Format distance value
  ///
  /// Round distance to 2 decimal places
  String formatDistance(double? distance) {
    if (distance == null) return '0.00';
    return distance.toStringAsFixed(2);
  }

  /// Create JavaScript payload to send to map
  ///
  /// Use when need to send data from Flutter to JavaScript map
  /// (example: set initial location)
  String createMapPayload({
    required double lat,
    required double lon,
    String? name,
  }) {
    final payload = {
      'lat': lat,
      'lon': lon,
      if (name != null) 'name': name,
    };
    return json.encode(payload);
  }

  /// Log received data for debugging
  void logReceivedData(Map<String, dynamic> data) {
    print('📦 [WEB MAP] Received location data:');
    print('   Latitude: ${data['latitude']}');
    print('   Longitude: ${data['longitude']}');
    print('   Location: ${data['location']}');
    print('   Distance: ${data['distance'] ?? 'N/A'} km');
  }

  /// Check if map URL is valid
  bool isValidMapUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get default map URL (fallback)
  String getDefaultMapUrl() {
    return dotenv.env['WEB_MAP_URL'] ?? 'https://hoangvhgch220975.github.io/map_only/';
  }
}

