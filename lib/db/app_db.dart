// lib/db/app_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hike.dart';
import '../models/observation.dart';
import '../models/media_item.dart';
import '../models/ai_suggestion.dart';

// ============================================================================
// DATABASE MANAGER CLASS (SINGLETON)
// Responsible for initializing the DB and providing basic CRUD functions.
// ============================================================================
class AppDatabase {
  // Using Singleton Pattern: Only one instance of AppDatabase exists
  static final AppDatabase instance = AppDatabase._privateConstructor();
  static Database? _database;

  AppDatabase._privateConstructor();

  // Database Name and Version
  final String _dbName = 'm_hike_hybrid_app.db';
  // Version 1: All tables including AI suggestions from the start
  final int _dbVersion = 1;

  // Table Names
  final String _hikeTable = 'hikes';
  final String _observationTable = 'observations';
  final String _mediaTable = 'media';
  final String _weatherTable = 'weather_forecasts';
  final String _aiSuggestionTable = 'ai_suggestions';

  // Getter for Database instance
  // If database already exists (_database != null) return it, otherwise initialize
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize Database: Open or create database at specified path
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate, // Function to create tables
      onConfigure: _onConfigure, // Function to enable Foreign Keys
      onUpgrade: _onUpgrade, // Function to handle schema upgrades (no-op for completed migration)
      onOpen: _onOpen,
    );
  }

  // onOpen — Database schema includes all tables from version 1
  // All features: hikes, observations, media, weather_forecasts, ai_suggestions
  Future _onOpen(Database db) async {
    // intentionally left blank
  }

  // Enable Foreign Keys mode
  // Ensures data integrity when deleting (ON DELETE CASCADE)
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Handle database upgrades
  // Starting fresh at version 1 with all tables from the start
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations needed - version 1 includes all tables
    // If you need to upgrade in the future, add migration logic here
  }

  // Create tables when database is created for the first time
  Future _onCreate(Database db, int version) async {
    // 1. HIKES Table
    await db.execute('''
      CREATE TABLE $_hikeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        date TEXT NOT NULL,
        length REAL NOT NULL,
        difficulty TEXT NOT NULL,
        description TEXT,
        isComplete INTEGER NOT NULL DEFAULT 0,
        isRemarkable INTEGER NOT NULL DEFAULT 0,
        hasParking INTEGER NOT NULL DEFAULT 0,
        estimatedDuration INTEGER NOT NULL DEFAULT 1,
        latitude REAL,
        longitude REAL,
        isMapPicked INTEGER NOT NULL DEFAULT 0,
        isLengthFromMap INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. OBSERVATIONS Table (Linked to HIKES)
    await db.execute('''
      CREATE TABLE $_observationTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        caption TEXT NOT NULL,
        content TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (hikeId) REFERENCES $_hikeTable (id) ON DELETE CASCADE
      )
    ''');

    // 3. MEDIA Table (Linked to OBSERVATIONS)
    await db.execute('''
      CREATE TABLE $_mediaTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        observationId INTEGER NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (observationId) REFERENCES $_observationTable (id) ON DELETE CASCADE
      )
    ''');

    // 4. WEATHER_FORECASTS Table (Linked to HIKES)
    await db.execute('''
      CREATE TABLE $_weatherTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        temperature REAL NOT NULL,
        condition TEXT NOT NULL,
        description TEXT NOT NULL,
        humidity REAL NOT NULL,
        windSpeed REAL NOT NULL,
        icon TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        forecastDate TEXT NOT NULL,
        FOREIGN KEY (hikeId) REFERENCES $_hikeTable (id) ON DELETE CASCADE
      )
    ''');

    // 5. AI_SUGGESTIONS Table (Linked to HIKES)
    await db.execute('''
      CREATE TABLE $_aiSuggestionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hikeId INTEGER NOT NULL,
        summary TEXT NOT NULL,
        difficultyAdvice TEXT NOT NULL,
        weatherAdvice TEXT NOT NULL,
        packingList TEXT NOT NULL,
        risks TEXT NOT NULL,
        startTimeHint TEXT,
        generatedAt TEXT NOT NULL,
        modelVersion TEXT NOT NULL,
        FOREIGN KEY (hikeId) REFERENCES $_hikeTable (id) ON DELETE CASCADE
      )
    ''');
  }

  // ============================================================================
  // MARK: - CRUD Hikes (Feature 1, 4)
  // ============================================================================

   /// Add a new hike to the hikes table.
   Future<int> insertHike(Hike hike) async {
     Database db = await instance.database;
     return await db.insert(_hikeTable, hike.toMap());
   }

   /// Get a Hike by ID.
   Future<Hike?> getHikeById(int id) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [id],
     );
     if (maps.isNotEmpty) {
       return Hike.fromMap(maps.first);
     }
     return null;
   }

   /// Update a Hike's information based on ID.
   Future<int> updateHike(Hike hike) async {
     Database db = await instance.database;
     return await db.update(
       _hikeTable,
       hike.toMap(),
       where: 'id = ?',
       whereArgs: [hike.id],
     );
   }

   /// Delete a Hike by ID.
   /// Thanks to ON DELETE CASCADE, related Observations and Media will be automatically deleted.
   Future<int> deleteHike(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   // Get all Hikes (no pagination).
   Future<List<Hike>> getAllHikes() async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Get paginated Hikes with custom page size (for Infinity Scroll).
   Future<List<Hike>> getHikesPaged(int page, int pageSize) async {
     Database db = await instance.database;
     final offset = page * pageSize;

     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       limit: pageSize,
       offset: offset,
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Count number of Hikes.
   Future<int> getHikesCount() async {
     Database db = await instance.database;
     final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_hikeTable');
     return Sqflite.firstIntValue(result) ?? 0;
   }

   /// Search Hikes by name or location.
   Future<List<Hike>> searchHikes(String query) async {
     if (query.isEmpty) return [];

     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'name LIKE ? OR location LIKE ?',
       whereArgs: ['%$query%', '%$query%'],
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Get list of completed Hikes (Feed).
   Future<List<Hike>> getCompletedHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isComplete = ?',
       whereArgs: [1],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Get list of planned Hikes (Plan).
   Future<List<Hike>> getPlannedHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isComplete = ?',
       whereArgs: [0],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Get list of remarkable Hikes (Remarkable).
   Future<List<Hike>> getRemarkableHikes({int? limit}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'isRemarkable = ?',
       whereArgs: [1],
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Get list of recent Hikes.
   Future<List<Hike>> getRecentHikes({int limit = 10}) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       orderBy: 'date DESC',
       limit: limit,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Filter Hikes by difficulty.
   Future<List<Hike>> getHikesByDifficulty(String difficulty) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: 'difficulty = ?',
       whereArgs: [difficulty],
       orderBy: 'date DESC',
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   /// Filter Hikes by multiple criteria (advanced filter).
   Future<List<Hike>> filterHikes({
     String? difficulty,
     bool? isComplete,
     bool? isRemarkable,
     double? minLength,
     double? maxLength,
     String? orderBy,
   }) async {
     Database db = await instance.database;

     List<String> whereClauses = [];
     List<dynamic> whereArgs = [];

     if (difficulty != null) {
       whereClauses.add('difficulty = ?');
       whereArgs.add(difficulty);
     }

     if (isComplete != null) {
       whereClauses.add('isComplete = ?');
       whereArgs.add(isComplete ? 1 : 0);
     }

     if (isRemarkable != null) {
       whereClauses.add('isRemarkable = ?');
       whereArgs.add(isRemarkable ? 1 : 0);
     }

     if (minLength != null) {
       whereClauses.add('length >= ?');
       whereArgs.add(minLength);
     }

     if (maxLength != null) {
       whereClauses.add('length <= ?');
       whereArgs.add(maxLength);
     }

     final whereClause = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
     final order = orderBy ?? 'date DESC';

     final List<Map<String, dynamic>> maps = await db.query(
       _hikeTable,
       where: whereClause,
       whereArgs: whereArgs.isEmpty ? null : whereArgs,
       orderBy: order,
     );

     return List.generate(maps.length, (i) {
       return Hike.fromMap(maps[i]);
     });
   }

   // ============================================================================
   // MARK: - CRUD Observations (Feature 2)
   // ============================================================================

   /// Add a new Observation to the observations table.
   Future<int> insertObservation(Observation observation) async {
     Database db = await instance.database;
     return await db.insert(_observationTable, observation.toMap());
   }

   /// Update Observation based on ID.
   Future<int> updateObservation(Observation observation) async {
     Database db = await instance.database;
     return await db.update(
       _observationTable,
       observation.toMap(),
       where: 'id = ?',
       whereArgs: [observation.id],
     );
   }

   /// Delete Observation by ID.
   /// Thanks to ON DELETE CASCADE, related Media will be automatically deleted.
   Future<int> deleteObservation(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _observationTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   /// Get Observation by ID (with media).
   Future<Observation?> getObservationById(int id) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'id = ?',
       whereArgs: [id],
     );

     if (maps.isNotEmpty) {
       Observation obs = Observation.fromMap(maps.first);
       // Load media
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
       return obs;
     }
     return null;
   }

   /// Get all Observations by hikeId (no pagination, with media).
   Future<List<Observation>> getObservationsByHike(int hikeId) async {
     Database db = await instance.database;

     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
     );

     List<Observation> observations = List.generate(maps.length, (i) {
       return Observation.fromMap(maps[i]);
     });

     // Load media for each observation
     for (var obs in observations) {
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
     }

     return observations;
   }

   /// Get paginated Observations by hikeId (for Infinity Scroll).
   Future<List<Observation>> getObservationsByHikePaged(
     int hikeId,
     int page,
     int pageSize,
   ) async {
     Database db = await instance.database;
     final offset = page * pageSize;

     final List<Map<String, dynamic>> maps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
       limit: pageSize,
       offset: offset,
     );

     List<Observation> observations = List.generate(maps.length, (i) {
       return Observation.fromMap(maps[i]);
     });

     // Load media for each observation
     for (var obs in observations) {
       if (obs.id != null) {
         obs.media = await getMediaForObservation(obs.id!);
       }
     }

     return observations;
   }

   /// Count number of Observations by hikeId.
   Future<int> getObservationsCount(int hikeId) async {
     Database db = await instance.database;
     final result = await db.rawQuery(
       'SELECT COUNT(*) as count FROM $_observationTable WHERE hikeId = ?',
       [hikeId],
     );
     return Sqflite.firstIntValue(result) ?? 0;
   }

   // ============================================================================
   // MARK: - CRUD Media Items (Feature 2)
   // ============================================================================

   /// Add list of MediaItem (images/videos) to media table.
   /// Use transaction to ensure all items are saved successfully.
   Future<void> insertMediaItems(List<MediaItem> mediaList) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       for (final media in mediaList) {
         await txn.insert(_mediaTable, media.toMap());
       }
     });
   }

   /// Get list of MediaItem belonging to a specific Observation.
   Future<List<MediaItem>> getMediaForObservation(int observationId) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _mediaTable,
       where: 'observationId = ?',
       whereArgs: [observationId],
       orderBy: 'id ASC',
     );

     return List.generate(maps.length, (i) {
       return MediaItem.fromMap(maps[i]);
     });
   }

  /// Get a specific MediaItem by observationId and media id.
  Future<MediaItem?> getMediaItemByObservationAndId(int observationId, int mediaId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _mediaTable,
      where: 'observationId = ? AND id = ?',
      whereArgs: [observationId, mediaId],
      limit: 1,
    );

    if (maps.isNotEmpty) return MediaItem.fromMap(maps.first);
    return null;
  }

   /// Add a single MediaItem.
   Future<int> insertMediaItem(MediaItem mediaItem) async {
     Database db = await instance.database;
     return await db.insert(_mediaTable, mediaItem.toMap());
   }

   /// Update MediaItem.
   Future<int> updateMediaItem(MediaItem mediaItem) async {
     Database db = await instance.database;
     return await db.update(
       _mediaTable,
       mediaItem.toMap(),
       where: 'id = ?',
       whereArgs: [mediaItem.id],
     );
   }

   /// Delete MediaItem by ID.
   Future<int> deleteMediaItem(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _mediaTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   // ============================================================================
   // MARK: - CUSTOM DATA RETRIEVAL (For Hike Detail and banner image logic)
   // ============================================================================

   /// Get Hike details including all related Observations and MediaItems.
   /// Used for Hike Detail screen and logic to determine banner image/carousel
   /// according to custom requirements.
   Future<Hike?> getHikeDetailData(int hikeId) async {
     Database db = await instance.database;

     // 1. Get basic Hike
     final List<Map<String, dynamic>> hikeMaps = await db.query(
       _hikeTable,
       where: 'id = ?',
       whereArgs: [hikeId],
     );
     if (hikeMaps.isEmpty) return null;

     Hike hike = Hike.fromMap(hikeMaps.first);

     // 2. Get related Observations
     final List<Map<String, dynamic>> obsMaps = await db.query(
       _observationTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       orderBy: 'time DESC',
     );

     List<Observation> observations = List.generate(obsMaps.length, (i) {
       return Observation.fromMap(obsMaps[i]);
     });

     // 3. Get Media related to ALL Observations
     if (observations.isNotEmpty) {
       final obsIds = observations.map((o) => o.id).whereType<int>().toList();

       // Query all MediaItem with observationId in obsIds list
       final List<Map<String, dynamic>> mediaMaps = await db.query(
         _mediaTable,
         where: 'observationId IN (${List.filled(obsIds.length, '?').join(', ')})',
         whereArgs: obsIds,
         orderBy: 'id ASC',
       );

       // Map MediaItem to corresponding Observation
       final mediaMap = <int, List<MediaItem>>{};
       for (final map in mediaMaps) {
         final mediaItem = MediaItem.fromMap(map);
         final obsId = mediaItem.observationId;
         mediaMap.putIfAbsent(obsId, () => []).add(mediaItem);
       }

       // Assign retrieved MediaItems list to each Observation
       for (var obs in observations) {
         obs.media = mediaMap[obs.id] ?? [];
       }
     }

     // Assign Observation list populated with MediaItems to Hike
     hike.observations = observations;

     return hike;
   }

   // ============================================================================
   // MARK: - CRUD Weather Forecasts (Feature 9)
   // ============================================================================

   /// Add a weather forecast to the weather_forecasts table
   Future<int> insertWeatherForecast(Map<String, dynamic> weatherData) async {
     Database db = await instance.database;
     return await db.insert(_weatherTable, weatherData);
   }

   /// Add multiple weather forecasts at once (for multi-day forecast)
   Future<void> insertWeatherForecasts(List<Map<String, dynamic>> forecasts) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       for (final forecast in forecasts) {
         await txn.insert(_weatherTable, forecast);
       }
     });
   }

   /// Get all weather forecasts for a hike
   Future<List<Map<String, dynamic>>> getWeatherForecastsByHike(int hikeId) async {
     if (hikeId <= 0) {
       return [];
     }

     try {
       Database db = await instance.database;
       final List<Map<String, dynamic>> maps = await db.query(
         _weatherTable,
         where: 'hikeId = ?',
         whereArgs: [hikeId],
         orderBy: 'forecastDate ASC',
       );
       return maps;
     } catch (e) {
       return [];
     }
   }

   /// Get weather forecast for a specific date of a hike
   Future<Map<String, dynamic>?> getWeatherForecastByDate(int hikeId, String date) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _weatherTable,
       where: 'hikeId = ? AND forecastDate = ?',
       whereArgs: [hikeId, date],
       limit: 1,
     );

     if (maps.isNotEmpty) {
       return maps.first;
     }
     return null;
   }

   /// Delete all weather forecasts for a hike
   Future<int> deleteWeatherForecastsByHike(int hikeId) async {
     Database db = await instance.database;
     return await db.delete(
       _weatherTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
     );
   }

   /// Delete weather forecasts older than 7 days
   Future<int> deleteOldWeatherForecasts() async {
     Database db = await instance.database;
     final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
     return await db.delete(
       _weatherTable,
       where: 'timestamp < ?',
       whereArgs: [sevenDaysAgo],
     );
   }

   /// Update weather forecasts for a hike (delete old and insert new entries)
   Future<void> updateWeatherForecastsForHike(int hikeId, List<Map<String, dynamic>> forecasts) async {
     Database db = await instance.database;
     await db.transaction((txn) async {
       // Remove existing forecasts
       await txn.delete(
         _weatherTable,
         where: 'hikeId = ?',
         whereArgs: [hikeId],
       );

       // Insert new forecasts
       for (final forecast in forecasts) {
         await txn.insert(_weatherTable, forecast);
       }
     });
   }

   // ============================================================================
   // MARK: - CRUD AI Suggestions
   // ============================================================================

   /// Insert a new AI suggestion into the ai_suggestions table
   Future<int> insertAISuggestion(AISuggestion suggestion) async {
     Database db = await instance.database;
     return await db.insert(_aiSuggestionTable, suggestion.toMap());
   }

   /// Get AI suggestion by hikeId
   /// Returns null if no suggestion exists for this hike
   Future<AISuggestion?> getAISuggestionByHikeId(int hikeId) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _aiSuggestionTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       limit: 1,
     );

     if (maps.isNotEmpty) {
       return AISuggestion.fromMap(maps.first);
     }
     return null;
   }

   /// Update an AI suggestion
   Future<int> updateAISuggestion(AISuggestion suggestion) async {
     Database db = await instance.database;
     return await db.update(
       _aiSuggestionTable,
       suggestion.toMap(),
       where: 'id = ?',
       whereArgs: [suggestion.id],
     );
   }

   /// Delete AI suggestion by hikeId
   Future<int> deleteAISuggestionByHikeId(int hikeId) async {
     Database db = await instance.database;
     return await db.delete(
       _aiSuggestionTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
     );
   }

   /// Delete AI suggestion by ID
   Future<int> deleteAISuggestion(int id) async {
     Database db = await instance.database;
     return await db.delete(
       _aiSuggestionTable,
       where: 'id = ?',
       whereArgs: [id],
     );
   }

   /// Check whether a hike already has an AI suggestion
   Future<bool> hasAISuggestion(int hikeId) async {
     Database db = await instance.database;
     final List<Map<String, dynamic>> maps = await db.query(
       _aiSuggestionTable,
       where: 'hikeId = ?',
       whereArgs: [hikeId],
       limit: 1,
     );
     return maps.isNotEmpty;
   }

   // ============================================================================
   // MARK: - UTILITY METHODS
   // ============================================================================


   /// Clear all data (for testing or app reset)
   Future<void> clearAllData() async {
     Database db = await instance.database;
     await db.delete(_weatherTable);
     await db.delete(_mediaTable);
     await db.delete(_observationTable);
     await db.delete(_hikeTable);
   }

   /// Close database connection
   Future<void> close() async {
     Database db = await instance.database;
     await db.close();
   }
}

// Create an alias for convenience
typedef DbHelper = AppDatabase;
