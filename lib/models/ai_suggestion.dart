// lib/models/ai_suggestion.dart

/// Model for AI-generated trip suggestions
class AISuggestion {
  int? id; // ID in database (null when not yet saved)
  int hikeId; // Foreign key referencing hikes table
  String summary; // Trip summary
  String difficultyAdvice; // Advice about trail difficulty
  String weatherAdvice; // Advice about weather conditions
  List<String> packingList; // List of items to bring
  List<String> risks; // List of potential risks
  String? startTimeHint; // Suggested starting time
  DateTime generatedAt; // Generation timestamp
  String modelVersion; // AI model version

  AISuggestion({
    this.id,
    required this.hikeId,
    required this.summary,
    required this.difficultyAdvice,
    required this.weatherAdvice,
    required this.packingList,
    required this.risks,
    this.startTimeHint,
    required this.generatedAt,
    required this.modelVersion,
  });

  /// Create AISuggestion from JSON API response
  factory AISuggestion.fromJson(Map<String, dynamic> json, int hikeId) {
    return AISuggestion(
      hikeId: hikeId,
      summary: json['summary'] ?? '',
      difficultyAdvice: json['difficulty_advice'] ?? '',
      weatherAdvice: json['weather_advice'] ?? '',
      packingList: List<String>.from(json['packing_list'] ?? []),
      risks: List<String>.from(json['risks'] ?? []),
      startTimeHint: json['start_time_hint'],
      generatedAt: json['generated_at_utc'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['generated_at_utc'] * 1000, isUtc: true)
          : DateTime.now(),
      modelVersion: json['model_version'] ?? 'unknown',
    );
  }

  /// Convert AISuggestion object to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'summary': summary,
      'difficultyAdvice': difficultyAdvice,
      'weatherAdvice': weatherAdvice,
      'packingList': packingList.join('||'), // Use || as separator
      'risks': risks.join('||'),
      'startTimeHint': startTimeHint,
      'generatedAt': generatedAt.toIso8601String(),
      'modelVersion': modelVersion,
    };
  }

  /// Create AISuggestion from Map read from SQLite
  factory AISuggestion.fromMap(Map<String, dynamic> map) {
    return AISuggestion(
      id: map['id'] as int?,
      hikeId: map['hikeId'] as int,
      summary: map['summary'] as String,
      difficultyAdvice: map['difficultyAdvice'] as String,
      weatherAdvice: map['weatherAdvice'] as String,
      packingList: (map['packingList'] as String).split('||').where((s) => s.isNotEmpty).toList(),
      risks: (map['risks'] as String).split('||').where((s) => s.isNotEmpty).toList(),
      startTimeHint: map['startTimeHint'] as String?,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      modelVersion: map['modelVersion'] as String,
    );
  }

  /// Copy with method for creating modified copies
  AISuggestion copyWith({
    int? id,
    int? hikeId,
    String? summary,
    String? difficultyAdvice,
    String? weatherAdvice,
    List<String>? packingList,
    List<String>? risks,
    String? startTimeHint,
    DateTime? generatedAt,
    String? modelVersion,
  }) {
    return AISuggestion(
      id: id ?? this.id,
      hikeId: hikeId ?? this.hikeId,
      summary: summary ?? this.summary,
      difficultyAdvice: difficultyAdvice ?? this.difficultyAdvice,
      weatherAdvice: weatherAdvice ?? this.weatherAdvice,
      packingList: packingList ?? this.packingList,
      risks: risks ?? this.risks,
      startTimeHint: startTimeHint ?? this.startTimeHint,
      generatedAt: generatedAt ?? this.generatedAt,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }
}
