// Offline-first Song Service
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/lyrics_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineSongService {
  final SongService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineSongService({SongService? onlineService})
    : _onlineService = onlineService ?? SongService();

  // Get all songs with offline support
  Future<Map<String, dynamic>> getAllSongs() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching songs from server...');
        final result = await _onlineService.getAllSongs();
        if (result['success']) {
          await _cacheSongs(result['songs']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongs();
  }

  // Get song by ID with offline support
  Future<Map<String, dynamic>> getSongById(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getSongById(id);
        if (result['success']) {
          await _cacheSongs([result['song']]);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongById(id);
  }

  // Get random songs with offline support
  Future<Map<String, dynamic>> getRandomSongs({int count = 10}) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getRandomSongs(count: count);
        if (result['success']) {
          await _cacheSongs(result['songs']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedRandomSongs(count);
  }

  // Get default random songs with offline support
  Future<Map<String, dynamic>> getDefaultRandomSongs() async {
    return await getRandomSongs(count: 10);
  }

  // Get songs by category with offline support
  Future<Map<String, dynamic>> getSongsByCategory(String category) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getSongsByCategory(category);
        if (result['success']) {
          await _cacheSongs(result['songs']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongsByCategory(category);
  }

  // Get songs with specific lyrics language
  Future<Map<String, dynamic>> getSongsWithLyrics(String language) async {
    return await _getCachedSongsWithLyrics(language);
  }

  // Get latest songs with offline support
  Future<Map<String, dynamic>> getLatestSongs({int limit = 10}) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getLatestSongs();
        if (result['success']) {
          await _cacheSongs(result['songs']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedLatestSongs(limit);
  }

  // Get songs by language with offline support
  Future<Map<String, dynamic>> getSongsByLanguage(String languageCode) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching songs by language: $languageCode');
        final result = await _onlineService.getSongsByLanguage(languageCode);
        if (result['success']) {
          // Cache songs with the language they were fetched for
          await _cacheSongsWithLanguage(result['songs'], languageCode);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongsByFetchedLanguage(languageCode);
  }

  // Get song lyrics by format with offline support
  Future<Map<String, dynamic>> getSongLyricsByFormat(
    String songTitle,
    String format,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getSongLyricsByFormat(
          songTitle,
          format,
        );
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongLyricsByFormat(songTitle, format);
  }

  // Get song lyrics by language with offline support
  Future<Map<String, dynamic>> getSongLyrics(
    String songTitle,
    String languageCode,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getSongLyrics(
          songTitle,
          languageCode,
        );
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongLyrics(songTitle, languageCode);
  }

  // Get song ID by name with offline support
  Future<Map<String, dynamic>> getSongIdByName(
    String songName,
    String artistName,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getSongIdByName(
          songName,
          artistName,
        );
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedSongIdByName(songName, artistName);
  }

  // Create song with offline support
  Future<Map<String, dynamic>> createSong(SongModel song) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.createSong(song);
        if (result['success']) {
          await _cacheSongs([result['song']]);
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _createSongLocally(song);
  }

  // Update song with offline support
  Future<Map<String, dynamic>> updateSong(int id, SongModel song) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateSong(id, song);
        if (result['success']) {
          await _cacheSongs([result['song']]);
          return result;
        }
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateSongLocally(id, song);
  }

  // Delete song with offline support
  Future<Map<String, dynamic>> deleteSong(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.deleteSong(id);
        if (result['success']) {
          await _deleteSongFromCache(id);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markSongForDeletion(id);
  }

  // Search songs with offline support
  Future<Map<String, dynamic>> searchSongs(String query) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.searchSongs(query);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online search failed, searching cache: $e');
      }
    }

    return await _searchCachedSongs(query);
  }

  // Private methods for caching and local operations
  Future<void> _cacheSongs(List<SongModel> songs) async {
    final db = await _dbHelper.database;

    for (final song in songs) {
      final songData = song.toJson()..['synced'] = 1;
      await db.insert(
        'songs',
        songData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${songs.length} songs');
  }

  // Cache songs with the language they were fetched for (for language-specific queries)
  Future<void> _cacheSongsWithLanguage(
    List<SongModel> songs,
    String language,
  ) async {
    final db = await _dbHelper.database;

    // Ensure fetched_language column exists
    await _ensureFetchedLanguageColumn(db);

    for (final song in songs) {
      final songData =
          song.toJson()
            ..['synced'] = 1
            ..['fetched_language'] = language;
      await db.insert(
        'songs',
        songData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${songs.length} songs for language: $language');
  }

  // Ensure the fetched_language column exists in songs table
  Future<void> _ensureFetchedLanguageColumn(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(songs)');
      final hasColumn = tableInfo.any(
        (col) => col['name'] == 'fetched_language',
      );
      if (!hasColumn) {
        await db.execute('ALTER TABLE songs ADD COLUMN fetched_language TEXT');
        print('✅ Added fetched_language column to songs table');
      }
    } catch (e) {
      print('⚠️ Error ensuring fetched_language column: $e');
    }
  }

  // Get cached songs filtered by the language they were fetched for
  Future<Map<String, dynamic>> _getCachedSongsByFetchedLanguage(
    String language,
  ) async {
    final db = await _dbHelper.database;

    // Ensure column exists before querying
    await _ensureFetchedLanguageColumn(db);

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

    // Filter by fetched_language column, with fallback to lyrics-based filtering
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1 
        AND (
          songs.fetched_language = ?
          OR (songs.fetched_language IS NULL AND songs.$lyricsColumn IS NOT NULL AND songs.$lyricsColumn != '')
        )
      ORDER BY songs.release_date DESC, songs.created_at DESC
    ''',
      [language],
    );

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': 'Songs for $language loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongs() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1
      ORDER BY songs.created_at DESC
    ''');

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': 'Songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.id = ? AND songs.synced != -1
    ''',
      [id],
    );

    if (maps.isNotEmpty) {
      final song = SongModel.fromJson(maps.first);
      return {
        'success': true,
        'song': song,
        'message': 'Song loaded from cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'Song not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _getCachedRandomSongs(int count) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1
      ORDER BY RANDOM()
      LIMIT ?
    ''',
      [count],
    );

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': 'Random songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedLatestSongs(int limit) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1
      ORDER BY songs.created_at DESC
      LIMIT ?
    ''',
      [limit],
    );

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': 'Latest songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongsByCategory(
    String category,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1 AND (
        songs.songname LIKE ? OR 
        songs.lyrics_si LIKE ? OR 
        songs.lyrics_en LIKE ? OR 
        songs.lyrics_ta LIKE ?
      )
      ORDER BY songs.created_at DESC
    ''',
      ['%$category%', '%$category%', '%$category%', '%$category%'],
    );

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': 'Category songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongsWithLyrics(
    String language,
  ) async {
    final db = await _dbHelper.database;
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

    final maps = await db.rawQuery('''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1 AND songs.$lyricsColumn IS NOT NULL AND songs.$lyricsColumn != ''
      ORDER BY songs.created_at DESC
    ''');

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message':
          'Songs with ${language.toUpperCase()} lyrics loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongLyricsByFormat(
    String songTitle,
    String format,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id
      WHERE songs.songname LIKE ? AND songs.synced != -1
      LIMIT 1
    ''',
      ['%$songTitle%'],
    );

    if (maps.isEmpty) {
      return {'success': false, 'message': 'Song not found in cache'};
    }

    final song = SongModel.fromJson(maps.first);
    final requiredLanguages = HowToReadLyricsService.getRequiredLanguages(
      format,
    );
    final displayOrder = HowToReadLyricsService.getLanguageDisplayOrder(format);

    final lyricsMap = <String, dynamic>{};
    final availableLanguages = <String>[];

    for (final lang in requiredLanguages) {
      final lyrics = song.getLyrics(lang);
      if (lyrics != null && lyrics.isNotEmpty) {
        lyricsMap[lang] = lyrics;
        availableLanguages.add(lang);
      }
    }

    return {
      'success': true,
      'song': song.songname,
      'artist': song.artistName ?? 'Unknown Artist',
      'format': format,
      'formatDisplayName': HowToReadLyricsService.getFormatTitle(format),
      'lyrics': lyricsMap,
      'displayOrder': displayOrder,
      'availableLanguages': availableLanguages,
      'totalLanguages': availableLanguages.length,
      'message': 'Lyrics loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedSongLyrics(
    String songTitle,
    String languageCode,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*
      FROM songs 
      WHERE songs.songname LIKE ? AND songs.synced != -1
      LIMIT 1
    ''',
      ['%$songTitle%'],
    );

    if (maps.isEmpty) {
      return {'success': false, 'message': 'Song not found in cache'};
    }

    final song = SongModel.fromJson(maps.first);
    final lyrics = song.getLyrics(languageCode);

    if (lyrics != null && lyrics.isNotEmpty) {
      return {
        'success': true,
        'lyrics': lyrics,
        'message': 'Lyrics loaded from cache',
        'source': 'cache',
      };
    } else {
      return {
        'success': false,
        'message': 'Lyrics not available for this language in cache',
      };
    }
  }

  Future<Map<String, dynamic>> _getCachedSongIdByName(
    String songName,
    String artistName,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.id
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id
      WHERE songs.songname LIKE ? AND artists.name LIKE ? AND songs.synced != -1
      LIMIT 1
    ''',
      ['%$songName%', '%$artistName%'],
    );

    if (maps.isNotEmpty) {
      return {
        'success': true,
        'songId': maps.first['id'],
        'message': 'Song ID found in cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'Song not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _createSongLocally(SongModel song) async {
    final db = await _dbHelper.database;

    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    final now = DateTime.now().toIso8601String();

    final songData =
        song.toCreateJson()
          ..['id'] = tempId
          ..['synced'] = 0
          ..['created_at'] = now
          ..['updated_at'] = now;

    await db.insert('songs', songData);

    final createdSong = SongModel.fromJson(songData);

    return {
      'success': true,
      'song': createdSong,
      'message': '💾 Song saved locally, will sync when online',
      'source': 'local',
      'pending_sync': true,
    };
  }

  Future<Map<String, dynamic>> _updateSongLocally(
    int id,
    SongModel song,
  ) async {
    final db = await _dbHelper.database;

    final updateData =
        song.toCreateJson()
          ..['synced'] = 0
          ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'songs',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsAffected > 0) {
      final updatedSong = song.copyWith(id: id, synced: 0);
      return {
        'success': true,
        'song': updatedSong,
        'message': '💾 Song updated locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Song not found in local database'};
    }
  }

  Future<Map<String, dynamic>> _markSongForDeletion(int id) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'songs',
      {'synced': -1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message': '🗑️ Song marked for deletion, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Song not found in local database'};
    }
  }

  Future<void> _deleteSongFromCache(int id) async {
    final db = await _dbHelper.database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> _searchCachedSongs(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, artists.image as artist_image, 
             albums.name as album_name, albums.image as album_image
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.synced != -1 AND (
        songs.songname LIKE ? OR 
        artists.name LIKE ? OR 
        songs.lyrics_si LIKE ? OR
        songs.lyrics_en LIKE ? OR
        songs.lyrics_ta LIKE ?
      )
      ORDER BY songs.created_at DESC
    ''',
      ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
    );

    final songs = maps.map((map) => SongModel.fromJson(map)).toList();

    return {
      'success': true,
      'songs': songs,
      'message': '🔍 Search completed in cache',
      'source': 'cache',
    };
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;

    await _syncPendingDeletions(db);
    await _syncPendingChanges(db);
  }

  Future<void> _syncPendingDeletions(Database db) async {
    final deletionMaps = await db.query(
      'songs',
      where: 'synced = ?',
      whereArgs: [-1],
    );

    for (final map in deletionMaps) {
      final songId = map['id'] as int;
      if (songId > 0) {
        try {
          final result = await _onlineService.deleteSong(songId);
          if (result['success']) {
            await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
            print('✅ Synced deletion for song $songId');
          }
        } catch (e) {
          print('❌ Failed to sync deletion for song $songId: $e');
        }
      } else {
        await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
      }
    }
  }

  Future<void> _syncPendingChanges(Database db) async {
    final unsyncedMaps = await db.query(
      'songs',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (final map in unsyncedMaps) {
      final song = SongModel.fromJson(map);

      try {
        if (song.id! < 0) {
          final result = await _onlineService.createSong(song);
          if (result['success']) {
            final serverSong = result['song'] as SongModel;
            await db.delete('songs', where: 'id = ?', whereArgs: [song.id]);
            await db.insert('songs', serverSong.toJson()..['synced'] = 1);
            print('✅ Synced local song creation: ${song.songname}');
          }
        } else {
          final result = await _onlineService.updateSong(song.id!, song);
          if (result['success']) {
            await db.update(
              'songs',
              {'synced': 1},
              where: 'id = ?',
              whereArgs: [song.id],
            );
            print('✅ Synced song update: ${song.songname}');
          }
        }
      } catch (e) {
        print('❌ Failed to sync song ${song.id}: $e');
      }
    }
  }

  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM songs WHERE synced = 0 OR synced = -1',
    );
    return result.first['count'] as int;
  }

  void dispose() {
    _onlineService.dispose();
  }
}
