// database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lyrics_app_offline.db');
    return await openDatabase(
      path,
      version: 10, // Incremented to refresh profile cache schema
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        fullname TEXT NOT NULL,
        phonenumber TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        isPremium INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Artists table - Enhanced with all required fields
    await db.execute('''
      CREATE TABLE artists(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image TEXT,
        bio TEXT,
        language TEXT DEFAULT 'en',
        album_count INTEGER DEFAULT 0,
        song_count INTEGER DEFAULT 0,
        total_song_count INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Albums table - Enhanced with artist info for joins
    await db.execute('''
      CREATE TABLE albums(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image TEXT,
        artist_id INTEGER NOT NULL,
        artist_name TEXT,
        artist_image TEXT,
        release_date TEXT,
        description TEXT,
        song_count INTEGER DEFAULT 0,
        language TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (artist_id) REFERENCES artists (id)
      )
    ''');

    // Songs table - Enhanced with all join fields
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY,
        songname TEXT NOT NULL,
        lyrics_si TEXT,
        lyrics_en TEXT,
        lyrics_ta TEXT,
        artist_id INTEGER NOT NULL,
        album_id INTEGER,
        artist_name TEXT,
        artist_image TEXT,
        album_name TEXT,
        album_image TEXT,
        duration INTEGER,
        track_number INTEGER,
        image TEXT,
        release_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (artist_id) REFERENCES artists (id),
        FOREIGN KEY (album_id) REFERENCES albums (id)
      )
    ''');

    // Group Songs table - NEW
    await db.execute('''
      CREATE TABLE group_songs(
        id INTEGER PRIMARY KEY,
        songname TEXT NOT NULL,
        album_name TEXT,
        lyrics_si TEXT,
        lyrics_en TEXT,
        lyrics_ta TEXT,
        image TEXT,
        language TEXT,
        release_date TEXT,
        duration TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Group Song Artists junction table - NEW
    await db.execute('''
      CREATE TABLE group_song_artists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_song_id INTEGER NOT NULL,
        artist_id INTEGER NOT NULL,
        artist_name TEXT,
        artist_image TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (group_song_id) REFERENCES group_songs (id),
        UNIQUE(group_song_id, artist_id)
      )
    ''');

    // User Profile Details table
    await db.execute('''
      CREATE TABLE user_profile_details(
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE,
        country TEXT,
        date_of_birth TEXT,
        gender TEXT,
        preferred_language TEXT,
        bio TEXT,
        profile_image TEXT,
        account_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // User Interests table
    await db.execute('''
      CREATE TABLE user_interests(
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        interest TEXT NOT NULL,
        created_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, interest)
      )
    ''');

    // User Favorites table
    await db.execute('''
      CREATE TABLE user_favorites(
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        song_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        song_image TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (song_id) REFERENCES songs (id),
        UNIQUE(user_id, song_id)
      )
    ''');

    // Setlist Folders table
    await db.execute('''
      CREATE TABLE setlist_folders(
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        folder_name TEXT NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, folder_name)
      )
    ''');

    // Setlist Songs table
    await db.execute('''
      CREATE TABLE setlist_songs(
        id INTEGER PRIMARY KEY,
        folder_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        song_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        song_image TEXT,
        lyrics_format TEXT DEFAULT 'tamil_only',
        saved_lyrics TEXT,
        order_index INTEGER DEFAULT 0,
        created_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (folder_id) REFERENCES setlist_folders (id),
        FOREIGN KEY (song_id) REFERENCES songs (id),
        UNIQUE(folder_id, song_id)
      )
    ''');

    // Worship Notes table
    await db.execute('''
      CREATE TABLE worship_notes(
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Worship Teams table (compatible with WorshipTeamModel cache schema) - Used for Worship Songs
    await db.execute('''
      CREATE TABLE worship_teams(
        id INTEGER PRIMARY KEY,
        songname TEXT,
        name TEXT,
        lyrics_si TEXT,
        lyrics_en TEXT,
        lyrics_ta TEXT,
        artist_id INTEGER,
        artist_name TEXT,
        artist_image TEXT,
        duration INTEGER,
        notes TEXT,
        image TEXT,
        artist_languages TEXT,
        language TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Worship Artists table
    await db.execute('''
      CREATE TABLE worship_artists(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image TEXT,
        bio TEXT,
        language TEXT DEFAULT 'en',
        album_count INTEGER DEFAULT 0,
        song_count INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Worship Albums table
    await db.execute('''
      CREATE TABLE worship_albums(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        image TEXT,
        artist_id INTEGER NOT NULL,
        artist_name TEXT,
        artist_image TEXT,
        release_date TEXT,
        description TEXT,
        song_count INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (artist_id) REFERENCES worship_artists (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY,
        title TEXT,
        message TEXT,
        date TEXT,
        created_at TEXT,
        is_read INTEGER DEFAULT 0
      )
    ''');

    // Sync Status table (for tracking sync operations)
    await db.execute('''
      CREATE TABLE sync_status(
        id INTEGER PRIMARY KEY,
        table_name TEXT NOT NULL,
        last_sync TEXT,
        sync_in_progress INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Existing indexes
    await db.execute('CREATE INDEX idx_albums_artist ON albums(artist_id)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist_id)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album_id)');
    await db.execute('CREATE INDEX idx_artists_language ON artists(language)');
    await db.execute('CREATE INDEX idx_sync_status ON users(synced)');
    await db.execute('CREATE INDEX idx_albums_sync ON albums(synced)');
    await db.execute('CREATE INDEX idx_songs_sync ON songs(synced)');
    await db.execute('CREATE INDEX idx_artists_sync ON artists(synced)');

    // New indexes for group songs
    await db.execute(
      'CREATE INDEX idx_group_songs_language ON group_songs(language)',
    );
    await db.execute(
      'CREATE INDEX idx_group_songs_sync ON group_songs(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_group_song_artists_song ON group_song_artists(group_song_id)',
    );
    await db.execute(
      'CREATE INDEX idx_group_song_artists_artist ON group_song_artists(artist_id)',
    );

    // Indexes for worship teams
    await db.execute(
      'CREATE INDEX idx_worship_teams_language ON worship_teams(language)',
    );
    await db.execute(
      'CREATE INDEX idx_worship_teams_sync ON worship_teams(synced)',
    );

    // Indexes for worship artists and albums
    await db.execute('CREATE INDEX idx_w_artists_language ON worship_artists(language)');
    await db.execute('CREATE INDEX idx_w_artists_sync ON worship_artists(synced)');
    await db.execute('CREATE INDEX idx_w_albums_artist ON worship_albums(artist_id)');
    await db.execute('CREATE INDEX idx_w_albums_sync ON worship_albums(synced)');

    // Index for notifications
    await db.execute('CREATE INDEX idx_notifications_created_at ON notifications(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add missing columns to existing tables
      await _addMissingColumns(db);
    }

    if (oldVersion < 3) {
      // Add group songs tables
      await _addGroupSongsTables(db);
    }

    if (oldVersion < 4) {
      // Add language column to albums table
      await _addLanguageColumnToAlbums(db);
    }

    if (oldVersion < 5) {
      // Add worship teams table
      await _addWorshipTeamsTable(db);
    }

    if (oldVersion < 6) {
      // Add release_date column to songs table
      await _addReleaseDateToSongs(db);
    }

    if (oldVersion < 7) {
      // Add total_song_count column to artists table
      await _addTotalSongCountToArtists(db);
    }

    if (oldVersion < 9) {
      // Add notifications table
      await _addNotificationsTable(db);
    }
  }

  Future<void> _addNotificationsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY,
          title TEXT,
          message TEXT,
          date TEXT,
          created_at TEXT,
          is_read INTEGER DEFAULT 0
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at)',
      );

      print('✅ Added notifications table');
    } catch (e) {
      print('⚠️ Error adding notifications table: $e');
    }
  }

  Future<void> _addWorshipArtistsAndAlbumsTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worship_artists(
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          image TEXT,
          bio TEXT,
          language TEXT DEFAULT 'en',
          album_count INTEGER DEFAULT 0,
          song_count INTEGER DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS worship_albums(
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          image TEXT,
          artist_id INTEGER NOT NULL,
          artist_name TEXT,
          artist_image TEXT,
          release_date TEXT,
          description TEXT,
          song_count INTEGER DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          synced INTEGER DEFAULT 0,
          FOREIGN KEY (artist_id) REFERENCES worship_artists (id)
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_w_artists_language ON worship_artists(language)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_w_artists_sync ON worship_artists(synced)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_w_albums_artist ON worship_albums(artist_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_w_albums_sync ON worship_albums(synced)');

      print('✅ Added worship artists and albums tables');
    } catch (e) {
      print('⚠️ Error adding worship artists and albums tables: $e');
    }
  }

  Future<void> _addWorshipTeamsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worship_teams(
          id INTEGER PRIMARY KEY,
          songname TEXT,
          name TEXT,
          lyrics_si TEXT,
          lyrics_en TEXT,
          lyrics_ta TEXT,
          artist_id INTEGER,
          artist_name TEXT,
          artist_image TEXT,
          duration INTEGER,
          notes TEXT,
          image TEXT,
          artist_languages TEXT,
          language TEXT,
          created_at TEXT,
          updated_at TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worship_teams_language ON worship_teams(language)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_worship_teams_sync ON worship_teams(synced)',
      );

      print('✅ Added worship teams table');
    } catch (e) {
      print('⚠️ Error adding worship teams table: $e');
    }
  }

  Future<void> _addReleaseDateToSongs(Database db) async {
    try {
      // Add release_date column to songs table
      await db.execute('ALTER TABLE songs ADD COLUMN release_date TEXT');
      print('✅ Added release_date column to songs table');
    } catch (e) {
      print('⚠️ release_date column might already exist in songs table: $e');
    }
  }

  Future<void> _addTotalSongCountToArtists(Database db) async {
    try {
      // Add total_song_count column to artists table
      await db.execute(
        'ALTER TABLE artists ADD COLUMN total_song_count INTEGER DEFAULT 0',
      );
      print('✅ Added total_song_count column to artists table');
    } catch (e) {
      print(
        '⚠️ total_song_count column might already exist in artists table: $e',
      );
    }
  }

  Future<void> _addLanguageColumnToAlbums(Database db) async {
    try {
      // Add language column to albums table
      await db.execute('ALTER TABLE albums ADD COLUMN language TEXT');
      print('✅ Added language column to albums table');
    } catch (e) {
      print('⚠️ Language column might already exist in albums table: $e');
    }
  }

  Future<void> _addGroupSongsTables(Database db) async {
    try {
      // Create group_songs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS group_songs(
          id INTEGER PRIMARY KEY,
          songname TEXT NOT NULL,
          album_name TEXT,
          lyrics_si TEXT,
          lyrics_en TEXT,
          lyrics_ta TEXT,
          image TEXT,
          language TEXT,
          release_date TEXT,
          duration TEXT,
          created_at TEXT,
          updated_at TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');

      // Create group_song_artists junction table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS group_song_artists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_song_id INTEGER NOT NULL,
          artist_id INTEGER NOT NULL,
          artist_name TEXT,
          artist_image TEXT,
          synced INTEGER DEFAULT 0,
          FOREIGN KEY (group_song_id) REFERENCES group_songs (id),
          UNIQUE(group_song_id, artist_id)
        )
      ''');

      // Create indexes for group songs
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_songs_language ON group_songs(language)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_songs_sync ON group_songs(synced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_song_artists_song ON group_song_artists(group_song_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_song_artists_artist ON group_song_artists(artist_id)',
      );

      print('✅ Added group songs tables');
    } catch (e) {
      print('⚠️ Group songs tables might already exist: $e');
    }
  }

  Future<void> _addMissingColumns(Database db) async {
    try {
      // Add missing columns to artists table
      await db.execute(
        'ALTER TABLE artists ADD COLUMN album_count INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE artists ADD COLUMN song_count INTEGER DEFAULT 0',
      );
      print('✅ Added missing columns to artists table');
    } catch (e) {
      print('⚠️ Artists table columns might already exist: $e');
    }

    try {
      // Add missing columns to albums table
      await db.execute('ALTER TABLE albums ADD COLUMN artist_name TEXT');
      await db.execute('ALTER TABLE albums ADD COLUMN artist_image TEXT');
      await db.execute(
        'ALTER TABLE albums ADD COLUMN song_count INTEGER DEFAULT 0',
      );
      print('✅ Added missing columns to albums table');
    } catch (e) {
      print('⚠️ Albums table columns might already exist: $e');
    }

    try {
      // Add missing columns to songs table
      await db.execute('ALTER TABLE songs ADD COLUMN artist_name TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN artist_image TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN album_name TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN album_image TEXT');
      print('✅ Added missing columns to songs table');
    } catch (e) {
      print('⚠️ Songs table columns might already exist: $e');
    }

    // Update missing data from existing relationships
    await _updateMissingData(db);
  }

  Future<void> _updateMissingData(Database db) async {
    try {
      // Update artist_name in albums table
      await db.execute('''
        UPDATE albums 
        SET artist_name = (
          SELECT artists.name 
          FROM artists 
          WHERE artists.id = albums.artist_id
        )
        WHERE artist_name IS NULL
      ''');

      // Update artist_image in albums table
      await db.execute('''
        UPDATE albums 
        SET artist_image = (
          SELECT artists.image 
          FROM artists 
          WHERE artists.id = albums.artist_id
        )
        WHERE artist_image IS NULL
      ''');

      // Update artist_name in songs table
      await db.execute('''
        UPDATE songs 
        SET artist_name = (
          SELECT artists.name 
          FROM artists 
          WHERE artists.id = songs.artist_id
        )
        WHERE artist_name IS NULL
      ''');

      // Update artist_image in songs table
      await db.execute('''
        UPDATE songs 
        SET artist_image = (
          SELECT artists.image 
          FROM artists 
          WHERE artists.id = songs.artist_id
        )
        WHERE artist_image IS NULL
      ''');

      // Update album_name in songs table
      await db.execute('''
        UPDATE songs 
        SET album_name = (
          SELECT albums.name 
          FROM albums 
          WHERE albums.id = songs.album_id
        )
        WHERE album_name IS NULL AND album_id IS NOT NULL
      ''');

      // Update album_image in songs table
      await db.execute('''
        UPDATE songs 
        SET album_image = (
          SELECT albums.image 
          FROM albums 
          WHERE albums.id = songs.album_id
        )
        WHERE album_image IS NULL AND album_id IS NOT NULL
      ''');

      print('✅ Updated missing relational data');
    } catch (e) {
      print('⚠️ Error updating missing data: $e');
    }
  }

  // Helper method to check if a column exists
  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.any((column) => column['name'] == columnName);
    } catch (e) {
      return false;
    }
  }

  // Method to get table schema info (useful for debugging)
  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }

  // Method to clear all data (useful for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;

    final tables = [
      'group_song_artists', // Clear junction table first
      'group_songs', // Then group songs
      'worship_notes',
      'worship_teams',
      'setlist_songs',
      'setlist_folders',
      'user_favorites',
      'user_interests',
      'user_profile_details',
      'songs',
      'albums',
      'artists',
      'users',
      'sync_status',
    ];

    for (final table in tables) {
      try {
        await db.delete(table);
        print('✅ Cleared table: $table');
      } catch (e) {
        print('⚠️ Error clearing table $table: $e');
      }
    }
  }

  // Method to reset database (delete and recreate)
  Future<void> resetDatabase() async {
    await close();
    String path = join(await getDatabasesPath(), 'lyrics_app_offline.db');
    await deleteDatabase(path);
    _database = null;
    await database; // This will recreate the database
    print('✅ Database reset successfully');
  }

  // Method specifically for clearing group songs data
  Future<void> clearGroupSongsData() async {
    final db = await database;
    try {
      await db.delete('group_song_artists');
      await db.delete('group_songs');
      print('✅ Cleared group songs data');
    } catch (e) {
      print('⚠️ Error clearing group songs data: $e');
    }
  }

  // Method to check if group songs tables exist
  Future<bool> groupSongsTablesExist() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('group_songs', 'group_song_artists')",
      );
      return result.length == 2;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
