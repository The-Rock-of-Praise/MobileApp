import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineAlbumService {
  final AlbumService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineAlbumService({AlbumService? onlineService})
    : _onlineService = onlineService ?? AlbumService();

  // Get all albums with offline support
  Future<Map<String, dynamic>> getAllAlbums() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching albums from server...');
        final result = await _onlineService.getAllAlbums();
        if (result['success']) {
          await _cacheAlbums(result['albums']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedAlbums();
  }

  // Get albums by language with offline support
  Future<Map<String, dynamic>> getAlbumsByLanguage(String language) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching albums for language: $language from server...');
        final result = await _onlineService.getAlbumsByLanguage(language);
        if (result['success']) {
          // Cache with proper language association
          await _cacheAlbumsByLanguage(result['albums'], language);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    // Always try cache when offline or when online fails
    print('📱 Loading albums for language: $language from cache...');
    return await _getCachedAlbumsByLanguage(language);
  }

  Future<void> _cacheAlbumsByLanguage(
    List<AlbumModel> albums,
    String language,
  ) async {
    final db = await _dbHelper.database;

    for (final album in albums) {
      // Ensure all necessary data is included
      final albumData =
          album.toFullJson()
            ..['synced'] = 1
            ..['language'] =
                language // Associate with language
            ..['updated_at'] = DateTime.now().toIso8601String();

      // Ensure artist data is preserved
      if (album.artistName != null) {
        albumData['artist_name'] = album.artistName;
      }
      if (album.artistImage != null) {
        albumData['artist_image'] = album.artistImage;
      }

      await db.insert(
        'albums',
        albumData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${albums.length} albums for language: $language');
  }

  // Get album by ID with offline support
  Future<Map<String, dynamic>> getAlbumById(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getAlbumById(id);
        if (result['success']) {
          await _cacheAlbums([result['album']]);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedAlbumById(id);
  }

  // Get latest albums with offline support
  Future<Map<String, dynamic>> getLatestAlbums() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getLatestAlbums();
        if (result['success']) {
          await _cacheAlbums(result['albums']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedLatestAlbums();
  }

  // Get album songs with offline support
  Future<Map<String, dynamic>> getAlbumSongs(int albumId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getAlbumSongs(albumId);
        if (result['success']) {
          // Cache songs if we have a song service
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedAlbumSongs(albumId);
  }

  // Create album with offline support
  Future<Map<String, dynamic>> createAlbum(AlbumModel album) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.createAlbum(album);
        if (result['success']) {
          await _cacheAlbums([result['album']]);
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _createAlbumLocally(album);
  }

  // Update album with offline support
  Future<Map<String, dynamic>> updateAlbum(int id, AlbumModel album) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateAlbum(id, album);
        if (result['success']) {
          await _cacheAlbums([result['album']]);
          return result;
        }
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateAlbumLocally(id, album);
  }

  // Delete album with offline support
  Future<Map<String, dynamic>> deleteAlbum(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.deleteAlbum(id);
        if (result['success']) {
          await _deleteAlbumFromCache(id);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markAlbumForDeletion(id);
  }

  // Search albums with offline support
  Future<Map<String, dynamic>> searchAlbums(String query) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.searchAlbums(query);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online search failed, searching cache: $e');
      }
    }

    return await _searchCachedAlbums(query);
  }

  // Private methods for caching and local operations
  Future<void> _cacheAlbums(List<AlbumModel> albums) async {
    final db = await _dbHelper.database;

    for (final album in albums) {
      final albumData = album.toFullJson()..['synced'] = 1;
      await db.insert(
        'albums',
        albumData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${albums.length} albums');
  }

  Future<Map<String, dynamic>> _getCachedAlbums() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT albums.*, artists.name as artist_name, artists.image as artist_image
      FROM albums 
      LEFT JOIN artists ON albums.artist_id = artists.id 
      WHERE albums.synced != -1
      ORDER BY albums.created_at DESC
    ''');

    final albums = maps.map((map) => AlbumModel.fromJson(map)).toList();

    return {
      'success': true,
      'albums': albums,
      'message': 'Albums loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedAlbumsByLanguage(
    String language,
  ) async {
    final db = await _dbHelper.database;

    try {
      // First try to get albums by language through artist relationship
      var maps = await db.rawQuery(
        '''
        SELECT albums.*, 
               COALESCE(albums.artist_name, artists.name) as artist_name,
               COALESCE(albums.artist_image, artists.image) as artist_image,
               artists.language
        FROM albums 
        LEFT JOIN artists ON albums.artist_id = artists.id 
        WHERE artists.language = ? AND albums.synced != -1
        ORDER BY albums.created_at DESC
        ''',
        [language],
      );

      // If no results and we have a stored language in albums, try that
      if (maps.isEmpty) {
        maps = await db.rawQuery(
          '''
          SELECT albums.*, 
                 COALESCE(albums.artist_name, artists.name) as artist_name,
                 COALESCE(albums.artist_image, artists.image) as artist_image,
                 COALESCE(albums.language, artists.language) as language
          FROM albums 
          LEFT JOIN artists ON albums.artist_id = artists.id 
          WHERE albums.language = ? AND albums.synced != -1
          ORDER BY albums.created_at DESC
          ''',
          [language],
        );
      }

      // Parse albums with error handling
      final albums =
          maps
              .map((map) {
                try {
                  // Ensure required fields are not null
                  final albumMap = Map<String, dynamic>.from(map);

                  // Provide fallback values for missing data
                  albumMap['artist_name'] ??= 'Unknown Artist';
                  albumMap['image'] ??= '';

                  return AlbumModel.fromJson(albumMap);
                } catch (e) {
                  print('⚠️ Error parsing album from cache: $e');
                  print('Raw data: $map');
                  return null;
                }
              })
              .where((album) => album != null)
              .cast<AlbumModel>()
              .toList();

      // If no albums found for this language, try fallback
      if (albums.isEmpty) {
        print('⚠️ No cached albums found for language: $language');
        final fallbackMaps = await db.rawQuery('''
          SELECT albums.*, 
                 COALESCE(albums.artist_name, artists.name) as artist_name,
                 COALESCE(albums.artist_image, artists.image) as artist_image
          FROM albums 
          LEFT JOIN artists ON albums.artist_id = artists.id 
          WHERE albums.synced != -1
          ORDER BY albums.created_at DESC
          LIMIT 20
          ''');

        final fallbackAlbums =
            fallbackMaps
                .map((map) {
                  try {
                    final albumMap = Map<String, dynamic>.from(map);
                    albumMap['artist_name'] ??= 'Unknown Artist';
                    albumMap['image'] ??= '';
                    return AlbumModel.fromJson(albumMap);
                  } catch (e) {
                    return null;
                  }
                })
                .where((album) => album != null)
                .cast<AlbumModel>()
                .toList();

        return {
          'success': true,
          'albums': fallbackAlbums,
          'language': language,
          'languageDisplayName': _getLanguageDisplayName(language),
          'message': 'Showing cached albums (language fallback)',
          'source': 'cache_fallback',
        };
      }

      return {
        'success': true,
        'albums': albums,
        'language': language,
        'languageDisplayName': _getLanguageDisplayName(language),
        'message': 'Albums loaded from cache',
        'source': 'cache',
      };
    } catch (e) {
      print('❌ Error loading cached albums: $e');
      return {
        'success': false,
        'albums': <AlbumModel>[],
        'message': 'Error loading cached albums: $e',
        'source': 'cache_error',
      };
    }
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'English';
      case 'si':
        return 'Sinhala';
      case 'ta':
        return 'Tamil';
      default:
        return languageCode.toUpperCase();
    }
  }

  Future<Map<String, dynamic>> _getCachedAlbumById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT albums.*, artists.name as artist_name, artists.image as artist_image
      FROM albums 
      LEFT JOIN artists ON albums.artist_id = artists.id 
      WHERE albums.id = ? AND albums.synced != -1
    ''',
      [id],
    );

    if (maps.isNotEmpty) {
      final album = AlbumModel.fromJson(maps.first);
      return {
        'success': true,
        'album': album,
        'message': 'Album loaded from cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'Album not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _getCachedLatestAlbums() async {
    final db = await _dbHelper.database;

    try {
      // Get the current language to filter by
      final selectedLanguage = await LanguageService.getLanguage();
      final languageCode = LanguageService.getLanguageCode(selectedLanguage);

      // First try to get latest albums by language through artist relationship
      var maps = await db.rawQuery(
        '''
      SELECT albums.*, 
             COALESCE(albums.artist_name, artists.name) as artist_name,
             COALESCE(albums.artist_image, artists.image) as artist_image,
             artists.language
      FROM albums 
      LEFT JOIN artists ON albums.artist_id = artists.id 
      WHERE artists.language = ? AND albums.synced != -1
      ORDER BY albums.created_at DESC 
      LIMIT 10
    ''',
        [languageCode],
      );

      // If no results and we have a stored language in albums, try that
      if (maps.isEmpty) {
        maps = await db.rawQuery(
          '''
        SELECT albums.*, 
               COALESCE(albums.artist_name, artists.name) as artist_name,
               COALESCE(albums.artist_image, artists.image) as artist_image,
               COALESCE(albums.language, artists.language) as language
        FROM albums 
        LEFT JOIN artists ON albums.artist_id = artists.id 
        WHERE albums.language = ? AND albums.synced != -1
        ORDER BY albums.created_at DESC 
        LIMIT 10
      ''',
          [languageCode],
        );
      }

      // If still no results for this language, get fallback albums
      if (maps.isEmpty) {
        print('⚠️ No cached latest albums found for language: $languageCode');
        maps = await db.rawQuery('''
        SELECT albums.*, 
               COALESCE(albums.artist_name, artists.name) as artist_name,
               COALESCE(albums.artist_image, artists.image) as artist_image
        FROM albums 
        LEFT JOIN artists ON albums.artist_id = artists.id 
        WHERE albums.synced != -1
        ORDER BY albums.created_at DESC 
        LIMIT 10
      ''');
      }

      final albums =
          maps
              .map((map) {
                try {
                  final albumMap = Map<String, dynamic>.from(map);
                  albumMap['artist_name'] ??= 'Unknown Artist';
                  albumMap['image'] ??= '';
                  return AlbumModel.fromJson(albumMap);
                } catch (e) {
                  print('⚠️ Error parsing latest album: $e');
                  return null;
                }
              })
              .where((album) => album != null)
              .cast<AlbumModel>()
              .toList();

      return {
        'success': true,
        'albums': albums,
        'language': languageCode,
        'message': 'Latest albums loaded from cache',
        'source': 'cache',
      };
    } catch (e) {
      print('❌ Error loading latest albums from cache: $e');
      return {
        'success': false,
        'albums': <AlbumModel>[],
        'message': 'Error loading latest albums: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _getCachedAlbumSongs(int albumId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, albums.name as album_name
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.album_id = ? AND songs.synced != -1
      ORDER BY songs.track_number ASC
    ''',
      [albumId],
    );

    return {
      'success': true,
      'songs': maps,
      'message': 'Album songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _createAlbumLocally(AlbumModel album) async {
    final db = await _dbHelper.database;

    // Generate temporary negative ID for local-only records
    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    final now = DateTime.now().toIso8601String();

    final albumData =
        album.toCreateJson()
          ..['id'] = tempId
          ..['synced'] =
              0 // Mark as pending sync
          ..['created_at'] = now
          ..['updated_at'] = now;

    await db.insert('albums', albumData);

    final createdAlbum = AlbumModel.fromJson(albumData);

    return {
      'success': true,
      'album': createdAlbum,
      'message': '💾 Album saved locally, will sync when online',
      'source': 'local',
      'pending_sync': true,
    };
  }

  Future<Map<String, dynamic>> _updateAlbumLocally(
    int id,
    AlbumModel album,
  ) async {
    final db = await _dbHelper.database;

    final updateData =
        album.toCreateJson()
          ..['synced'] =
              0 // Mark as pending sync
          ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'albums',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsAffected > 0) {
      final updatedAlbum = album.copyWith(id: id, synced: 0);
      return {
        'success': true,
        'album': updatedAlbum,
        'message': '💾 Album updated locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Album not found in local database'};
    }
  }

  Future<Map<String, dynamic>> _markAlbumForDeletion(int id) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'albums',
      {
        'synced': -1, // Mark for deletion
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsAffected > 0) {
      return {
        'success': true,
        'message': '🗑️ Album marked for deletion, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {'success': false, 'message': 'Album not found in local database'};
    }
  }

  Future<void> _deleteAlbumFromCache(int id) async {
    final db = await _dbHelper.database;
    await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> _searchCachedAlbums(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT albums.*, artists.name as artist_name, artists.image as artist_image
      FROM albums 
      LEFT JOIN artists ON albums.artist_id = artists.id 
      WHERE albums.synced != -1 AND (
        albums.name LIKE ? OR 
        artists.name LIKE ? OR 
        albums.description LIKE ?
      )
      ORDER BY albums.created_at DESC
    ''',
      ['%$query%', '%$query%', '%$query%'],
    );

    final albums = maps.map((map) => AlbumModel.fromJson(map)).toList();

    return {
      'success': true,
      'albums': albums,
      'message': '🔍 Search completed in cache',
      'source': 'cache',
    };
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;

    // Sync deletions first
    await _syncPendingDeletions(db);

    // Sync creations and updates
    await _syncPendingChanges(db);
  }

  Future<void> _syncPendingDeletions(Database db) async {
    final deletionMaps = await db.query(
      'albums',
      where: 'synced = ?',
      whereArgs: [-1],
    );

    for (final map in deletionMaps) {
      final albumId = map['id'] as int;
      if (albumId > 0) {
        // Only sync server records
        try {
          final result = await _onlineService.deleteAlbum(albumId);
          if (result['success']) {
            await db.delete('albums', where: 'id = ?', whereArgs: [albumId]);
            print('✅ Synced deletion for album $albumId');
          }
        } catch (e) {
          print('❌ Failed to sync deletion for album $albumId: $e');
        }
      } else {
        // Local-only record, just delete it
        await db.delete('albums', where: 'id = ?', whereArgs: [albumId]);
      }
    }
  }

  Future<void> _syncPendingChanges(Database db) async {
    final unsyncedMaps = await db.query(
      'albums',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (final map in unsyncedMaps) {
      final album = AlbumModel.fromJson(map);

      try {
        if (album.id! < 0) {
          // This is a locally created album
          final result = await _onlineService.createAlbum(album);
          if (result['success']) {
            final serverAlbum = result['album'] as AlbumModel;
            // Replace local record with server record
            await db.delete('albums', where: 'id = ?', whereArgs: [album.id]);
            await db.insert('albums', serverAlbum.toFullJson()..['synced'] = 1);
            print('✅ Synced local album creation: ${album.name}');
          }
        } else {
          // This is an updated album
          final result = await _onlineService.updateAlbum(album.id!, album);
          if (result['success']) {
            await db.update(
              'albums',
              {'synced': 1},
              where: 'id = ?',
              whereArgs: [album.id],
            );
            print('✅ Synced album update: ${album.name}');
          }
        }
      } catch (e) {
        print('❌ Failed to sync album ${album.id}: $e');
      }
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM albums WHERE synced = 0 OR synced = -1',
    );
    return result.first['count'] as int;
  }

  void dispose() {
    _onlineService.dispose();
  }
}
