// proactive_image_cache_manager.dart - Enhanced image caching with proactive strategy
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';

class ProactiveImageCacheManager {
  static final ProactiveImageCacheManager _instance =
      ProactiveImageCacheManager._internal();
  static ProactiveImageCacheManager get instance => _instance;
  ProactiveImageCacheManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  static const String _cacheFolder = 'image_cache';
  static const int _maxConcurrentDownloads = 5;
  static const Duration _downloadTimeout = Duration(seconds: 30);

  bool _isPreloadingInProgress = false;
  int _totalImages = 0;
  int _cachedImages = 0;
  int _failedImages = 0;

  // Callback for progress updates
  Function(int cached, int total, int failed)? onProgressUpdate;

  // Get cache directory
  Future<Directory> get _cacheDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheFolder');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  // Generate cache key from URL
  String _getCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  // Check if image is cached
  Future<File?> getCachedImage(String url) async {
    try {
      final cacheDir = await _cacheDirectory;
      final cacheKey = _getCacheKey(url);
      final file = File('${cacheDir.path}/$cacheKey.jpg');

      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          return file;
        } else {
          await file.delete();
        }
      }

      return null;
    } catch (e) {
      print('Error checking cached image: $e');
      return null;
    }
  }

  // Download and cache single image
  Future<File?> downloadAndCacheImage(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'image/*', 'User-Agent': 'Flutter App'},
          )
          .timeout(_downloadTimeout);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final cacheDir = await _cacheDirectory;
        final cacheKey = _getCacheKey(url);
        final file = File('${cacheDir.path}/$cacheKey.jpg');

        await file.writeAsBytes(response.bodyBytes);

        // Update cache metadata in database
        await _updateCacheMetadata(url, file.path, response.bodyBytes.length);

        return file;
      } else {
        print(
          '❌ Failed to download image: HTTP ${response.statusCode} for $url',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image $url: $e');
      return null;
    }
  }

  // Update cache metadata in database
  Future<void> _updateCacheMetadata(
    String url,
    String localPath,
    int fileSize,
  ) async {
    try {
      final db = await _dbHelper.database;

      // Create cache metadata table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS image_cache_metadata(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_url TEXT UNIQUE NOT NULL,
          local_path TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          cached_at TEXT NOT NULL,
          last_accessed TEXT NOT NULL
        )
      ''');

      final now = DateTime.now().toIso8601String();
      await db.insert('image_cache_metadata', {
        'image_url': url,
        'local_path': localPath,
        'file_size': fileSize,
        'cached_at': now,
        'last_accessed': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error updating cache metadata: $e');
    }
  }

  // Get image provider with caching
  Future<ImageProvider?> getImageProvider(String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }

    try {
      // First check cache
      final cachedFile = await getCachedImage(url);
      if (cachedFile != null) {
        // Update last accessed time
        await _updateLastAccessed(url);
        return FileImage(cachedFile);
      }

      // If not cached and we're online, try to download
      final isOnline = await _connectivityManager.isConnected();
      if (isOnline) {
        final downloadedFile = await downloadAndCacheImage(url);
        if (downloadedFile != null) {
          return FileImage(downloadedFile);
        }
      }

      // Fallback to network image (will fail if offline)
      return NetworkImage(url);
    } catch (e) {
      print('Error getting image provider for $url: $e');
      return null;
    }
  }

  // Update last accessed time
  Future<void> _updateLastAccessed(String url) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'image_cache_metadata',
        {'last_accessed': DateTime.now().toIso8601String()},
        where: 'image_url = ?',
        whereArgs: [url],
      );
    } catch (e) {
      print('Error updating last accessed: $e');
    }
  }

  // **MAIN METHOD: Cache all system images proactively**
  Future<void> cacheAllSystemImages({
    Function(int, int, int)? progressCallback,
  }) async {
    if (_isPreloadingInProgress) {
      print('⚠️ Image preloading already in progress');
      return;
    }

    final isOnline = await _connectivityManager.isConnected();
    if (!isOnline) {
      print('⚠️ Cannot preload images while offline');
      return;
    }

    _isPreloadingInProgress = true;
    _cachedImages = 0;
    _failedImages = 0;
    onProgressUpdate = progressCallback;

    try {
      print('🚀 Starting proactive image caching...');

      // Collect all image URLs from the database
      final imageUrls = await _collectAllImageUrls();
      _totalImages = imageUrls.length;

      if (_totalImages == 0) {
        print('ℹ️ No images found to cache');
        _isPreloadingInProgress = false;
        return;
      }

      print('📊 Found $_totalImages images to cache');

      // Filter out already cached images
      final uncachedUrls = <String>[];
      for (final url in imageUrls) {
        final cachedFile = await getCachedImage(url);
        if (cachedFile == null) {
          uncachedUrls.add(url);
        } else {
          _cachedImages++;
        }
      }

      print(
        '📱 ${_cachedImages} images already cached, ${uncachedUrls.length} to download',
      );

      if (uncachedUrls.isEmpty) {
        print('✅ All images already cached!');
        _isPreloadingInProgress = false;
        onProgressUpdate?.call(_cachedImages, _totalImages, _failedImages);
        return;
      }

      // Download images in batches to avoid overwhelming the network
      await _downloadImagesInBatches(uncachedUrls);

      print(
        '✅ Image caching completed: $_cachedImages cached, $_failedImages failed',
      );
    } catch (e) {
      print('❌ Error during proactive image caching: $e');
    } finally {
      _isPreloadingInProgress = false;
      onProgressUpdate?.call(_cachedImages, _totalImages, _failedImages);
    }
  }

  // Collect all image URLs from database
  Future<Set<String>> _collectAllImageUrls() async {
    final db = await _dbHelper.database;
    final imageUrls = <String>{};

    try {
      // Get artist images
      final artistMaps = await db.query(
        'artists',
        columns: ['image'],
        where: 'image IS NOT NULL AND image != ""',
      );
      for (final map in artistMaps) {
        final image = map['image'] as String?;
        if (image != null && image.isNotEmpty) {
          imageUrls.add(image);
        }
      }

      // Get album images and artist images from albums
      final albumMaps = await db.query(
        'albums',
        columns: ['image', 'artist_image'],
        where: 'synced != -1',
      );
      for (final map in albumMaps) {
        final image = map['image'] as String?;
        final artistImage = map['artist_image'] as String?;

        if (image != null && image.isNotEmpty) {
          imageUrls.add(image);
        }
        if (artistImage != null && artistImage.isNotEmpty) {
          imageUrls.add(artistImage);
        }
      }

      // Get song images, album images, and artist images from songs
      final songMaps = await db.query(
        'songs',
        columns: ['image', 'album_image', 'artist_image'],
        where: 'synced != -1',
      );
      for (final map in songMaps) {
        final image = map['image'] as String?;
        final albumImage = map['album_image'] as String?;
        final artistImage = map['artist_image'] as String?;

        if (image != null && image.isNotEmpty) {
          imageUrls.add(image);
        }
        if (albumImage != null && albumImage.isNotEmpty) {
          imageUrls.add(albumImage);
        }
        if (artistImage != null && artistImage.isNotEmpty) {
          imageUrls.add(artistImage);
        }
      }

      // Get group song images
      final groupSongMaps = await db.query(
        'group_songs',
        columns: ['image'],
        where: 'image IS NOT NULL AND image != ""',
      );
      for (final map in groupSongMaps) {
        final image = map['image'] as String?;
        if (image != null && image.isNotEmpty) {
          imageUrls.add(image);
        }
      }

      // Get group song artist images
      final groupArtistMaps = await db.query(
        'group_song_artists',
        columns: ['artist_image'],
        where: 'artist_image IS NOT NULL AND artist_image != ""',
      );
      for (final map in groupArtistMaps) {
        final artistImage = map['artist_image'] as String?;
        if (artistImage != null && artistImage.isNotEmpty) {
          imageUrls.add(artistImage);
        }
      }

      // Get user profile images
      final profileMaps = await db.query(
        'user_profile_details',
        columns: ['profile_image'],
        where: 'profile_image IS NOT NULL AND profile_image != ""',
      );
      for (final map in profileMaps) {
        final profileImage = map['profile_image'] as String?;
        if (profileImage != null && profileImage.isNotEmpty) {
          imageUrls.add(profileImage);
        }
      }

      print('🔍 Collected ${imageUrls.length} unique image URLs');
      return imageUrls;
    } catch (e) {
      print('❌ Error collecting image URLs: $e');
      return <String>{};
    }
  }

  // Download images in batches with concurrency control
  Future<void> _downloadImagesInBatches(List<String> imageUrls) async {
    final batches = <List<String>>[];

    // Split into batches
    for (int i = 0; i < imageUrls.length; i += _maxConcurrentDownloads) {
      final end =
          (i + _maxConcurrentDownloads < imageUrls.length)
              ? i + _maxConcurrentDownloads
              : imageUrls.length;
      batches.add(imageUrls.sublist(i, end));
    }

    print('📦 Processing ${batches.length} batches of images...');

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];
      print(
        '📥 Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} images)',
      );

      // Download batch concurrently
      final futures =
          batch.map((url) => _downloadSingleImageWithRetry(url)).toList();
      await Future.wait(futures);

      // Update progress
      onProgressUpdate?.call(_cachedImages, _totalImages, _failedImages);

      // Small delay between batches to avoid overwhelming the server
      if (batchIndex < batches.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }

  // Download single image with retry logic
  Future<void> _downloadSingleImageWithRetry(
    String url, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final file = await downloadAndCacheImage(url);
        if (file != null) {
          _cachedImages++;
          print('✅ Cached image: $url');
          return;
        }
      } catch (e) {
        print('❌ Attempt $attempt failed for $url: $e');

        if (attempt < maxRetries) {
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }
    }

    _failedImages++;
    print('❌ Failed to cache after $maxRetries attempts: $url');
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await _dbHelper.database;
      final cacheDir = await _cacheDirectory;

      // Get total cached images count
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(file_size) as total_size FROM image_cache_metadata',
      );

      final count = result.first['count'] as int? ?? 0;
      final totalSize = result.first['total_size'] as int? ?? 0;

      // Get cache directory size (as backup calculation)
      int directorySize = 0;
      if (await cacheDir.exists()) {
        await for (final file in cacheDir.list(recursive: true)) {
          if (file is File) {
            directorySize += await file.length();
          }
        }
      }

      return {
        'cachedImagesCount': count,
        'totalSizeBytes': totalSize > 0 ? totalSize : directorySize,
        'totalSizeMB':
            (totalSize > 0 ? totalSize : directorySize) / (1024 * 1024),
        'isPreloadingInProgress': _isPreloadingInProgress,
        'lastPreloadProgress': {
          'cached': _cachedImages,
          'total': _totalImages,
          'failed': _failedImages,
        },
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {
        'cachedImagesCount': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': 0.0,
        'isPreloadingInProgress': _isPreloadingInProgress,
      };
    }
  }

  // Clean old cache entries
  Future<void> cleanOldCache({int maxAgeInDays = 30}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate =
          DateTime.now()
              .subtract(Duration(days: maxAgeInDays))
              .toIso8601String();

      // Get old cache entries
      final oldEntries = await db.query(
        'image_cache_metadata',
        where: 'last_accessed < ?',
        whereArgs: [cutoffDate],
      );

      for (final entry in oldEntries) {
        final localPath = entry['local_path'] as String;
        final file = File(localPath);

        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from database
      final deletedCount = await db.delete(
        'image_cache_metadata',
        where: 'last_accessed < ?',
        whereArgs: [cutoffDate],
      );

      print('🧹 Cleaned $deletedCount old cache entries');
    } catch (e) {
      print('Error cleaning old cache: $e');
    }
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      final db = await _dbHelper.database;
      await db.delete('image_cache_metadata');

      print('✅ All image cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
