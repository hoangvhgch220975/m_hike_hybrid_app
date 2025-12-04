// lib/services/map_service.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for handling operations related to Google Maps and Geocoding
class MapService {
  GoogleMapController? _mapController;

  /// Store Google Maps controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Get current map controller
  GoogleMapController? get mapController => _mapController;

  /// Move camera to specific location
  Future<void> moveCamera(LatLng target, {double zoom = 14.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
      );
    }
  }

  /// Calculate distance between two points (Haversine formula)
  /// Returns distance in kilometers
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // km

    final double lat1 = start.latitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double dLat = (end.latitude - start.latitude) * pi / 180;
    final double dLon = (end.longitude - start.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get formatted distance string
  String getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(2)} km';
    }
  }

  // ============================================================================
  // GEOCODING & ROUTING API
  // ============================================================================

  /// Reverse Geocoding: Get location name from coordinates
  ///
  /// Use Nominatim API (OpenStreetMap) to convert
  /// coordinates (lat, lon) into detailed location name.
  ///
  /// [lat] - Latitude
  /// [lon] - Longitude
  ///
  /// Returns: Location name or null if failed
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MHikeApp/1.0', // Nominatim requires User-Agent
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      } else {
        print('❌ Reverse geocoding failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in reverseGeocode: $e');
      return null;
    }
  }

  /// Forward Geocoding: Search location by name
  ///
  /// Use Nominatim API to search for locations
  /// matching the query string.
  ///
  /// [query] - Search string (location name, address)
  /// [limit] - Maximum number of results (default: 10)
  ///
  /// Returns: List of found locations
  Future<List<Map<String, dynamic>>> searchLocation(
    String query, {
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=$limit',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MHikeApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
            'display_name': item['display_name'] as String,
            'type': item['type'] as String?,
            'importance': item['importance'] as double?,
          };
        }).toList();
      } else {
        print('❌ Location search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error in searchLocation: $e');
      return [];
    }
  }

  /// Calculate Route Distance: Calculate route distance between 2 points
  ///
  /// Use OSRM API (Open Source Routing Machine) to calculate
  /// actual route distance (following roads) between 2 points.
  ///
  /// [startLat] - Starting point latitude
  /// [startLon] - Starting point longitude
  /// [endLat] - Ending point latitude
  /// [endLon] - Ending point longitude
  /// [profile] - Route type: 'foot-walking', 'driving-car', 'cycling-regular'
  ///
  /// Returns: Map containing distance (km), duration (minutes), and geometry
  Future<Map<String, dynamic>?> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String profile = 'foot-walking',
  }) async {
    try {
      // Use OSRM public API
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          return {
            'distance': (route['distance'] as num) / 1000.0, // Convert to km
            'duration': (route['duration'] as num) / 60.0, // Convert to minutes
            'geometry': route['geometry'],
            'legs': route['legs'],
          };
        } else {
          print('❌ Route calculation failed: ${data['code']}');
          return null;
        }
      } else {
        print('❌ OSRM API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in calculateRoute: $e');
      return null;
    }
  }

  /// Get Route Polyline Points: Get list of points for polyline
  ///
  /// Parse geometry from route response to draw polyline on map
  ///
  /// [geometry] - GeoJSON geometry from OSRM response
  ///
  /// Returns: List of LatLng points
  List<LatLng> parseRouteGeometry(Map<String, dynamic> geometry) {
    try {
      if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
        final List<dynamic> coordinates = geometry['coordinates'];
        return coordinates.map((coord) {
          return LatLng(
            coord[1] as double, // lat
            coord[0] as double, // lon
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error parsing geometry: $e');
      return [];
    }
  }

  /// Batch Reverse Geocoding: Get names for multiple coordinates
  ///
  /// Use when need to reverse geocode multiple points at once.
  ///
  /// [positions] - List of coordinates to reverse geocode
  /// [delay] - Delay between requests (milliseconds) to avoid rate limit
  ///
  /// Returns: Map with key as "lat,lon" and value as display_name
  Future<Map<String, String>> batchReverseGeocode(
    List<LatLng> positions, {
    int delay = 1000,
  }) async {
    final results = <String, String>{};

    for (final pos in positions) {
      final key = '${pos.latitude},${pos.longitude}';
      final name = await reverseGeocode(pos.latitude, pos.longitude);

      if (name != null) {
        results[key] = name;
      }

      // Delay to avoid rate limiting
      if (delay > 0 && positions.indexOf(pos) < positions.length - 1) {
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    return results;
  }

  /// Validate and Format Location Name
  ///
  /// Normalize location name, remove unnecessary characters
  ///
  /// [locationName] - Location name to format
  /// [maxLength] - Maximum length (default: 100)
  ///
  /// Returns: Formatted location name
  String formatLocationName(String locationName, {int maxLength = 100}) {
    String formatted = locationName.trim();

    // Remove multiple spaces
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');

    // Truncate if too long
    if (formatted.length > maxLength) {
      formatted = '${formatted.substring(0, maxLength - 3)}...';
    }

    return formatted;
  }

  // ============================================================================
  // GOOGLE MAPS UI HELPERS
  // ============================================================================

  /// Create Marker: Create marker for Google Maps
  ///
  /// Helper method to create marker with basic attributes
  ///
  /// [markerId] - Unique ID for marker
  /// [position] - Marker position (LatLng)
  /// [title] - Title displayed when tapping marker
  /// [snippet] - Detailed description (optional)
  /// [icon] - Custom icon (optional, default is red marker)
  /// [infoWindow] - Custom InfoWindow (optional)
  ///
  /// Returns: Marker object
  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    InfoWindow? infoWindow,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: infoWindow ?? InfoWindow(
        title: title,
        snippet: snippet,
      ),
      onTap: onTap,
    );
  }

  /// Create Polyline: Create polyline for Google Maps
  ///
  /// Helper method to create polyline (connecting line between points)
  ///
  /// [polylineId] - Unique ID for polyline
  /// [points] - List of points forming the polyline
  /// [color] - Polyline color (default: blue)
  /// [width] - Line width (default: 5)
  /// [patterns] - Line pattern (optional, example: dotted, dashed)
  ///
  /// Returns: Polyline object
  Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = const Color(0xFF0000FF), // Blue
    int width = 5,
    List<PatternItem>? patterns,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      patterns: patterns ?? [], // Use empty list if null
    );
  }

  /// Create Circle: Create circle overlay on map
  ///
  /// Use to highlight a circular area on map
  ///
  /// [circleId] - Unique ID for circle
  /// [center] - Center of circle
  /// [radius] - Radius (meters)
  /// [fillColor] - Fill color (optional)
  /// [strokeColor] - Border color (optional)
  /// [strokeWidth] - Border width (optional)
  ///
  /// Returns: Circle object
  Circle createCircle({
    required String circleId,
    required LatLng center,
    required double radius,
    Color fillColor = const Color(0x330000FF),
    Color strokeColor = const Color(0xFF0000FF),
    int strokeWidth = 2,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Create Polygon: Create polygon on map
  ///
  /// Use to draw polygon area on map
  ///
  /// [polygonId] - Unique ID for polygon
  /// [points] - List of polygon corner points
  /// [fillColor] - Fill color (optional)
  /// [strokeColor] - Border color (optional)
  /// [strokeWidth] - Border width (optional)
  ///
  /// Returns: Polygon object
  Polygon createPolygon({
    required String polygonId,
    required List<LatLng> points,
    Color fillColor = const Color(0x3300FF00),
    Color strokeColor = const Color(0xFF00FF00),
    int strokeWidth = 2,
  }) {
    return Polygon(
      polygonId: PolygonId(polygonId),
      points: points,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Get Bounds: Calculate bounds for multiple points
  ///
  /// Use to fit camera to all markers
  ///
  /// [points] - List of points to include
  ///
  /// Returns: LatLngBounds
  LatLngBounds? getBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      // Single point - create small bounds around it
      final point = points[0];
      return LatLngBounds(
        southwest: LatLng(point.latitude - 0.001, point.longitude - 0.001),
        northeast: LatLng(point.latitude + 0.001, point.longitude + 0.001),
      );
    }

    double? minLat, maxLat, minLon, maxLon;

    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLon == null || point.longitude < minLon) minLon = point.longitude;
      if (maxLon == null || point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLon!),
      northeast: LatLng(maxLat!, maxLon!),
    );
  }

  /// Fit Bounds: Adjust camera to display all markers
  ///
  /// [bounds] - LatLngBounds to fit
  /// [padding] - Padding around (pixels)
  Future<void> fitBounds(LatLngBounds bounds, {double padding = 50}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    }
  }

  /// Dispose controller
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
  }
}

