// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_data.dart';
import '../db/app_db.dart';

/// Weather service for getting weather information (Feature 9: Weather API)
/// Service for retrieving weather information
class WeatherService {
  // Load API key and base URL from environment variables
  // Free registration at: https://openweathermap.org/api
  static String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
  static String get _baseUrl => dotenv.env['WEATHER_API_BASE_URL'] ?? 'https://api.openweathermap.org/data/2.5';

  /// Get weather by coordinates (lat, lng)
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Get weather by city name
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Get 5-day weather forecast (every 3 hours)
  Future<List<WeatherData>?> getForecast(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        return list.map((item) => WeatherData.fromJson(item)).toList();
      } else {
        print('Forecast API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return null;
    }
  }

  /// Get weather forecast for a duration (number of days)
  /// Returns one forecast per day (preferably at 12:00 PM)
  Future<List<WeatherData>?> getForecastForDuration(
    double lat,
    double lng,
    DateTime startDate,
    int durationDays,
  ) async {
    try {
      // Get raw forecast data
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lng&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        print('Forecast API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final List<dynamic> list = data['list'];

      // Group forecasts by date and pick one per day (preferably noon forecast)
      final Map<String, WeatherData> dailyForecasts = {};

      for (final item in list) {
        // Parse forecast with hike plan date as timestamp
        final forecast = WeatherData.fromJson(item, hikeDate: startDate);
        final date = forecast.forecastDate;

        // Check if this date is within our range
        final forecastDateTime = DateTime.parse(date);
        final daysDiff = forecastDateTime.difference(startDate).inDays;

        if (daysDiff >= 0 && daysDiff < durationDays) {
          // If we don't have this date yet, or this forecast is closer to noon
          if (!dailyForecasts.containsKey(date)) {
            dailyForecasts[date] = forecast;
          }
        }
      }

      // Convert map to sorted list
      final result = dailyForecasts.values.toList();
      result.sort((a, b) => a.forecastDate.compareTo(b.forecastDate));

      return result;
    } catch (e) {
      print('Error fetching forecast for duration: $e');
      return null;
    }
  }

  /// Save weather forecast for a hike to database
  Future<bool> saveWeatherForecastForHike(
    int hikeId,
    double lat,
    double lng,
    DateTime startDate,
    int durationDays,
  ) async {
    try {
      final forecasts = await getForecastForDuration(lat, lng, startDate, durationDays);
      if (forecasts == null || forecasts.isEmpty) return false;

      // Prepare forecast data for database
      final List<Map<String, dynamic>> forecastMaps = forecasts.map((forecast) {
        return {
          'hikeId': hikeId,
          'temperature': forecast.temperature,
          'condition': forecast.condition,
          'description': forecast.description,
          'humidity': forecast.humidity,
          'windSpeed': forecast.windSpeed,
          'icon': forecast.icon,
          'timestamp': forecast.timestamp.toIso8601String(),
          'forecastDate': forecast.forecastDate,
        };
      }).toList();

      // Save to database
      await AppDatabase.instance.updateWeatherForecastsForHike(hikeId, forecastMaps);
      return true;
    } catch (e) {
      print('Error saving weather forecast: $e');
      return false;
    }
  }

  /// Get weather forecasts from database
  Future<List<WeatherData>> getStoredWeatherForecasts(int hikeId) async {
    if (hikeId <= 0) {
      print('Invalid hikeId: $hikeId');
      return [];
    }

    try {
      final maps = await AppDatabase.instance.getWeatherForecastsByHike(hikeId);
      return maps.map((map) => WeatherData.fromMap(map)).toList();
    } catch (e) {
      print('Error getting stored weather forecasts: $e');
      return [];
    }
  }

  /// Save weather forecast for a hike to database (using location name)
  Future<bool> saveWeatherForecastForHikeByLocation(
    int hikeId,
    String locationName,
    DateTime startDate,
    int durationDays,
  ) async {
    try {
      // First, get the current weather to obtain coordinates
      final currentWeather = await getWeatherByCity(locationName);
      if (currentWeather == null) {
        print('Could not fetch weather for location: $locationName');
        return false;
      }

      // Now fetch the forecast using coordinates from the current weather response
      // We need to get coordinates from the API response
      final url = Uri.parse(
        '$_baseUrl/weather?q=$locationName&appid=$_apiKey&units=metric&lang=vi',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return false;

      final data = json.decode(response.body);
      final coord = data['coord'];
      final double lat = coord['lat'].toDouble();
      final double lng = coord['lon'].toDouble();

      // Now get the forecast for the duration
      final forecasts = await getForecastForDuration(lat, lng, startDate, durationDays);
      if (forecasts == null || forecasts.isEmpty) return false;

      // Prepare forecast data for database
      final List<Map<String, dynamic>> forecastMaps = forecasts.map((forecast) {
        return {
          'hikeId': hikeId,
          'temperature': forecast.temperature,
          'condition': forecast.condition,
          'description': forecast.description,
          'humidity': forecast.humidity,
          'windSpeed': forecast.windSpeed,
          'icon': forecast.icon,
          'timestamp': forecast.timestamp.toIso8601String(),
          'forecastDate': forecast.forecastDate,
        };
      }).toList();

      // Save to database
      await AppDatabase.instance.updateWeatherForecastsForHike(hikeId, forecastMaps);
      return true;
    } catch (e) {
      print('Error saving weather forecast by location: $e');
      return false;
    }
  }

  /// Check if weather is suitable for hiking
  bool isGoodForHiking(WeatherData weather) {
    // Điều kiện lý tưởng: 15-30°C, không mưa/bão, gió < 30 km/h
    bool goodTemp = weather.temperature >= 15 && weather.temperature <= 30;
    bool goodCondition = !['rain', 'thunderstorm', 'snow'].contains(
      weather.condition.toLowerCase(),
    );
    bool goodWind = weather.windSpeed < 30;

    return goodTemp && goodCondition && goodWind;
  }

  /// Get hiking recommendation based on weather
  String getHikingRecommendation(WeatherData weather) {
    if (weather.condition.toLowerCase().contains('rain')) {
      return '🌧️ Not recommended. Roads may be slippery and dangerous.';
    }

    if (weather.condition.toLowerCase().contains('thunderstorm')) {
      return '⛈️ Very dangerous! Do not go hiking during storms.';
    }

    if (weather.temperature > 35) {
      return '🔥 Too hot! Consider going early morning or late afternoon.';
    }

    if (weather.temperature < 5) {
      return '❄️ Too cold! Prepare warm clothes and protective gear.';
    }

    if (weather.windSpeed > 30) {
      return '💨 Strong winds! Be careful in high altitude areas.';
    }

    if (isGoodForHiking(weather)) {
      return '✅ Perfect weather for hiking!';
    }

    return '⚠️ Weather is acceptable. Prepare well before going.';
  }

  /// Format temperature string
  String formatTemperature(double temp) {
    return '${temp.toStringAsFixed(1)}°C';
  }

  /// Format wind speed string
  String formatWindSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} km/h';
  }

  /// Format humidity string
  String formatHumidity(double humidity) {
    return '${humidity.toStringAsFixed(0)}%';
  }
}

