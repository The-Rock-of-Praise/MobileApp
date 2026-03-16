// Enhanced ArtistModel with offline support
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:sqflite/sqflite.dart';

// Offline-first Artist Service
class OfflineArtistService {
  final ArtistService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineArtistService({ArtistService? onlineService})
    : _onlineService = onlineService ?? ArtistService();

  // Get all artists with offline support
  Future<Map<String, dynamic>> getAllArtists() async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching artists from server...');
        final result = await _onlineService.getAllArtists();
        if (result['success']) {
          await _cacheArtists(result['artists']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedArtists();
  }

  // Get artists by language with offline support
  Future<Map<String, dynamic>> getArtistsByLanguage(String language) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Fetching artists for language: $language from server...');
        final result = await _onlineService.getArtistsByLanguage(language);
        if (result['success']) {
          // Cache with proper language association
          await _cacheArtistsByLanguage(result['artists'], language);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    // Always try cache when offline or when online fails
    print('📱 Loading artists for language: $language from cache...');
    return await _getCachedArtistsByLanguage(language);
  }

  Future<void> _cacheArtistsByLanguage(
    List<ArtistModel> artists,
    String language,
  ) async {
    final db = await _dbHelper.database;

    for (final artist in artists) {
      final artistData =
          artist.toJson()
            ..['synced'] = 1
            ..['language'] =
                language // Ensure language is stored
            ..['updated_at'] = DateTime.now().toIso8601String();

      await db.insert(
        'artists',
        artistData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${artists.length} artists for language: $language');
  }

  // Get artist by ID with offline support
  Future<Map<String, dynamic>> getArtistById(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getArtistById(id);
        if (result['success']) {
          await _cacheArtists([result['artist']]);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedArtistById(id);
  }

  // Get artist albums with offline support
  Future<Map<String, dynamic>> getArtistAlbums(int artistId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.getArtistAlbums(artistId);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedArtistAlbums(artistId);
  }

  // Get artist songs with offline support
  Future<Map<String, dynamic>> getArtistSongs(int artistId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        // Fetch regular songs
        final songsResult = await _onlineService.getArtistSongs(artistId);

        // Fetch group songs where artist is a collaborator
        List<dynamic> groupSongs = [];
        try {
          final groupSongsService = OfflineGroupSongService();
          final groupResult = await groupSongsService.getGroupSongsByArtist(
            artistId,
          );
          if (groupResult['success'] == true) {
            groupSongs = groupResult['groupSongs'] ?? [];
          }
        } catch (e) {
          print('⚠️ Failed to fetch group songs for artist: $e');
        }

        if (songsResult['success']) {
          // Combine regular songs and group songs
          final List<dynamic> allSongs = [
            ...(songsResult['songs'] ?? []),
            ...groupSongs,
          ];

          return {
            'success': true,
            'songs': allSongs,
            'message': songsResult['message'],
            'source': 'online',
          };
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedArtistSongs(artistId);
  }

  // Create artist with offline support
  Future<Map<String, dynamic>> createArtist(ArtistModel artist) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.createArtist(artist);
        if (result['success']) {
          await _cacheArtists([result['artist']]);
          return result;
        }
      } catch (e) {
        print('❌ Online creation failed, saving locally: $e');
      }
    }

    return await _createArtistLocally(artist);
  }

  // Update artist with offline support
  Future<Map<String, dynamic>> updateArtist(int id, ArtistModel artist) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.updateArtist(id, artist);
        if (result['success']) {
          await _cacheArtists([result['artist']]);
          return result;
        }
      } catch (e) {
        print('❌ Online update failed, saving locally: $e');
      }
    }

    return await _updateArtistLocally(id, artist);
  }

  // Delete artist with offline support
  Future<Map<String, dynamic>> deleteArtist(int id) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await _onlineService.deleteArtist(id);
        if (result['success']) {
          await _deleteArtistFromCache(id);
          return result;
        }
      } catch (e) {
        print('❌ Online delete failed, marking for deletion: $e');
      }
    }

    return await _markArtistForDeletion(id);
  }

  // Private methods for caching and local operations
  Future<void> _cacheArtists(List<ArtistModel> artists) async {
    final db = await _dbHelper.database;

    for (final artist in artists) {
      final artistData = artist.toJson()..['synced'] = 1;
      await db.insert(
        'artists',
        artistData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Cached ${artists.length} artists');
  }

  Future<Map<String, dynamic>> _getCachedArtists() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artists',
      where: 'synced != ?',
      whereArgs: [-1],
      orderBy: 'created_at DESC',
    );

    final artists = maps.map((map) => ArtistModel.fromJson(map)).toList();

    return {
      'success': true,
      'artists': artists,
      'message': 'Artists loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedArtistsByLanguage(
    String language,
  ) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.query(
        'artists',
        where: 'language = ? AND synced != ?',
        whereArgs: [language, -1],
        orderBy: 'created_at DESC',
      );

      final artists =
          maps
              .map((map) {
                try {
                  return ArtistModel.fromJson(map);
                } catch (e) {
                  print('⚠️ Error parsing artist from cache: $e');
                  print('Raw data: $map');
                  return null;
                }
              })
              .where((artist) => artist != null)
              .cast<ArtistModel>()
              .toList();

      // If no artists found for this language, try to get any available artists
      if (artists.isEmpty) {
        print('⚠️ No cached artists found for language: $language');
        final fallbackMaps = await db.query(
          'artists',
          where: 'synced != ?',
          whereArgs: [-1],
          orderBy: 'created_at DESC',
          limit: 10,
        );

        final fallbackArtists =
            fallbackMaps
                .map((map) {
                  try {
                    return ArtistModel.fromJson(map);
                  } catch (e) {
                    return null;
                  }
                })
                .where((artist) => artist != null)
                .cast<ArtistModel>()
                .toList();

        return {
          'success': true,
          'artists': fallbackArtists,
          'language': language,
          'message': 'Showing cached artists (language fallback)',
          'source': 'cache_fallback',
        };
      }

      return {
        'success': true,
        'artists': artists,
        'language': language,
        'languageDisplayName': _getLanguageDisplayName(language),
        'message': 'Artists loaded from cache',
        'source': 'cache',
      };
    } catch (e) {
      print('❌ Error loading cached artists: $e');
      return {
        'success': false,
        'artists': <ArtistModel>[],
        'message': 'Error loading cached artists: $e',
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

  Future<Map<String, dynamic>> _getCachedArtistById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'artists',
      where: 'id = ? AND synced != ?',
      whereArgs: [id, -1],
    );

    if (maps.isNotEmpty) {
      final artist = ArtistModel.fromJson(maps.first);
      return {
        'success': true,
        'artist': artist,
        'message': 'Artist loaded from cache',
        'source': 'cache',
      };
    } else {
      return {'success': false, 'message': 'Artist not found in cache'};
    }
  }

  Future<Map<String, dynamic>> _getCachedArtistAlbums(int artistId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'albums',
      where: 'artist_id = ? AND synced != ?',
      whereArgs: [artistId, -1],
      orderBy: 'created_at DESC',
    );

    return {
      'success': true,
      'albums': maps,
      'message': 'Artist albums loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedArtistSongs(int artistId) async {
    final db = await _dbHelper.database;

    // Fetch regular songs
    final songMaps = await db.rawQuery(
      '''
      SELECT songs.*, artists.name as artist_name, albums.name as album_name
      FROM songs 
      LEFT JOIN artists ON songs.artist_id = artists.id 
      LEFT JOIN albums ON songs.album_id = albums.id
      WHERE songs.artist_id = ? AND songs.synced != -1
      ORDER BY songs.created_at DESC
    ''',
      [artistId],
    );

    // Fetch group songs where artist is a collaborator
    List<dynamic> groupSongs = [];
    try {
      final groupSongsService = OfflineGroupSongService();
      final groupResult = await groupSongsService.getGroupSongsByArtist(
        artistId,
      );
      if (groupResult['success'] == true) {
        groupSongs = groupResult['groupSongs'] ?? [];
      }
    } catch (e) {
      print('⚠️ Failed to fetch cached group songs for artist: $e');
    }

    // Combine both lists
    final allSongs = [...songMaps, ...groupSongs];

    return {
      'success': true,
      'songs': allSongs,
      'message': 'Artist songs loaded from cache',
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _createArtistLocally(ArtistModel artist) async {
    final db = await _dbHelper.database;

    // Generate temporary negative ID for local-only records
    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    final now = DateTime.now().toIso8601String();

    final artistData =
        artist.toCreateJson()
          ..['id'] = tempId
          ..['synced'] =
              0 // Mark as pending sync
          ..['created_at'] = now
          ..['updated_at'] = now;

    await db.insert('artists', artistData);

    final createdArtist = ArtistModel.fromJson(artistData);

    return {
      'success': true,
      'artist': createdArtist,
      'message': '💾 Artist saved locally, will sync when online',
      'source': 'local',
      'pending_sync': true,
    };
  }

  Future<Map<String, dynamic>> _updateArtistLocally(
    int id,
    ArtistModel artist,
  ) async {
    final db = await _dbHelper.database;

    final updateData =
        artist.toCreateJson()
          ..['synced'] =
              0 // Mark as pending sync
          ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'artists',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsAffected > 0) {
      final updatedArtist = artist.copyWith(id: id, synced: 0);
      return {
        'success': true,
        'artist': updatedArtist,
        'message': '💾 Artist updated locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {
        'success': false,
        'message': 'Artist not found in local database',
      };
    }
  }

  Future<Map<String, dynamic>> _markArtistForDeletion(int id) async {
    final db = await _dbHelper.database;

    final rowsAffected = await db.update(
      'artists',
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
        'message': '🗑️ Artist marked for deletion, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } else {
      return {
        'success': false,
        'message': 'Artist not found in local database',
      };
    }
  }

  Future<void> _deleteArtistFromCache(int id) async {
    final db = await _dbHelper.database;
    await db.delete('artists', where: 'id = ?', whereArgs: [id]);
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
      'artists',
      where: 'synced = ?',
      whereArgs: [-1],
    );

    for (final map in deletionMaps) {
      final artistId = map['id'] as int;
      if (artistId > 0) {
        // Only sync server records
        try {
          final result = await _onlineService.deleteArtist(artistId);
          if (result['success']) {
            await db.delete('artists', where: 'id = ?', whereArgs: [artistId]);
            print('✅ Synced deletion for artist $artistId');
          }
        } catch (e) {
          print('❌ Failed to sync deletion for artist $artistId: $e');
        }
      } else {
        // Local-only record, just delete it
        await db.delete('artists', where: 'id = ?', whereArgs: [artistId]);
      }
    }
  }

  Future<void> _syncPendingChanges(Database db) async {
    final unsyncedMaps = await db.query(
      'artists',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (final map in unsyncedMaps) {
      final artist = ArtistModel.fromJson(map);

      try {
        if (artist.id! < 0) {
          // This is a locally created artist
          final result = await _onlineService.createArtist(artist);
          if (result['success']) {
            final serverArtist = result['artist'] as ArtistModel;
            // Replace local record with server record
            await db.delete('artists', where: 'id = ?', whereArgs: [artist.id]);
            await db.insert('artists', serverArtist.toJson()..['synced'] = 1);
            print('✅ Synced local artist creation: ${artist.name}');
          }
        } else {
          // This is an updated artist
          final result = await _onlineService.updateArtist(artist.id!, artist);
          if (result['success']) {
            await db.update(
              'artists',
              {'synced': 1},
              where: 'id = ?',
              whereArgs: [artist.id],
            );
            print('✅ Synced artist update: ${artist.name}');
          }
        }
      } catch (e) {
        print('❌ Failed to sync artist ${artist.id}: $e');
      }
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM artists WHERE synced = 0 OR synced = -1',
    );
    return result.first['count'] as int;
  }

  void dispose() {
    _onlineService.dispose();
  }
}
