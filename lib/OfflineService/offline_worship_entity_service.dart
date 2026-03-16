import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/worship_entity_service.dart';
import 'package:sqflite/sqflite.dart';

class OfflineWorshipEntityService {
  final WorshipEntityService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineWorshipEntityService({WorshipEntityService? onlineService})
      : _onlineService = onlineService ?? WorshipEntityService();

  // Get worship artists with offline support
  Future<Map<String, dynamic>> getWorshipArtists() async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getAllWorshipArtists();
        if (result['success']) {
          await _cacheWorshipArtists(result['artists']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship artists fetch failed: $e');
      }
    }
    return await _getCachedWorshipArtists();
  }

  // Get worship artist by ID with offline support
  Future<Map<String, dynamic>> getWorshipArtistById(int id) async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getWorshipArtistById(id);
        if (result['success']) {
          await _cacheWorshipArtists([result['artist']]);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship artist fetch failed: $e');
      }
    }
    return await _getCachedWorshipArtistById(id);
  }

  // Get worship artists by language with offline support
  Future<Map<String, dynamic>> getWorshipArtistsByLanguage(String lang) async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getWorshipArtistsByLanguage(lang);
        if (result['success']) {
          await _cacheWorshipArtists(result['artists']);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship artists for lang $lang fetch failed: $e');
      }
    }
    return await _getCachedWorshipArtistsByLanguage(lang);
  }

  // Get latest worship albums with offline support
  Future<Map<String, dynamic>> getLatestWorshipAlbums({String? lang}) async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getLatestWorshipAlbums(language: lang);
        if (result['success']) {
          final albums = List<WorshipAlbumModel>.from(result['albums']);
          await _cacheWorshipAlbums(albums);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online latest worship albums fetch failed: $e');
      }
    }
    return await _getCachedLatestWorshipAlbums(lang);
  }

  // Get artist albums with offline support
  Future<Map<String, dynamic>> getWorshipArtistAlbums(int artistId) async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getWorshipArtistAlbums(artistId);
        if (result['success']) {
          final albums = List<WorshipAlbumModel>.from(result['albums']);
          await _cacheWorshipAlbums(albums);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship albums for artist $artistId fetch failed: $e');
      }
    }
    return await _getCachedWorshipArtistAlbums(artistId);
  }

  // Get artist songs with offline support
  Future<Map<String, dynamic>> getWorshipArtistSongs(int artistId) async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getWorshipArtistSongs(artistId);
        if (result['success']) {
          final songs = List<WorshipSongModel>.from(result['songs']);
          await _cacheWorshipSongs(songs);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship songs for artist $artistId fetch failed: $e');
      }
    }
    return await _getCachedWorshipArtistSongs(artistId);
  }

  // Caching methods
  Future<void> _cacheWorshipArtists(List<WorshipArtistModel> artists) async {
    final db = await _dbHelper.database;
    for (var artist in artists) {
      await db.insert(
        'worship_artists',
        artist.toJson()..['synced'] = 1,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _cacheWorshipAlbums(List<WorshipAlbumModel> albums) async {
    final db = await _dbHelper.database;
    for (var album in albums) {
      await db.insert(
        'worship_albums',
        album.toJson()..['synced'] = 1,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _cacheWorshipSongs(List<WorshipSongModel> songs) async {
    final db = await _dbHelper.database;
    for (var song in songs) {
      await db.insert(
        'worship_teams', // Use existing worship_teams table for songs
        song.toJson()..['synced'] = 1,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Fetch from cache
  Future<Map<String, dynamic>> _getCachedWorshipArtists() async {
    final db = await _dbHelper.database;
    final maps = await db.query('worship_artists', orderBy: 'name ASC');
    final items = maps.map((e) => WorshipArtistModel.fromJson(e)).toList();
    return {'success': true, 'artists': items, 'source': 'cache'};
  }

  Future<Map<String, dynamic>> _getCachedWorshipArtistById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worship_artists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return {'success': false, 'message': 'Artist not found in cache'};
    }
    return {
      'success': true,
      'artist': WorshipArtistModel.fromJson(maps.first),
      'source': 'cache',
    };
  }

  Future<Map<String, dynamic>> _getCachedWorshipArtistsByLanguage(String lang) async {
    final db = await _dbHelper.database;
    // Note: In DB, language is typically a comma separated string if it comes from the split in backend
    // but the table schema I added has a `language` field.
    // Let's use a LIKE query just in case.
    final maps = await db.query(
      'worship_artists',
      where: 'language LIKE ?',
      whereArgs: ['%$lang%'],
      orderBy: 'name ASC',
    );
    final items = maps.map((e) => WorshipArtistModel.fromJson(e)).toList();
    return {'success': true, 'artists': items, 'source': 'cache'};
  }

  Future<Map<String, dynamic>> _getCachedWorshipArtistAlbums(int artistId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worship_albums',
      where: 'artist_id = ?',
      whereArgs: [artistId],
      orderBy: 'release_date DESC',
    );
    final items = maps.map((e) => WorshipAlbumModel.fromJson(e)).toList();
    return {'success': true, 'albums': items, 'source': 'cache'};
  }

  Future<Map<String, dynamic>> _getCachedWorshipArtistSongs(int artistId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worship_teams',
      where: 'artist_id = ?',
      whereArgs: [artistId],
      orderBy: 'songname ASC',
    );
    final items = maps.map((e) => WorshipSongModel.fromJson(e)).toList();
    return {'success': true, 'songs': items, 'source': 'cache'};
  }

  Future<Map<String, dynamic>> _getCachedLatestWorshipAlbums(String? lang) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;
    
    // For now we'll just return all for simplicity, as specific lang filtering might need joins
    final maps = await db.query(
      'worship_albums',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'release_date DESC',
      limit: 10,
    );
    final items = maps.map((e) => WorshipAlbumModel.fromJson(e)).toList();
    return {'success': true, 'albums': items, 'source': 'cache'};
  }

  void dispose() {
    _onlineService.dispose();
  }
}
