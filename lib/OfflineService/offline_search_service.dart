// OfflineService/offline_search_service.dart
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Models/artist_model.dart';
import 'package:lyrics/Models/song_model.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/search_service.dart';
import 'package:lyrics/Service/song_service.dart';

class OfflineSearchService {
  final String baseUrl;
  late final SearchService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final OfflineGroupSongService _groupSongService = OfflineGroupSongService();

  OfflineSearchService({required this.baseUrl}) {
    _onlineService = SearchService(baseUrl: baseUrl);
  }

  // Main search method that searches across all content types
  Future<Map<String, dynamic>> search(String query) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        print('📡 Searching online...');
        final result = await _onlineService.search(query);
        if (result['success']) {
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('❌ Online search failed, searching cache: $e');
      }
    }

    return await _searchCache(query);
  }

  // Search in cached data
  Future<Map<String, dynamic>> _searchCache(String query) async {
    try {
      // Search all content types in parallel
      final List<Future> searches = [
        _searchCachedArtists(query),
        _searchCachedAlbums(query),
        _searchCachedSongs(query),
        _groupSongService.searchGroupSongs(query),
      ];

      final results = await Future.wait(searches);

      return {
        'success': true,
        'artists': results[0]['artists'] ?? [],
        'albums': results[1]['albums'] ?? [],
        'songs': results[2]['songs'] ?? [],
        'groupSongs': results[3]['groupSongs'] ?? [],
        'message': '🔍 Search completed in cache',
        'source': 'cache',
        'searchQuery': query,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Search failed: $e',
        'artists': [],
        'albums': [],
        'songs': [],
        'groupSongs': [],
      };
    }
  }

  // Search cached artists
  Future<Map<String, dynamic>> _searchCachedArtists(String query) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.rawQuery(
        '''
        SELECT * FROM artists 
        WHERE synced != -1 AND (
          name LIKE ? OR 
          bio LIKE ?
        )
        ORDER BY name
      ''',
        ['%$query%', '%$query%'],
      );

      final artists = maps.map((map) => ArtistModel.fromJson(map)).toList();

      return {
        'success': true,
        'artists': artists,
        'message': 'Artists found in cache',
        'source': 'cache',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error searching artists: $e',
        'artists': [],
      };
    }
  }

  // Search cached albums
  Future<Map<String, dynamic>> _searchCachedAlbums(String query) async {
    final db = await _dbHelper.database;

    try {
      final maps = await db.rawQuery(
        '''
        SELECT albums.*, artists.name as artist_name, artists.image as artist_image
        FROM albums 
        LEFT JOIN artists ON albums.artist_id = artists.id
        WHERE albums.synced != -1 AND (
          albums.name LIKE ? OR 
          albums.description LIKE ? OR
          artists.name LIKE ?
        )
        ORDER BY albums.name
      ''',
        ['%$query%', '%$query%', '%$query%'],
      );

      final albums = maps.map((map) => AlbumModel.fromJson(map)).toList();

      return {
        'success': true,
        'albums': albums,
        'message': 'Albums found in cache',
        'source': 'cache',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error searching albums: $e',
        'albums': [],
      };
    }
  }

  // Search cached songs
  Future<Map<String, dynamic>> _searchCachedSongs(String query) async {
    final db = await _dbHelper.database;

    try {
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
        ORDER BY songs.songname
      ''',
        ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
      );

      final songs = maps.map((map) => SongModel.fromJson(map)).toList();

      return {
        'success': true,
        'songs': songs,
        'message': 'Songs found in cache',
        'source': 'cache',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error searching songs: $e',
        'songs': [],
      };
    }
  }

  Future<Map<String, dynamic>> searchGroupSongs(String query) async {
    return await _groupSongService.searchGroupSongs(query);
  }

  // Advanced search with filters

  // Helper methods for filtering
  Map<String, dynamic> _filterResults(
    Map<String, dynamic> results,
    String? contentType,
    String? language,
    int limit,
  ) {
    if (contentType != null) {
      // Filter by content type
      final filteredResults = <String, dynamic>{
        'success': results['success'],
        'source': results['source'],
        'searchQuery': results['searchQuery'],
      };

      switch (contentType) {
        case 'artists':
          filteredResults['artists'] = results['artists'] ?? [];
          filteredResults['albums'] = [];
          filteredResults['songs'] = [];
          filteredResults['groupSongs'] = [];
          break;
        case 'albums':
          filteredResults['artists'] = [];
          filteredResults['albums'] = results['albums'] ?? [];
          filteredResults['songs'] = [];
          filteredResults['groupSongs'] = [];
          break;
        case 'songs':
          filteredResults['artists'] = [];
          filteredResults['albums'] = [];
          filteredResults['songs'] = results['songs'] ?? [];
          filteredResults['groupSongs'] = [];
          break;
        case 'group_songs':
          filteredResults['artists'] = [];
          filteredResults['albums'] = [];
          filteredResults['songs'] = [];
          filteredResults['groupSongs'] = results['groupSongs'] ?? [];
          break;
      }
      return filteredResults;
    }

    return results;
  }

  List<dynamic> _filterAlbumsByLanguage(List<dynamic> albums, String language) {
    return albums.where((album) {
      if (album is AlbumModel) {
        // You might want to add language field to AlbumModel or filter by artist language
        return true; // For now, return all albums
      }
      return false;
    }).toList();
  }

  List<dynamic> _filterArtistsByLanguage(
    List<dynamic> artists,
    String language,
  ) {
    return artists.where((artist) {
      if (artist is ArtistModel) {
        return artist.languages?.contains(language) ?? false;
      }
      return false;
    }).toList();
  }

  // Get search suggestions based on cached data
  Future<Map<String, dynamic>> getSearchSuggestions(String query) async {
    if (query.length < 2) {
      return {
        'success': true,
        'suggestions': [],
        'message': 'Query too short for suggestions',
      };
    }

    final db = await _dbHelper.database;

    try {
      // Get suggestions from different content types
      final List<String> suggestions = [];

      // Artist suggestions
      final artistMaps = await db.rawQuery(
        '''
        SELECT DISTINCT name FROM artists 
        WHERE synced != -1 AND name LIKE ? 
        LIMIT 3
      ''',
        ['%$query%'],
      );
      suggestions.addAll(artistMaps.map((m) => m['name'] as String));

      // Song suggestions
      final songMaps = await db.rawQuery(
        '''
        SELECT DISTINCT songname FROM songs 
        WHERE synced != -1 AND songname LIKE ? 
        LIMIT 3
      ''',
        ['%$query%'],
      );
      suggestions.addAll(songMaps.map((m) => m['songname'] as String));

      // Album suggestions
      final albumMaps = await db.rawQuery(
        '''
        SELECT DISTINCT name FROM albums 
        WHERE synced != -1 AND name LIKE ? 
        LIMIT 3
      ''',
        ['%$query%'],
      );
      suggestions.addAll(albumMaps.map((m) => m['name'] as String));

      // Group song suggestions
      final groupSongMaps = await db.rawQuery(
        '''
        SELECT DISTINCT songname FROM group_songs 
        WHERE synced != -1 AND songname LIKE ? 
        LIMIT 3
      ''',
        ['%$query%'],
      );
      suggestions.addAll(groupSongMaps.map((m) => m['songname'] as String));

      // Remove duplicates and limit
      final uniqueSuggestions = suggestions.toSet().take(10).toList();

      return {
        'success': true,
        'suggestions': uniqueSuggestions,
        'message': 'Suggestions from cache',
        'source': 'cache',
      };
    } catch (e) {
      return {
        'success': false,
        'suggestions': [],
        'message': 'Failed to get suggestions: $e',
      };
    }
  }

  // Get search history (if you want to implement this)
  Future<Map<String, dynamic>> getSearchHistory() async {
    // Implement if you want to store search history
    return {
      'success': true,
      'history': [],
      'message': 'Search history not implemented',
    };
  }

  void dispose() {
    _groupSongService.dispose();
  }
}
