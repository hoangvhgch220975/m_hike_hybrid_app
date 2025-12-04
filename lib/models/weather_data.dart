// lib/models/weather_data.dart

/// Weather data model
class WeatherData {
  int? id; // ID in database (null when not saved yet)
  int? hikeId; // Foreign key to hikes table
  final double temperature;        // Temperature (°C)
  final String condition;          // Weather condition (Sunny, Cloudy, Rain, etc.)
  final String description;        // Detailed description
  final double humidity;           // Humidity (%)
  final double windSpeed;          // Wind speed (km/h)
  final String icon;               // Icon code from API
  final DateTime timestamp;        // Time when data was retrieved
  final String forecastDate;       // Forecast date (YYYY-MM-DD format)

  WeatherData({
    this.id,
    this.hikeId,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
    required this.forecastDate,
  });

  /// Create WeatherData from API JSON
  factory WeatherData.fromJson(
      Map<String, dynamic> json, {
        DateTime? hikeDate, // Hike plan date (from date field in hikes table)
      }) {
    // Handle both current weather and forecast API responses
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    // For forecast API, use dt_txt; for current weather, use current timestamp
    String forecastDate;

    if (json.containsKey('dt_txt')) {
      // Forecast API format: "2024-01-15 12:00:00"
      forecastDate = json['dt_txt'].toString().split(' ')[0];
    } else {
      // Current weather API - use today's date
      forecastDate = DateTime.now().toIso8601String().split('T')[0];
    }

    // timestamp = hike plan date (same for all forecasts of a hike)
    // forecastDate = individual forecast date (different for each day)
    final DateTime timestamp = hikeDate ?? DateTime.now();

    return WeatherData(
      temperature: main['temp'].toDouble(),
      condition: weather['main'],
      description: weather['description'],
      humidity: main['humidity'].toDouble(),
      windSpeed: wind['speed'].toDouble(),
      icon: weather['icon'],
      timestamp: timestamp, // Use hike plan date as timestamp
      forecastDate: forecastDate, // Keep individual forecast date
    );
  }

  /// Convert WeatherData object to Map for saving into SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'temperature': temperature,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'forecastDate': forecastDate,
    };
  }

  /// Create WeatherData object from Map read from SQLite
  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'] as int?,
      hikeId: map['hikeId'] as int?,
      temperature: (map['temperature'] as num).toDouble(),
      condition: map['condition'] as String,
      description: map['description'] as String,
      humidity: (map['humidity'] as num).toDouble(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      icon: map['icon'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      forecastDate: map['forecastDate'] as String,
    );
  }

  /// Get icon URL from OpenWeatherMap
  String getIconUrl() {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  /// Get emoji icon based on condition
  String getEmoji() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌡️';
    }
  }

  /// Copy with method for creating modified copies
  WeatherData copyWith({
    int? id,
    int? hikeId,
    double? temperature,
    String? condition,
    String? description,
    double? humidity,
    double? windSpeed,
    String? icon,
    DateTime? timestamp,
    String? forecastDate,
  }) {
    return WeatherData(
      id: id ?? this.id,
      hikeId: hikeId ?? this.hikeId,
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
      forecastDate: forecastDate ?? this.forecastDate,
    );
  }
}
