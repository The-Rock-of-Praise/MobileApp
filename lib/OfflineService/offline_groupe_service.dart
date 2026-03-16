// OfflineService/offline_group_song_service.dart
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/group_song_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineGroupSongService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineGroupSongService();

  // Get all group songs with offline support
  Future<Map<String, dynamic>> getAllGroupSongs() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching group songs from server...');
        final result = await GroupSongService.getGroupSongs();
        await _cacheGroupSongs(result);
        return {'success': true, 'groupSongs': result, 'source': 'online'};
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedGroupSongs();
  }

  // Get group songs by language with offline support
  Future<Map<String, dynamic>> getGroupSongsByLanguage(String language) async {
    final isConnected = await _connectivityManager.isConnected();
    print('Checking connectivity for language $language: $isConnected');
    if (isConnected) {
      try {
        print('📡 Fetching group songs by language from server...');
        final result = await GroupSongService.getGroupSongsByLanguage(language);
        print('results from online $result');
        // Cache group songs with the language they were fetched for
        await _cacheGroupSongsWithLanguage(result, language);
        return {
          'success': true,
          'groupSongs': result,
          'language': language,
          'languageDisplayName': _getLanguageDisplayName(language),
          'source': 'online',
        };
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }
    return await _getCachedGroupSongsByLanguage(language);
  }

  // Get group song by ID with offline support
  Future<Map<String, dynamic>> getGroupSongById(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.getGroupSong(id);
        await _cacheGroupSongs([result]);
        return {'success': true, 'groupSong': result, 'source': 'online'};
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedGroupSongById(id);
  }

  // Get random group songs with offline support
  Future<Map<String, dynamic>> getRandomGroupSongs({
    int count = 10,
    String? language,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.getRandomGroupSongs(
          count,
          language: language,
        );
        await _cacheGroupSongs(result);
        return {
          'success': true,
          'groupSongs': result,
          'source': 'online',
          if (language != null) 'languageFilter': language,
        };
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedRandomGroupSongs(count, language: language);
  }

  // Get group songs by artist with offline support
  Future<Map<String, dynamic>> getGroupSongsByArtist(int artistId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.getGroupSongsByArtist(artistId);
        await _cacheGroupSongs(result);
        return {
          'success': true,
          'groupSongs': result,
          'artistId': artistId,
          'source': 'online',
        };
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedGroupSongsByArtist(artistId);
  }

  // Search group songs with offline support
  Future<Map<String, dynamic>> searchGroupSongs(
    String query, {
    String? language,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.searchGroupSongs(
          query,
          language: language,
        );
        return {
          'success': true,
          'groupSongs': result,
          'searchQuery': query,
          'source': 'online',
          if (language != null) 'languageFilter': language,
        };
      } catch (e) {
        print('❌ Online search failed, searching cache: $e');
      }
    }

    return await _searchCachedGroupSongs(query, language: language);
  }

  // Get group song lyrics by format with offline support
  Future<Map<String, dynamic>> getGroupSongLyricsByFormat({
    required String title,
    required String format,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.getGroupSongLyricsByFormat(
          title: title,
          format: format,
        );
        return {'success': true, 'data': result, 'source': 'online'};
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedGroupSongLyricsByFormat(title, format);
  }

  // Get group song lyrics by language with offline support
  Future<Map<String, dynamic>> getGroupSongLyrics(
    int id,
    String language,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await GroupSongService.getGroupSongLyrics(id, language);
        return {'success': true, 'data': result, 'source': 'online'};
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedGroupSongLyrics(id, language);
  }

  // Private methods for caching and local operations
  Future<void> _cacheGroupSongs(List<GroupSongModel> groupSongs) async {
    final db = await _dbHelper.database;

    // First ensure the group songs table exists
    await _ensureGroupSongTablesExist(db);

    for (final groupSong in groupSongs) {
      // Convert GroupSong to GroupSongModel for consistency
      final groupSongModel = GroupSongModel(
        id: groupSong.id,
        songName: groupSong.songName,
        albumName: groupSong.albumName,
        lyricsSi: groupSong.lyricsSi,
        lyricsEn: groupSong.lyricsEn,
        lyricsTa: groupSong.lyricsTa,
        image: groupSong.image,
        languages: groupSong.languages,
        releaseDate: groupSong.releaseDate,
        duration: groupSong.duration,
        artists:
            groupSong.artists
                .map(
                  (artist) => GroupSongArtist(
                    id: artist.id,
                    name: artist.name,
                    image: artist.image,
                  ),
                )
                .toList(),
        createdAt: groupSong.createdAt,
        updatedAt: groupSong.updatedAt,
      );

      // Cache the group song
      final groupSongData = groupSongModel.toJson()..['synced'] = 1;
      await db.insert(
        'group_songs',
        groupSongData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cache the artists relationship
      await db.delete(
        'group_song_artists',
        where: 'group_song_id = ?',
        whereArgs: [groupSong.id],
      );
      for (final artist in groupSong.artists) {
        await db.insert('group_song_artists', {
          'group_song_id': groupSong.id,
          'artist_id': artist.id,
          'artist_name': artist.name,
          'artist_image': artist.image,
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    print('✅ Cached ${groupSongs.length} group songs');
  }

  // Cache group songs with explicit language (for language-specific queries)
  Future<void> _cacheGroupSongsWithLanguage(
    List<GroupSongModel> groupSongs,
    String language,
  ) async {
    final db = await _dbHelper.database;

    // First ensure the group songs table exists
    await _ensureGroupSongTablesExist(db);

    for (final groupSong in groupSongs) {
      // Convert GroupSong to GroupSongModel for consistency
      final groupSongModel = GroupSongModel(
        id: groupSong.id,
        songName: groupSong.songName,
        albumName: groupSong.albumName,
        lyricsSi: groupSong.lyricsSi,
        lyricsEn: groupSong.lyricsEn,
        lyricsTa: groupSong.lyricsTa,
        image: groupSong.image,
        languages: groupSong.languages,
        releaseDate: groupSong.releaseDate,
        duration: groupSong.duration,
        artists:
            groupSong.artists
                .map(
                  (artist) => GroupSongArtist(
                    id: artist.id,
                    name: artist.name,
                    image: artist.image,
                  ),
                )
                .toList(),
        createdAt: groupSong.createdAt,
        updatedAt: groupSong.updatedAt,
      );

      // Cache the group song with explicit language
      final groupSongData =
          groupSongModel.toJson()
            ..['synced'] = 1
            ..['language'] = language; // Explicitly set the fetched language
      await db.insert(
        'group_songs',
        groupSongData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cache the artists relationship
      await db.delete(
        'group_song_artists',
        where: 'group_song_id = ?',
        whereArgs: [groupSong.id],
      );
      for (final artist in groupSong.artists) {
        await db.insert('group_song_artists', {
          'group_song_id': groupSong.id,
          'artist_id': artist.id,
          'artist_name': artist.name,
          'artist_image': artist.image,
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    print('✅ Cached ${groupSongs.length} group songs for language: $language');
  }

  Future<void> _ensureGroupSongTablesExist(Database db) async {
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

      // Create group_song_artists table
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

      // Create indexes
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_songs_language ON group_songs(language)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_group_song_artists_song ON group_song_artists(group_song_id)',
      );
    } catch (e) {
      print('⚠️ Group song tables might already exist: $e');
    }
  }

  Future<Map<String, dynamic>> _getCachedGroupSongs() async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final maps = await db.rawQuery('''
      SELECT gs.*, 
             GROUP_CONCAT(gsa.artist_name, ', ') as artist_names,
             COUNT(gsa.artist_id) as artist_count
      FROM group_songs gs
      LEFT JOIN group_song_artists gsa ON gs.id = gsa.group_song_id
      WHERE gs.synced != -1
      GROUP BY gs.id
      ORDER BY gs.created_at DESC
    ''');

    final groupSongs = <GroupSongModel>[];
    for (final map in maps) {
      final artists = await _getGroupSongArtists(db, map['id'] as int);
      final groupSong = GroupSongModel.fromJson({
        ...map,
        'artists': artists.map((a) => a.toJson()).toList(),
      });
      groupSongs.add(groupSong);
    }

    return {
      'success': true,
      'groupSongs': groupSongs,
      'message': 'Group songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedGroupSongsByLanguage(
    String language,
  ) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    // Determine the lyrics column for the requested language
    String lyricsColumn;
    switch (language.toLowerCase()) {
      case 'si':
        lyricsColumn = 'lyrics_si';
        break;
      case 'en':
        lyricsColumn = 'lyrics_en';
        break;
      case 'ta':
        lyricsColumn = 'lyrics_ta';
        break;
      default:
        lyricsColumn = 'lyrics_en';
    }

    // Filter by language metadata AND ensure lyrics exist for that language
    // Use exact match for language, with fallback for legacy data using LIKE pattern
    final maps = await db.rawQuery(
      '''
      SELECT gs.*, 
             GROUP_CONCAT(gsa.artist_name, ', ') as artist_names,
             COUNT(gsa.artist_id) as artist_count
      FROM group_songs gs
      LEFT JOIN group_song_artists gsa ON gs.id = gsa.group_song_id
      WHERE gs.synced != -1 
        AND (
          (gs.language = ? AND gs.$lyricsColumn IS NOT NULL AND gs.$lyricsColumn != '')
          OR (gs.language LIKE ? AND gs.$lyricsColumn IS NOT NULL AND gs.$lyricsColumn != '')
          OR (gs.language IS NULL AND gs.$lyricsColumn IS NOT NULL AND gs.$lyricsColumn != '')
        )
      GROUP BY gs.id
      ORDER BY gs.release_date DESC, gs.created_at DESC
    ''',
      [language, '%$language%'],
    );

    final groupSongs = <GroupSongModel>[];
    for (final map in maps) {
      final artists = await _getGroupSongArtists(db, map['id'] as int);
      final groupSong = GroupSongModel.fromJson({
        ...map,
        'artists': artists.map((a) => a.toJson()).toList(),
      });
      groupSongs.add(groupSong);
    }

    return {
      'success': true,
      'groupSongs': groupSongs,
      'language': language,
      'languageDisplayName': _getLanguageDisplayName(language),
      'message': 'Group songs by language loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedGroupSongById(int id) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final maps = await db.query(
      'group_songs',
      where: 'id = ? AND synced != -1',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return {'success': false, 'message': 'Group song not found in cache'};
    }

    final artists = await _getGroupSongArtists(db, id);
    final groupSong = GroupSongModel.fromJson({
      ...maps.first,
      'artists': artists.map((a) => a.toJson()).toList(),
    });

    return {
      'success': true,
      'groupSong': groupSong,
      'message': 'Group song loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedRandomGroupSongs(
    int count, {
    String? language,
  }) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    String query = '''
      SELECT gs.*, 
             GROUP_CONCAT(gsa.artist_name, ', ') as artist_names,
             COUNT(gsa.artist_id) as artist_count
      FROM group_songs gs
      LEFT JOIN group_song_artists gsa ON gs.id = gsa.group_song_id
      WHERE gs.synced != -1
    ''';

    List<dynamic> queryArgs = [];

    if (language != null) {
      query += ' AND (gs.language LIKE ? OR gs.language IS NULL)';
      queryArgs.add('%$language%');
    }

    query += '''
      GROUP BY gs.id
      ORDER BY RANDOM()
      LIMIT ?
    ''';
    queryArgs.add(count);

    final maps = await db.rawQuery(query, queryArgs);

    final groupSongs = <GroupSongModel>[];
    for (final map in maps) {
      final artists = await _getGroupSongArtists(db, map['id'] as int);
      final groupSong = GroupSongModel.fromJson({
        ...map,
        'artists': artists.map((a) => a.toJson()).toList(),
      });
      groupSongs.add(groupSong);
    }

    return {
      'success': true,
      'groupSongs': groupSongs,
      'message': 'Random group songs loaded from cache',
      'source': 'cache',
      if (language != null) 'languageFilter': language,
    };
  }

  Future<Map<String, dynamic>> _getCachedGroupSongsByArtist(
    int artistId,
  ) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final maps = await db.rawQuery(
      '''
      SELECT gs.*, 
             GROUP_CONCAT(gsa.artist_name, ', ') as artist_names,
             COUNT(gsa.artist_id) as artist_count
      FROM group_songs gs
      JOIN group_song_artists gsa ON gs.id = gsa.group_song_id
      WHERE gs.synced != -1 AND gsa.artist_id = ?
      GROUP BY gs.id
      ORDER BY gs.created_at DESC
    ''',
      [artistId],
    );

    final groupSongs = <GroupSongModel>[];
    for (final map in maps) {
      final artists = await _getGroupSongArtists(db, map['id'] as int);
      final groupSong = GroupSongModel.fromJson({
        ...map,
        'artists': artists.map((a) => a.toJson()).toList(),
      });
      groupSongs.add(groupSong);
    }

    return {
      'success': true,
      'groupSongs': groupSongs,
      'artistId': artistId,
      'message': 'Group songs by artist loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _searchCachedGroupSongs(
    String query, {
    String? language,
  }) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    String searchQuery = '''
      SELECT gs.*, 
             GROUP_CONCAT(gsa.artist_name, ', ') as artist_names,
             COUNT(gsa.artist_id) as artist_count
      FROM group_songs gs
      LEFT JOIN group_song_artists gsa ON gs.id = gsa.group_song_id
      WHERE gs.synced != -1 AND (
        gs.songname LIKE ? OR 
        gs.album_name LIKE ? OR
        gs.lyrics_si LIKE ? OR
        gs.lyrics_en LIKE ? OR
        gs.lyrics_ta LIKE ? OR
        gsa.artist_name LIKE ?
      )
    ''';

    List<dynamic> queryArgs = List.filled(6, '%$query%');

    if (language != null) {
      searchQuery += ' AND (gs.language LIKE ? OR gs.language IS NULL)';
      queryArgs.add('%$language%');
    }

    searchQuery += '''
      GROUP BY gs.id
      ORDER BY gs.songname
    ''';

    final maps = await db.rawQuery(searchQuery, queryArgs);

    final groupSongs = <GroupSongModel>[];
    for (final map in maps) {
      final artists = await _getGroupSongArtists(db, map['id'] as int);
      final groupSong = GroupSongModel.fromJson({
        ...map,
        'artists': artists.map((a) => a.toJson()).toList(),
      });
      groupSongs.add(groupSong);
    }

    return {
      'success': true,
      'groupSongs': groupSongs,
      'searchQuery': query,
      'message': '🔍 Group songs search completed in cache',
      'source': 'cache',
      if (language != null) 'languageFilter': language,
    };
  }

  Future<Map<String, dynamic>> _getCachedGroupSongLyricsByFormat(
    String title,
    String format,
  ) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final maps = await db.rawQuery(
      '''
      SELECT gs.*
      FROM group_songs gs
      WHERE gs.songname LIKE ? AND gs.synced != -1
      LIMIT 1
    ''',
      ['%$title%'],
    );

    if (maps.isEmpty) {
      return {'success': false, 'message': 'Group song not found in cache'};
    }

    final groupSong = GroupSongModel.fromJson(maps.first);
    final artists = await _getGroupSongArtists(db, groupSong.id);

    // Parse format and build lyrics response
    final lyricsResponse = <String, dynamic>{};
    final displayOrder = <String>[];
    bool hasRequiredLyrics = false;

    switch (format) {
      case 'tamil_only':
        if (groupSong.lyricsTa != null &&
            groupSong.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = groupSong.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        break;
      case 'english_only':
        if (groupSong.lyricsEn != null &&
            groupSong.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = groupSong.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
      case 'sinhala_only':
        if (groupSong.lyricsSi != null &&
            groupSong.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = groupSong.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        break;
      case 'tamil_english':
        if (groupSong.lyricsTa != null &&
            groupSong.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = groupSong.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (groupSong.lyricsEn != null &&
            groupSong.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = groupSong.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
      case 'tamil_sinhala':
        if (groupSong.lyricsTa != null &&
            groupSong.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = groupSong.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (groupSong.lyricsSi != null &&
            groupSong.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = groupSong.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        break;
      case 'all_three':
        if (groupSong.lyricsTa != null &&
            groupSong.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = groupSong.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (groupSong.lyricsSi != null &&
            groupSong.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = groupSong.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        if (groupSong.lyricsEn != null &&
            groupSong.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = groupSong.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
    }

    if (!hasRequiredLyrics) {
      return {
        'success': false,
        'message':
            'No lyrics available for "$title" in $format format from cache',
      };
    }

    return {
      'success': true,
      'data': {
        'song': groupSong.songName,
        'album_name': groupSong.albumName,
        'artists':
            artists
                .map((artist) => {'name': artist.name, 'image': artist.image})
                .toList(),
        'format': format,
        'formatDisplayName': _getFormatDisplayName(format),
        'lyrics': lyricsResponse,
        'displayOrder': displayOrder,
        'availableLanguages': _getAvailableLanguages(groupSong),
        'totalLanguages': displayOrder.length,
      },
      'message': 'Group song lyrics loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedGroupSongLyrics(
    int id,
    String language,
  ) async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final maps = await db.query(
      'group_songs',
      where: 'id = ? AND synced != -1',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return {'success': false, 'message': 'Group song not found in cache'};
    }

    final groupSong = GroupSongModel.fromJson(maps.first);
    final artists = await _getGroupSongArtists(db, id);

    String? lyrics;
    switch (language.toLowerCase()) {
      case 'si':
        lyrics = groupSong.lyricsSi;
        break;
      case 'en':
        lyrics = groupSong.lyricsEn;
        break;
      case 'ta':
        lyrics = groupSong.lyricsTa;
        break;
    }

    if (lyrics == null || lyrics.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Lyrics not available for this language in cache',
      };
    }

    return {
      'success': true,
      'data': {
        'id': groupSong.id,
        'songname': groupSong.songName,
        'album_name': groupSong.albumName,
        'language': language,
        'lyrics': lyrics,
        'artists':
            artists
                .map((artist) => {'name': artist.name, 'image': artist.image})
                .toList(),
        'language_supported': true,
      },
      'message': 'Group song lyrics loaded from cache',
      'source': 'cache',
    };
  }

  Future<List<GroupSongArtist>> _getGroupSongArtists(
    Database db,
    int groupSongId,
  ) async {
    final maps = await db.query(
      'group_song_artists',
      where: 'group_song_id = ?',
      whereArgs: [groupSongId],
      orderBy: 'artist_name',
    );

    return maps
        .map(
          (map) => GroupSongArtist(
            id: map['artist_id'] as int,
            name: map['artist_name'] as String,
            image: map['artist_image'] as String?,
          ),
        )
        .toList();
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'Tamil';
      case 'si':
        return 'Sinhala';
      case 'en':
        return 'English';
      default:
        return languageCode.toUpperCase();
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'tamil_only':
        return 'Tamil Only';
      case 'tamil_english':
        return 'Tamil + English Transliteration';
      case 'tamil_sinhala':
        return 'Tamil + Sinhala Transliteration';
      case 'all_three':
        return 'All Three Languages';
      case 'english_only':
        return 'English Transliteration Only';
      case 'sinhala_only':
        return 'Sinhala Transliteration Only';
      default:
        return format;
    }
  }

  List<String> _getAvailableLanguages(GroupSongModel groupSong) {
    final available = <String>[];
    if (groupSong.lyricsTa != null && groupSong.lyricsTa!.trim().isNotEmpty)
      available.add('ta');
    if (groupSong.lyricsSi != null && groupSong.lyricsSi!.trim().isNotEmpty)
      available.add('si');
    if (groupSong.lyricsEn != null && groupSong.lyricsEn!.trim().isNotEmpty)
      available.add('en');
    return available;
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    await _syncPendingDeletions(db);
    await _syncPendingChanges(db);
  }

  Future<void> _syncPendingDeletions(Database db) async {
    final deletionMaps = await db.query(
      'group_songs',
      where: 'synced = ?',
      whereArgs: [-1],
    );

    for (final map in deletionMaps) {
      final groupSongId = map['id'] as int;
      if (groupSongId > 0) {
        try {
          await GroupSongService.deleteGroupSong(groupSongId);
          await db.delete(
            'group_songs',
            where: 'id = ?',
            whereArgs: [groupSongId],
          );
          await db.delete(
            'group_song_artists',
            where: 'group_song_id = ?',
            whereArgs: [groupSongId],
          );
          print('✅ Synced deletion for group song $groupSongId');
        } catch (e) {
          print('❌ Failed to sync deletion for group song $groupSongId: $e');
        }
      } else {
        await db.delete(
          'group_songs',
          where: 'id = ?',
          whereArgs: [groupSongId],
        );
        await db.delete(
          'group_song_artists',
          where: 'group_song_id = ?',
          whereArgs: [groupSongId],
        );
      }
    }
  }

  Future<void> _syncPendingChanges(Database db) async {
    final unsyncedMaps = await db.query(
      'group_songs',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (final map in unsyncedMaps) {
      final groupSong = GroupSongModel.fromJson(map);
      final artists = await _getGroupSongArtists(db, groupSong.id);

      try {
        if (groupSong.id < 0) {
          // This is a locally created group song, create it on server
          final result = await GroupSongService.createGroupSong(
            songName: groupSong.songName,
            artistIds: artists.map((a) => a.id).toList(),
            albumName: groupSong.albumName,
            lyricsSi: groupSong.lyricsSi,
            lyricsEn: groupSong.lyricsEn,
            lyricsTa: groupSong.lyricsTa,
            languages: groupSong.languages,
            releaseDate: groupSong.releaseDate,
            duration: groupSong.duration,
          );

          await db.delete(
            'group_songs',
            where: 'id = ?',
            whereArgs: [groupSong.id],
          );
          await db.delete(
            'group_song_artists',
            where: 'group_song_id = ?',
            whereArgs: [groupSong.id],
          );
          await _cacheGroupSongs([result]);
          print('✅ Synced local group song creation: ${groupSong.songName}');
        } else {
          // This is an update to an existing group song
          final result = await GroupSongService.updateGroupSong(
            id: groupSong.id,
            songName: groupSong.songName,
            artistIds: artists.map((a) => a.id).toList(),
            albumName: groupSong.albumName,
            lyricsSi: groupSong.lyricsSi,
            lyricsEn: groupSong.lyricsEn,
            lyricsTa: groupSong.lyricsTa,
            languages: groupSong.languages,
            releaseDate: groupSong.releaseDate,
            duration: groupSong.duration,
          );

          await db.update(
            'group_songs',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [groupSong.id],
          );
          print('✅ Synced group song update: ${groupSong.songName}');
        }
      } catch (e) {
        print('❌ Failed to sync group song ${groupSong.id}: $e');
      }
    }
  }

  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    await _ensureGroupSongTablesExist(db);

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM group_songs WHERE synced = 0 OR synced = -1',
    );
    return result.first['count'] as int;
  }

  void dispose() {
    // Clean up any resources if needed
  }
}

// Update your existing GroupSongModel to be compatible
class GroupSongModel {
  final int id;
  final String songName;
  final String? albumName;
  final String? lyricsSi;
  final String? lyricsEn;
  final String? lyricsTa;
  final String? image;
  final List<String> languages;
  final String? releaseDate;
  final String? duration;
  final List<GroupSongArtist> artists;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupSongModel({
    required this.id,
    required this.songName,
    this.albumName,
    this.lyricsSi,
    this.lyricsEn,
    this.lyricsTa,
    this.image,
    required this.languages,
    this.releaseDate,
    this.duration,
    required this.artists,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupSongModel.fromJson(Map<String, dynamic> json) {
    return GroupSongModel(
      id: json['id'] ?? 0,
      songName: json['songname'] ?? json['songName'] ?? '',
      albumName: json['album_name'],
      lyricsSi: json['lyrics_si'],
      lyricsEn: json['lyrics_en'],
      lyricsTa: json['lyrics_ta'],
      image: json['image'],
      languages: _parseLanguages(json['language']),
      releaseDate: json['release_date'],
      duration: json['duration'],
      artists: _parseArtists(json['artists']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static List<String> _parseLanguages(dynamic languageData) {
    if (languageData == null) return ['en'];
    if (languageData is List) return languageData.cast<String>();
    if (languageData is String) {
      return languageData.split(',').map((e) => e.trim()).toList();
    }
    return ['en'];
  }

  static List<GroupSongArtist> _parseArtists(dynamic artistsData) {
    if (artistsData == null) return [];
    if (artistsData is List) {
      return artistsData
          .map((artist) {
            if (artist is Map<String, dynamic>) {
              return GroupSongArtist.fromJson(artist);
            } else if (artist is GroupSongArtist) {
              return artist;
            }
            return null;
          })
          .whereType<GroupSongArtist>()
          .toList();
    }
    return [];
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songname': songName,
      'album_name': albumName,
      'lyrics_si': lyricsSi,
      'lyrics_en': lyricsEn,
      'lyrics_ta': lyricsTa,
      'image': image,
      'language': languages.join(','),
      'release_date': releaseDate,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'songname': songName,
      'album_name': albumName,
      'lyrics_si': lyricsSi,
      'lyrics_en': lyricsEn,
      'lyrics_ta': lyricsTa,
      'language': languages,
      'release_date': releaseDate,
      'duration': duration,
      'artist_ids': artists.map((a) => a.id).toList(),
    };
  }

  GroupSongModel copyWith({
    int? id,
    String? songName,
    String? albumName,
    String? lyricsSi,
    String? lyricsEn,
    String? lyricsTa,
    String? image,
    List<String>? languages,
    String? releaseDate,
    String? duration,
    List<GroupSongArtist>? artists,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupSongModel(
      id: id ?? this.id,
      songName: songName ?? this.songName,
      albumName: albumName ?? this.albumName,
      lyricsSi: lyricsSi ?? this.lyricsSi,
      lyricsEn: lyricsEn ?? this.lyricsEn,
      lyricsTa: lyricsTa ?? this.lyricsTa,
      image: image ?? this.image,
      languages: languages ?? this.languages,
      releaseDate: releaseDate ?? this.releaseDate,
      duration: duration ?? this.duration,
      artists: artists ?? this.artists,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GroupSongArtist {
  final int id;
  final String name;
  final String? image;

  GroupSongArtist({required this.id, required this.name, this.image});

  factory GroupSongArtist.fromJson(Map<String, dynamic> json) {
    return GroupSongArtist(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}
