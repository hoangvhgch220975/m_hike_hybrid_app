// lib/services/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/hike.dart';
import '../models/ai_suggestion.dart';
import '../models/weather_data.dart';
import '../db/app_db.dart';

/// Service for calling AI backend (Python FastAPI)
class AIService {
  // Load AI backend URL from environment variables
  // Backend runs at localhost:8000
  // Using 10.0.2.2 for Android Emulator (10.0.2.2 = host machine localhost)

  static String get _baseUrl => dotenv.env['AI_SERVICE_BASE_URL'] ?? 'http://10.0.2.2:8000';

  // Change URL in .env file depending on the device you are testing:
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator & Desktop: http://localhost:8000
  // Alternative localhost: http://127.0.0.1:8000
  // Real device: http://YOUR_COMPUTER_IP:8000 (replace with your computer IP)

  static const String _evaluateEndpoint = '/api/hike-ai/evaluate';

  /// Get AI suggestion for a hike
  /// If already exists in database, return the saved result
  /// If not exists, call API to create new one and save to database
  static Future<AISuggestion?> getOrGenerateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    // Check if AI suggestion already exists
    final existingSuggestion = await AppDatabase.instance.getAISuggestionByHikeId(hike.id!);
    if (existingSuggestion != null) {
      return existingSuggestion;
    }

    // If not exists, call API to create new one
    return await generateAISuggestion(hike);
  }

  /// Call API to create new AI suggestion
  static Future<AISuggestion?> generateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    try {
      // Fetch weather data from database
      final weatherMaps = await AppDatabase.instance.getWeatherForecastsByHike(hike.id!);
      final List<Map<String, dynamic>> weatherData = weatherMaps.map((map) {
        return {
          'temperature': map['temperature'],
          'condition': map['condition'],
          'description': map['description'],
          'humidity': map['humidity'],
          'windSpeed': map['windSpeed'],
          'icon': map['icon'],
          'forecastDate': map['forecastDate'],
        };
      }).toList();

      // Prepare request body
      final requestBody = {
        'id': hike.id,
        'name': hike.name,
        'location': hike.location,
        'date': hike.date,
        'length': hike.length,
        'difficulty': hike.difficulty,
        'description': hike.description ?? '',
        'hasParking': hike.hasParking,
        'estimatedDuration': hike.estimatedDuration ?? 1,
        'weather': weatherData,
      };

      // Call API
      final url = Uri.parse('$_baseUrl$_evaluateEndpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - AI service took too long to respond');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final suggestion = AISuggestion.fromJson(responseData, hike.id!);

        // Save to database
        final suggestionId = await AppDatabase.instance.insertAISuggestion(suggestion);
        return suggestion.copyWith(id: suggestionId);
      } else {
        throw Exception('Failed to generate AI suggestion: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error generating AI suggestion: $e');
      rethrow;
    }
  }

  /// Delete existing AI suggestion and regenerate (refresh)
  static Future<AISuggestion?> regenerateAISuggestion(Hike hike) async {
    if (hike.id == null) {
      throw Exception('Hike must have an ID');
    }

    // Delete old suggestion
    await AppDatabase.instance.deleteAISuggestionByHikeId(hike.id!);

    // Generate new one
    return await generateAISuggestion(hike);
  }

  /// Check whether the AI service is operational
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('AI service health check failed: $e');
      return false;
    }
  }
}

