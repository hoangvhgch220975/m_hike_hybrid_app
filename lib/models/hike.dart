// lib/models/hike.dart

import 'observation.dart';

class Hike {
  int? id; // ID in database (can be null when newly created)
  String name;
  String location;
  String date; // Should be stored as String or int (timestamp)
  double length;
  String difficulty;
  String? description;
  bool isComplete; // Used for filtering Feed/Plan
  bool isRemarkable; // Used for filtering Remarkable
  bool hasParking; // New: Whether parking is available (yes/no)
  int? estimatedDuration; // New: Estimated days (duration in days) - nullable for backward compatibility
  double? latitude; // Latitude from map picker
  double? longitude; // Longitude from map picker
  bool isMapPicked; // Flag indicating if location was selected from map
  bool isLengthFromMap; // Flag indicating if length was calculated from map
  List<Observation> observations; // List of related observations

  Hike({
    this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.length,
    required this.difficulty,
    this.description,
    this.isComplete = false,
    this.isRemarkable = false,
    this.hasParking = false,
    this.estimatedDuration, // Can be null for old records
    this.latitude,
    this.longitude,
    this.isMapPicked = false,
    this.isLengthFromMap = false,
    this.observations = const [], // Initialize empty
  });

  // Convert Hike object to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'date': date,
      'length': length,
      'difficulty': difficulty,
      'description': description,
      // Store bool as int (1 for true, 0 for false) in SQLite
      'isComplete': isComplete ? 1 : 0,
      'isRemarkable': isRemarkable ? 1 : 0,
      'hasParking': hasParking ? 1 : 0,
      'estimatedDuration': estimatedDuration ?? 1, // Default to 1 if null
      'latitude': latitude,
      'longitude': longitude,
      'isMapPicked': isMapPicked ? 1 : 0,
    };
  }

  // Create a Hike object from SQLite Map
  factory Hike.fromMap(Map<String, dynamic> map) {
    // length in DB may be int or real; handle both
    double parsedLength = 0.0;
    try {
      if (map['length'] is num) {
        parsedLength = (map['length'] as num).toDouble();
      } else if (map['length'] != null) {
        parsedLength = double.tryParse(map['length'].toString()) ?? 0.0;
      }
    } catch (_) {
      parsedLength = 0.0;
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is int) return v == 1;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    // Parse estimatedDuration - return null if missing (backward compatibility)
    int? parsedDuration;
    try {
      if (map.containsKey('estimatedDuration') && map['estimatedDuration'] != null) {
        parsedDuration = map['estimatedDuration'] is int
            ? map['estimatedDuration'] as int
            : int.tryParse(map['estimatedDuration'].toString());
      }
    } catch (_) {
      parsedDuration = null;
    }

    // Parse latitude/longitude - nullable for backward compatibility
    double? parsedLat;
    double? parsedLon;
    try {
      if (map.containsKey('latitude') && map['latitude'] != null) {
        parsedLat = map['latitude'] is double
            ? map['latitude'] as double
            : double.tryParse(map['latitude'].toString());
      }
      if (map.containsKey('longitude') && map['longitude'] != null) {
        parsedLon = map['longitude'] is double
            ? map['longitude'] as double
            : double.tryParse(map['longitude'].toString());
      }
    } catch (_) {
      parsedLat = null;
      parsedLon = null;
    }

    return Hike(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String,
      date: map['date'] as String,
      length: parsedLength,
      difficulty: map['difficulty'] as String,
      description: map['description'] as String?,
      // Convert int to bool
      isComplete: parseBool(map['isComplete']),
      isRemarkable: parseBool(map['isRemarkable']),
      hasParking: parseBool(map['hasParking']),
      estimatedDuration: parsedDuration,
      latitude: parsedLat,
      longitude: parsedLon,
      isMapPicked: map.containsKey('isMapPicked') ? parseBool(map['isMapPicked']) : false,
      // observations will be injected later after loading from DB
      observations: [],
    );
  }
}
