// services/sync_manager.dart - Enhanced with proactive image caching
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/image_cache_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Service/setlist_service.dart';
import 'package:lyrics/Service/worship_note_service.dart';
import 'package:lyrics/Models/artist_model.dart';
import 'package:lyrics/Models/song_model.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  static bool _isSyncing = false;
  static bool _isImageCaching = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final ProactiveImageCacheManager _imageCacheManager =
      ProactiveImageCacheManager.instance;

  // Progress callbacks
  Function(String stage, int progress, int total)? onSyncProgress;
  Function(String message, bool isError)? onSyncMessage;
  Function(int cached, int total, int failed)? onImageCacheProgress;

  // Enhanced performFullSync with image caching
  Future<void> performFullSync({
    bool includeImageCaching = true,
    Function(String, int, int)? progressCallback,
    Function(String, bool)? messageCallback,
    Function(int, int, int)? imageCacheCallback,
  }) async {
    if (_isSyncing || !await _connectivityManager.isConnected()) return;

    _isSyncing = true;
    onSyncProgress = progressCallback;
    onSyncMessage = messageCallback;
    onImageCacheProgress = imageCacheCallback;

    try {
      _notifyProgress('Starting full sync...', 0, includeImageCaching ? 7 : 6);
      _notifyMessage('🔄 Starting comprehensive sync...', false);

      // Step 1: Sync Artists
      _notifyProgress('Syncing artists...', 1, includeImageCaching ? 7 : 6);
      await _syncArtists();

      // Step 2: Sync Albums
      _notifyProgress('Syncing albums...', 2, includeImageCaching ? 7 : 6);
      await _syncAlbums();

      // Step 3: Sync Songs
      _notifyProgress('Syncing songs...', 3, includeImageCaching ? 7 : 6);
      await _syncSongs();

      // Step 4: Sync Group Songs (if available)
      _notifyProgress('Syncing group songs...', 4, includeImageCaching ? 7 : 6);
      await _syncGroupSongs();

      // Step 5: Sync User Data
      _notifyProgress('Syncing user data...', 5, includeImageCaching ? 7 : 6);
      await _syncUserData();

      // Step 6: Cache Images Proactively
      if (includeImageCaching) {
        _notifyProgress('Caching images...', 6, 7);
        await _cacheAllImages();
      }

      // Step 7: Update sync time and cleanup
      _notifyProgress(
        'Finalizing sync...',
        includeImageCaching ? 7 : 6,
        includeImageCaching ? 7 : 6,
      );
      await _updateLastSyncTime();
      await _cleanupOldData();

      _notifyProgress(
        'Sync completed!',
        includeImageCaching ? 7 : 6,
        includeImageCaching ? 7 : 6,
      );
      _notifyMessage('✅ Full sync completed successfully', false);

      // Log final statistics
      final stats = await getSyncStats();
      print('📊 Final sync stats: $stats');
    } catch (e) {
      _notifyMessage('❌ Sync failed: $e', true);
      print('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Enhanced _syncArtists with image URL collection
  Future<void> _syncArtists() async {
    try {
      print('📡 Syncing artists...');
      final artistService = ArtistService();
      final result = await artistService.getAllArtists();

      if (result['success']) {
        final artistsData = result['artists'] as List<dynamic>;
        final db = await _dbHelper.database;
        final imageUrls = <String>[];

        for (final artistData in artistsData) {
          Map<String, dynamic> artistJson;
          if (artistData is ArtistModel) {
            artistJson = artistData.toJson();
            // Collect image URL
            if (artistData.image != null && artistData.image!.isNotEmpty) {
              imageUrls.add(artistData.image!);
            }
          } else if (artistData is Map<String, dynamic>) {
            artistJson = Map<String, dynamic>.from(artistData);
            // Collect image URL
            final imageUrl = artistJson['image'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              imageUrls.add(imageUrl);
            }
          } else {
            continue;
          }

          artistJson['synced'] = 1;
          artistJson['updated_at'] = DateTime.now().toIso8601String();

          await db.insert(
            'artists',
            artistJson,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        print('✅ Synced ${artistsData.length} artists');

        // Cache artist images immediately in background
        if (imageUrls.isNotEmpty) {
          _cacheImagesInBackground('artist', imageUrls);
        }
      }
    } catch (e) {
      print('❌ Artist sync failed: $e');
      _notifyMessage('❌ Artist sync failed: $e', true);
    }
  }

  // Enhanced _syncAlbums with image URL collection
  Future<void> _syncAlbums() async {
    try {
      print('📡 Syncing albums...');
      final albumService = AlbumService();
      final result = await albumService.getAllAlbums();

      if (result['success']) {
        final albumsData = result['albums'] as List<dynamic>;
        final db = await _dbHelper.database;
        final imageUrls = <String>[];

        for (final albumData in albumsData) {
          Map<String, dynamic> albumJson;
          if (albumData is AlbumModel) {
            albumJson = albumData.toFullJson();
            // Collect album and artist image URLs
            if (albumData.image != null && albumData.image!.isNotEmpty) {
              imageUrls.add(albumData.image!);
            }
            if (albumData.artistImage != null &&
                albumData.artistImage!.isNotEmpty) {
              imageUrls.add(albumData.artistImage!);
            }
          } else if (albumData is Map<String, dynamic>) {
            albumJson = Map<String, dynamic>.from(albumData);
            // Collect image URLs
            final albumImage = albumJson['image'] as String?;
            final artistImage = albumJson['artist_image'] as String?;
            if (albumImage != null && albumImage.isNotEmpty) {
              imageUrls.add(albumImage);
            }
            if (artistImage != null && artistImage.isNotEmpty) {
              imageUrls.add(artistImage);
            }
          } else {
            continue;
          }

          albumJson['synced'] = 1;
          albumJson['updated_at'] = DateTime.now().toIso8601String();

          await db.insert(
            'albums',
            albumJson,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        print('✅ Synced ${albumsData.length} albums');

        // Cache album images immediately in background
        if (imageUrls.isNotEmpty) {
          _cacheImagesInBackground('album', imageUrls);
        }
      }
    } catch (e) {
      print('❌ Album sync failed: $e');
      _notifyMessage('❌ Album sync failed: $e', true);
    }
  }

  // Enhanced _syncSongs with image URL collection
  Future<void> _syncSongs() async {
    try {
      print('📡 Syncing songs...');
      final songService = SongService();
      final result = await songService.getAllSongs();

      if (result['success']) {
        final songsData = result['songs'] as List<dynamic>;
        final db = await _dbHelper.database;
        final imageUrls = <String>[];

        for (final songData in songsData) {
          Map<String, dynamic> songJson;
          if (songData is SongModel) {
            songJson = songData.toJson();
            // Collect song, album, and artist image URLs
            if (songData.image != null && songData.image!.isNotEmpty) {
              imageUrls.add(songData.image!);
            }
            if (songData.albumImage != null &&
                songData.albumImage!.isNotEmpty) {
              imageUrls.add(songData.albumImage!);
            }
          } else if (songData is Map<String, dynamic>) {
            songJson = Map<String, dynamic>.from(songData);
            // Collect image URLs
            final songImage = songJson['image'] as String?;
            final albumImage = songJson['album_image'] as String?;
            final artistImage = songJson['artist_image'] as String?;

            if (songImage != null && songImage.isNotEmpty) {
              imageUrls.add(songImage);
            }
            if (albumImage != null && albumImage.isNotEmpty) {
              imageUrls.add(albumImage);
            }
            if (artistImage != null && artistImage.isNotEmpty) {
              imageUrls.add(artistImage);
            }
          } else {
            continue;
          }

          songJson['synced'] = 1;
          songJson['updated_at'] = DateTime.now().toIso8601String();

          await db.insert(
            'songs',
            songJson,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        print('✅ Synced ${songsData.length} songs');

        // Cache song images immediately in background
        if (imageUrls.isNotEmpty) {
          _cacheImagesInBackground('song', imageUrls);
        }
      }
    } catch (e) {
      print('❌ Song sync failed: $e');
      _notifyMessage('❌ Song sync failed: $e', true);
    }
  }

  // New method: Sync Group Songs with image caching
  Future<void> _syncGroupSongs() async {
    try {
      print('📡 Syncing group songs...');

      // Note: You'll need to implement this based on your GroupSongService
      // This is a template - adjust according to your actual service
      /*
      final groupSongService = GroupSongService(); // Adjust class name
      final result = await groupSongService.getAllGroupSongs();

      if (result['success']) {
        final groupSongsData = result['groupSongs'] as List<dynamic>;
        final db = await _dbHelper.database;
        final imageUrls = <String>[];

        // Begin transaction for group songs and their artists
        await db.transaction((txn) async {
          for (final groupSongData in groupSongsData) {
            final groupSongJson = Map<String, dynamic>.from(groupSongData);
            
            // Collect group song image
            final groupSongImage = groupSongJson['image'] as String?;
            if (groupSongImage != null && groupSongImage.isNotEmpty) {
              imageUrls.add(groupSongImage);
            }

            groupSongJson['synced'] = 1;
            groupSongJson['updated_at'] = DateTime.now().toIso8601String();

            await txn.insert(
              'group_songs',
              groupSongJson,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Handle associated artists
            final artists = groupSongJson['artists'] as List<dynamic>? ?? [];
            final groupSongId = groupSongJson['id'];
            
            // Clear existing associations
            await txn.delete(
              'group_song_artists',
              where: 'group_song_id = ?',
              whereArgs: [groupSongId],
            );

            // Add current associations
            for (final artist in artists) {
              final artistMap = Map<String, dynamic>.from(artist);
              
              // Collect artist image
              final artistImage = artistMap['image'] as String?;
              if (artistImage != null && artistImage.isNotEmpty) {
                imageUrls.add(artistImage);
              }

              await txn.insert(
                'group_song_artists',
                {
                  'group_song_id': groupSongId,
                  'artist_id': artistMap['id'],
                  'artist_name': artistMap['name'],
                  'artist_image': artistImage,
                  'synced': 1,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        });

        print('✅ Synced ${groupSongsData.length} group songs');
        
        // Cache group song images in background
        if (imageUrls.isNotEmpty) {
          _cacheImagesInBackground('group_song', imageUrls);
        }
      }
      */

      print('ℹ️ Group song sync not implemented yet');
    } catch (e) {
      print('❌ Group song sync failed: $e');
      _notifyMessage('❌ Group song sync failed: $e', true);
    }
  }

  // Cache images in background for specific type
  Future<void> _cacheImagesInBackground(
    String type,
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) return;

    // Remove duplicates
    final uniqueUrls = imageUrls.toSet().toList();
    print(
      '📸 Queuing ${uniqueUrls.length} $type images for background caching...',
    );

    // Cache in background without blocking the sync process
    Future.microtask(() async {
      try {
        int cached = 0;
        for (final url in uniqueUrls) {
          try {
            final cachedFile = await _imageCacheManager.getCachedImage(url);
            if (cachedFile == null) {
              await _imageCacheManager.downloadAndCacheImage(url);
            }
            cached++;
          } catch (e) {
            print('Failed to cache $type image: $url');
          }
        }
        print('✅ Background cached $cached/$uniqueUrls.length} $type images');
      } catch (e) {
        print('❌ Background image caching failed for $type: $e');
      }
    });
  }

  // Enhanced comprehensive image caching
  Future<void> _cacheAllImages() async {
    if (_isImageCaching) return;

    _isImageCaching = true;

    try {
      _notifyMessage('📸 Starting comprehensive image caching...', false);

      await _imageCacheManager.cacheAllSystemImages(
        progressCallback: (cached, total, failed) {
          onImageCacheProgress?.call(cached, total, failed);

          if (total > 0) {
            final progressPercent = ((cached + failed) / total * 100).round();
            _notifyMessage(
              '📸 Caching images: $cached/$total (failed: $failed)',
              false,
            );
          }

          if (cached + failed == total) {
            final message =
                failed == 0
                    ? '✅ All $total images cached successfully!'
                    : '⚠️ Cached $cached/$total images ($failed failed)';
            _notifyMessage(message, failed > 0);
          }
        },
      );
    } catch (e) {
      _notifyMessage('❌ Image caching failed: $e', true);
    } finally {
      _isImageCaching = false;
    }
  }

  // Clean up old data and cache
  Future<void> _cleanupOldData() async {
    try {
      _notifyMessage('🧹 Cleaning up old data...', false);

      // Clean old image cache (older than 30 days)
      await _imageCacheManager.cleanOldCache(maxAgeInDays: 30);

      print('✅ Cleanup completed');
    } catch (e) {
      print('❌ Cleanup failed: $e');
    }
  }

  // Get comprehensive sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final db = await _dbHelper.database;

      // Get data counts
      final artistResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM artists WHERE synced != -1',
      );
      final albumResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM albums WHERE synced != -1',
      );
      final songResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM songs WHERE synced != -1',
      );
      final groupSongResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM group_songs WHERE synced != -1',
      );

      // Get image cache stats
      final imageStats = await _imageCacheManager.getCacheStats();

      // Get last sync time
      final lastSync = await getLastSyncTime();

      return {
        'artists': artistResult.first['count'] as int,
        'albums': albumResult.first['count'] as int,
        'songs': songResult.first['count'] as int,
        'groupSongs': groupSongResult.first['count'] as int,
        'imageCache': imageStats,
        'lastSyncTime': lastSync?.toIso8601String(),
        'syncInProgress': _isSyncing,
        'imageCachingInProgress': _isImageCaching,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'syncInProgress': _isSyncing,
        'imageCachingInProgress': _isImageCaching,
      };
    }
  }

  // **Your existing methods remain the same**
  Future<void> _syncUserData() async {
    try {
      print('📡 Syncing user data...');

      final userId = await UserService.getUserID();
      if (userId.isEmpty) {
        print('ℹ️ No user logged in, skipping user data sync');
        return;
      }

      final userIdInt = int.parse(userId);
      await _syncUserFavorites(userIdInt);
      await _syncUserSetlists(userIdInt);
      await _syncWorshipNotes(userIdInt);

      print('✅ User data sync completed');
    } catch (e) {
      print('❌ User data sync failed: $e');
      _notifyMessage('❌ User data sync failed: $e', true);
    }
  }

  Future<void> _syncUserFavorites(int userId) async {
    try {
      print('📡 Syncing user favorites...');
      print('✅ User favorites synced');
    } catch (e) {
      print('❌ User favorites sync failed: $e');
    }
  }

  Future<void> _syncUserSetlists(int userId) async {
    try {
      print('📡 Syncing user setlists...');

      final setlistResult = await SetListService.getFolders(userId.toString());
      if (setlistResult['success']) {
        final foldersData = setlistResult['data'];
        if (foldersData == null) {
          print('ℹ️ No setlist folders found for user $userId');
          return;
        }

        final folders = foldersData as List<dynamic>;
        final db = await _dbHelper.database;

        print('📁 Found ${folders.length} folders to sync');

        for (final folder in folders) {
          try {
            if (folder == null) continue;

            final folderData = Map<String, dynamic>.from(folder);
            folderData['synced'] = 1;
            folderData['created_at'] ??= DateTime.now().toIso8601String();
            folderData['updated_at'] ??= DateTime.now().toIso8601String();

            await db.insert(
              'setlist_folders',
              folderData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            final folderId = folder['id'];
            if (folderId != null) {
              await _syncFolderSongs(folderId as int);
            }
          } catch (e) {
            print('⚠️ Error syncing folder: $e');
            continue;
          }
        }

        print('✅ User setlists synced');
      } else {
        print('ℹ️ Setlist sync failed: ${setlistResult['message']}');
      }
    } catch (e) {
      print('❌ User setlists sync failed: $e');
    }
  }

  Future<void> _syncFolderSongs(int folderId) async {
    try {
      final songsResult = await SetListService.getFolderSongs(folderId);
      if (songsResult['success']) {
        final songs = songsResult['data'] as List<dynamic>;
        final db = await _dbHelper.database;

        for (final song in songs) {
          await db.insert('setlist_songs', {
            ...Map<String, dynamic>.from(song),
            'synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      print('❌ Folder songs sync failed: $e');
    }
  }

  Future<void> _syncWorshipNotes(int userId) async {
    try {
      print('📡 Syncing worship notes...');

      final worshipNotesService = WorshipNotesService();
      final notesResult = await worshipNotesService.getUserWorshipNotes();

      if (notesResult['success']) {
        final notes = notesResult['notes'] as List<dynamic>;
        final db = await _dbHelper.database;

        for (final note in notes) {
          await db.insert('worship_notes', {
            ...Map<String, dynamic>.from(note),
            'synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        print('✅ Worship notes synced');
      }
    } catch (e) {
      print('❌ Worship notes sync failed: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
    await prefs.setString(
      'last_image_cache_time',
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString('last_sync_time');
    return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
  }

  Future<DateTime?> getLastImageCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCacheString = prefs.getString('last_image_cache_time');
    return lastCacheString != null ? DateTime.parse(lastCacheString) : null;
  }

  Future<Map<String, int>> getSyncStatus() async {
    final db = await _dbHelper.database;

    final tables = [
      'albums',
      'songs',
      'artists',
      'user_favorites',
      'setlist_folders',
      'setlist_songs',
      'worship_notes',
      'group_songs',
    ];
    final status = <String, int>{};

    for (final table in tables) {
      try {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $table WHERE synced = 0 OR synced = -1',
        );
        status[table] = result.first['count'] as int;
      } catch (e) {
        status[table] = 0;
      }
    }

    return status;
  }

  Future<int> getTotalPendingSyncCount() async {
    final syncStatus = await getSyncStatus();
    return syncStatus.values.fold<int>(0, (sum, count) => sum + count);
  }

  bool get isSyncing => _isSyncing;
  bool get isImageCaching => _isImageCaching;

  Future<void> forceSync() async {
    _isSyncing = false;
    _isImageCaching = false;
    await performFullSync();
  }

  Future<void> syncTable(String table) async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      switch (table) {
        case 'artists':
          await _syncArtists();
          break;
        case 'albums':
          await _syncAlbums();
          break;
        case 'songs':
          await _syncSongs();
          break;
        case 'group_songs':
          await _syncGroupSongs();
          break;
        case 'user_data':
          await _syncUserData();
          break;
        case 'images':
          await _cacheAllImages();
          break;
        default:
          print('❌ Unknown table: $table');
      }
    } catch (e) {
      print('❌ Table sync failed for $table: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // New method: Cache images only
  Future<void> cacheAllImagesOnly({
    Function(int, int, int)? progressCallback,
  }) async {
    if (_isImageCaching) return;

    onImageCacheProgress = progressCallback;
    await _cacheAllImages();
  }

  // Utility methods for notifications
  void _notifyProgress(String stage, int progress, int total) {
    onSyncProgress?.call(stage, progress, total);
    print('📊 $stage ($progress/$total)');
  }

  void _notifyMessage(String message, bool isError) {
    onSyncMessage?.call(message, isError);
    print(message);
  }
}
