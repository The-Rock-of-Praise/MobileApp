// OfflineService/offline_favorites_service.dart
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/favorites_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineFavoritesService {
  final FavoritesService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineFavoritesService({FavoritesService? onlineService})
    : _onlineService = onlineService ?? FavoritesService();

  // Check favorite status with offline support
  Future<Map<String, dynamic>> checkFavoriteStatus(
    String userId,
    int songId,
  ) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await FavoritesService.checkFavoriteStatus(
          userId,
          songId,
        );
        if (result['success']) {
          // Cache the result
          await _cacheFavoriteStatus(
            userId,
            songId,
            result['isFavorite'] ?? false,
          );
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online favorite check failed, using cache: $e');
      }
    }

    return await _getCachedFavoriteStatus(userId, songId);
  }

  // Add to favorites with offline support
  Future<Map<String, dynamic>> addToFavorites({
    required String userId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await FavoritesService.addToFavorites(
          userId: userId,
          songId: songId,
          songName: songName,
          artistName: artistName,
          songImage: songImage,
        );

        if (result['success']) {
          await _cacheFavoriteStatus(userId, songId, true);
          await _cacheFavoriteItem(
            userId,
            songId,
            songName,
            artistName,
            songImage,
          );
          return result;
        }
      } catch (e) {
        print('❌ Online add to favorites failed, saving locally: $e');
      }
    }

    return await _addToFavoritesLocally(
      userId: userId,
      songId: songId,
      songName: songName,
      artistName: artistName,
      songImage: songImage,
    );
  }

  // Remove from favorites with offline support
  Future<Map<String, dynamic>> removeFromFavorites({
    required String userId,
    required int songId,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await FavoritesService.removeFromFavorites(
          userId: userId,
          songId: songId,
        );

        if (result['success']) {
          await _removeFavoriteFromCache(userId, songId);
          return result;
        }
      } catch (e) {
        print(
          '❌ Online remove from favorites failed, marking for deletion: $e',
        );
      }
    }

    return await _markFavoriteForDeletion(userId, songId);
  }

  // Get user favorites with offline support
  Future<Map<String, dynamic>> getFavorites(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await FavoritesService.getFavorites(
          userId,
          limit: limit,
          offset: offset,
        );
        if (result['success']) {
          await _cacheFavorites(userId, result['favorites']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedFavorites(userId);
  }

  // Get favorite statistics with offline support
  Future<Map<String, dynamic>> getFavoriteStats(String userId) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await FavoritesService.getFavoriteStats(userId);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online stats fetch failed: $e');
      }
    }

    return await _getCachedFavoriteStats(userId);
  }

  // Private methods for caching and local operations
  Future<void> _cacheFavorites(String userId, List<dynamic> favorites) async {
    final db = await _dbHelper.database;

    try {
      // Clear existing favorites for this user
      await db.delete(
        'user_favorites',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Insert new favorites
      for (final favorite in favorites) {
        if (favorite == null) continue;

        final favoriteMap =
            favorite is Map<String, dynamic>
                ? favorite
                : Map<String, dynamic>.from(favorite);

        await db.insert('user_favorites', {
          'user_id': userId,
          'song_id': favoriteMap['song_id'],
          'song_name': favoriteMap['song_name'] ?? '',
          'artist_name': favoriteMap['artist_name'] ?? '',
          'song_image': favoriteMap['song_image'] ?? '',
          'created_at':
              favoriteMap['created_at'] ?? DateTime.now().toIso8601String(),
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      print('✅ Cached ${favorites.length} favorites for user $userId');
    } catch (e) {
      print('⚠️ Error caching favorites: $e');
    }
  }

  Future<Map<String, dynamic>> _getCachedFavoriteStatus(
    String userId,
    int songId,
  ) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.query(
        'user_favorites',
        where: 'user_id = ? AND song_id = ? AND synced != -1',
        whereArgs: [userId, songId],
        limit: 1,
      );

      return {
        'success': true,
        'isFavorite': maps.isNotEmpty,
        'source': 'cache',
      };
    } catch (e) {
      print('⚠️ Error getting cached favorite status: $e');
      return {
        'success': false,
        'message': 'Error checking favorite status: $e',
        'isFavorite': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getCachedFavorites(String userId) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.query(
        'user_favorites',
        where: 'user_id = ? AND synced != -1',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return {
        'success': true,
        'favorites': maps,
        'message': 'Favorites loaded from cache',
        'source': 'cache',
      };
    } catch (e) {
      print('⚠️ Error getting cached favorites: $e');
      return {
        'success': false,
        'message': 'Error loading favorites: $e',
        'favorites': <Map<String, dynamic>>[],
      };
    }
  }

  Future<Map<String, dynamic>> _getCachedFavoriteStats(String userId) async {
    final db = await _dbHelper.database;

    try {
      // Get total favorites count
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_favorites WHERE user_id = ? AND synced != -1',
        [userId],
      );
      final totalFavorites = totalResult.first['count'] as int;

      // Get unique artists count
      final artistsResult = await db.rawQuery(
        'SELECT COUNT(DISTINCT artist_name) as count FROM user_favorites WHERE user_id = ? AND synced != -1',
        [userId],
      );
      final favoriteArtists = artistsResult.first['count'] as int;

      // Get last added date
      final lastAddedResult = await db.rawQuery(
        'SELECT created_at FROM user_favorites WHERE user_id = ? AND synced != -1 ORDER BY created_at DESC LIMIT 1',
        [userId],
      );
      final lastAdded =
          lastAddedResult.isNotEmpty
              ? DateTime.parse(lastAddedResult.first['created_at'] as String)
              : null;

      // Get top artists
      final topArtistsResult = await db.rawQuery(
        'SELECT artist_name, COUNT(*) as count FROM user_favorites '
        'WHERE user_id = ? AND synced != -1 '
        'GROUP BY artist_name ORDER BY count DESC LIMIT 3',
        [userId],
      );

      final topArtists =
          topArtistsResult
              .map(
                (row) => {
                  'artist_name': row['artist_name'],
                  'count': row['count'],
                },
              )
              .toList();

      return {
        'success': true,
        'stats': {
          'total_favorites': totalFavorites,
          'favorite_artists': favoriteArtists,
          'last_added': lastAdded?.toIso8601String(),
          'topArtists': topArtists,
        },
        'source': 'cache',
      };
    } catch (e) {
      print('⚠️ Error getting cached favorite stats: $e');
      return {
        'success': false,
        'message': 'Error loading favorite stats: $e',
        'stats': {
          'total_favorites': 0,
          'favorite_artists': 0,
          'last_added': null,
          'topArtists': [],
        },
      };
    }
  }

  Future<Map<String, dynamic>> _addToFavoritesLocally({
    required String userId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
  }) async {
    final db = await _dbHelper.database;

    try {
      final tempId = -(DateTime.now().millisecondsSinceEpoch);

      await db.insert('user_favorites', {
        'id': tempId,
        'user_id': userId,
        'song_id': songId,
        'song_name': songName,
        'artist_name': artistName,
        'song_image': songImage,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0, // Mark as pending sync
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return {
        'success': true,
        'message': '💾 Added to favorites locally, will sync when online',
        'source': 'local',
        'pending_sync': true,
      };
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return {'success': false, 'message': 'Song already in favorites'};
      }
      return {'success': false, 'message': 'Failed to add to favorites: $e'};
    }
  }

  Future<Map<String, dynamic>> _markFavoriteForDeletion(
    String userId,
    int songId,
  ) async {
    final db = await _dbHelper.database;

    try {
      final rowsAffected = await db.update(
        'user_favorites',
        {'synced': -1}, // Mark for deletion
        where: 'user_id = ? AND song_id = ?',
        whereArgs: [userId, songId],
      );

      if (rowsAffected > 0) {
        return {
          'success': true,
          'message':
              '🗑️ Removed from favorites locally, will sync when online',
          'source': 'local',
          'pending_sync': true,
        };
      } else {
        return {'success': false, 'message': 'Favorite not found'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove from favorites: $e',
      };
    }
  }

  Future<void> _removeFavoriteFromCache(String userId, int songId) async {
    final db = await _dbHelper.database;

    try {
      await db.delete(
        'user_favorites',
        where: 'user_id = ? AND song_id = ?',
        whereArgs: [userId, songId],
      );
    } catch (e) {
      print('⚠️ Error removing favorite from cache: $e');
    }
  }

  Future<void> _cacheFavoriteStatus(
    String userId,
    int songId,
    bool isFavorite,
  ) async {
    final db = await _dbHelper.database;

    try {
      if (isFavorite) {
        // Insert or update favorite status
        await db.insert('user_favorites', {
          'user_id': userId,
          'song_id': songId,
          'song_name': '', // Will be updated when we have full data
          'artist_name': '',
          'song_image': '',
          'created_at': DateTime.now().toIso8601String(),
          'synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        // Remove from favorites if exists
        await db.delete(
          'user_favorites',
          where: 'user_id = ? AND song_id = ?',
          whereArgs: [userId, songId],
        );
      }
    } catch (e) {
      print('⚠️ Error caching favorite status: $e');
    }
  }

  Future<void> _cacheFavoriteItem(
    String userId,
    int songId,
    String songName,
    String artistName,
    String songImage,
  ) async {
    final db = await _dbHelper.database;

    try {
      await db.insert('user_favorites', {
        'user_id': userId,
        'song_id': songId,
        'song_name': songName,
        'artist_name': artistName,
        'song_image': songImage,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('⚠️ Error caching favorite item: $e');
    }
  }

  // Sync pending changes when back online
  Future<void> syncPendingChanges() async {
    final isConnected = await _connectivityManager.isConnected();
    if (!isConnected) return;

    final db = await _dbHelper.database;

    try {
      // Sync deletions first
      await _syncPendingDeletions(db);

      // Sync additions
      await _syncPendingAdditions(db);
    } catch (e) {
      print('❌ Error syncing pending favorite changes: $e');
    }
  }

  Future<void> _syncPendingDeletions(Database db) async {
    try {
      final deletionMaps = await db.query(
        'user_favorites',
        where: 'synced = ?',
        whereArgs: [-1],
      );

      for (final favoriteData in deletionMaps) {
        final favoriteId = favoriteData['id'] as int;
        final userId = favoriteData['user_id'].toString();
        final songId = favoriteData['song_id'] as int;

        try {
          if (favoriteId > 0) {
            // Server record - try to delete from server
            final result = await FavoritesService.removeFromFavorites(
              userId: userId,
              songId: songId,
            );

            if (result['success']) {
              await db.delete(
                'user_favorites',
                where: 'id = ?',
                whereArgs: [favoriteId],
              );
              print('✅ Synced favorite deletion: $songId');
            }
          } else {
            // Local-only record, just delete it
            await db.delete(
              'user_favorites',
              where: 'id = ?',
              whereArgs: [favoriteId],
            );
          }
        } catch (e) {
          print('❌ Failed to sync favorite deletion $favoriteId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending deletions: $e');
    }
  }

  Future<void> _syncPendingAdditions(Database db) async {
    try {
      final unsyncedMaps = await db.query(
        'user_favorites',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (final favoriteData in unsyncedMaps) {
        final favoriteId = favoriteData['id'] as int;

        try {
          if (favoriteId < 0) {
            // This is a locally created favorite
            final result = await FavoritesService.addToFavorites(
              userId: favoriteData['user_id'].toString(),
              songId: favoriteData['song_id'] as int,
              songName: favoriteData['song_name'] as String,
              artistName: favoriteData['artist_name'] as String,
              songImage: favoriteData['song_image'] as String,
            );

            if (result['success']) {
              // Mark as synced or replace with server record if available
              await db.update(
                'user_favorites',
                {'synced': 1},
                where: 'id = ?',
                whereArgs: [favoriteId],
              );
              print(
                '✅ Synced local favorite addition: ${favoriteData['song_name']}',
              );
            }
          }
        } catch (e) {
          print('❌ Failed to sync favorite $favoriteId: $e');
        }
      }
    } catch (e) {
      print('❌ Error syncing pending additions: $e');
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_favorites WHERE synced = 0 OR synced = -1',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error getting pending sync count: $e');
      return 0;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
