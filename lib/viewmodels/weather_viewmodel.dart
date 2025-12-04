// lib/viewmodels/weather_viewmodel.dart

import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  // Current weather data (single day)
  WeatherData? currentWeather;

  // Forecast data for multiple days
  List<WeatherData> forecastList = [];

  // Loading and error states
  bool isLoading = false;
  String? errorMessage;

  // Track if data is from database (for completed hikes) or API (for planned hikes)
  bool isFromDatabase = false;

  // Get weather by city name
  Future<void> getWeatherByCity(String city) async {
    if (city.isEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final weatherData = await _weatherService.getWeatherByCity(city);

      if (weatherData != null) {
        currentWeather = weatherData;
      } else {
        errorMessage = 'Could not fetch weather data';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting weather: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get weather by coordinates
  Future<void> getWeatherByCoordinates(double lat, double lon) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final weatherData = await _weatherService.getWeatherByCoordinates(lat, lon);

      if (weatherData != null) {
        currentWeather = weatherData;
      } else {
        errorMessage = 'Could not fetch weather data';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting weather: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get weather forecast for duration days
  Future<void> getForecastForDuration(
      double lat,
      double lon,
      DateTime startDate,
      int durationDays,
      ) async {
    isLoading = true;
    errorMessage = null;
    forecastList = [];
    notifyListeners();

    try {
      final forecasts = await _weatherService.getForecastForDuration(
        lat,
        lon,
        startDate,
        durationDays,
      );

      if (forecasts != null && forecasts.isNotEmpty) {
        forecastList = forecasts;
      } else {
        errorMessage = 'Could not fetch forecast data';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error getting forecast: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch and save weather forecast for a hike (by coordinates)
  Future<bool> fetchAndSaveWeatherForHike(
      int hikeId,
      double lat,
      double lon,
      DateTime startDate,
      int durationDays,
      ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _weatherService.saveWeatherForecastForHike(
        hikeId,
        lat,
        lon,
        startDate,
        durationDays,
      );

      if (success) {
        // Load the stored forecasts
        forecastList = await _weatherService.getStoredWeatherForecasts(hikeId);
        isFromDatabase = false; // Data fetched from API
      } else {
        errorMessage = 'Failed to fetch weather data';
      }

      return success;
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error fetching and saving weather: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch and save weather forecast for a hike (by coordinates) - Alias method
  Future<bool> fetchAndSaveWeatherForHikeByCoordinates(
      int hikeId,
      double lat,
      double lon,
      DateTime startDate,
      int durationDays,
      ) async {
    // This is just an alias to the existing method for better naming clarity
    return await fetchAndSaveWeatherForHike(
      hikeId,
      lat,
      lon,
      startDate,
      durationDays,
    );
  }

  // Fetch and save weather forecast for a hike (by location name)
  Future<bool> fetchAndSaveWeatherForHikeByLocation(
      int hikeId,
      String locationName,
      DateTime startDate,
      int durationDays,
      ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _weatherService.saveWeatherForecastForHikeByLocation(
        hikeId,
        locationName,
        startDate,
        durationDays,
      );

      if (success) {
        // Load the stored forecasts
        forecastList = await _weatherService.getStoredWeatherForecasts(hikeId);
        isFromDatabase = false; // Data fetched from API
      } else {
        errorMessage = 'Failed to fetch weather data. Check location name.';
      }

      return success;
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error fetching and saving weather: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load stored weather forecasts for a hike
  // Load stored weather forecast for a hike
  Future<void> loadStoredForecasts(int hikeId) async {
    if (hikeId <= 0) {
      debugPrint('Invalid hikeId: $hikeId');
      errorMessage = 'Invalid hike ID';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      forecastList = await _weatherService.getStoredWeatherForecasts(hikeId);
      isFromDatabase = true; // Data loaded from database

      if (forecastList.isEmpty) {
        errorMessage = 'No weather data stored for this hike.';
      } else {
        errorMessage = null; // Clear error on successful load
      }
    } catch (e) {
      errorMessage = 'Error loading weather data';
      debugPrint('Error loading stored forecasts: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Clear weather data
  void clear() {
    currentWeather = null;
    forecastList = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  // Check if weather data is available
  bool get hasWeatherData => currentWeather != null || forecastList.isNotEmpty;
}
