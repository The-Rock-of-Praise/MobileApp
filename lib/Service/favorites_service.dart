// Create this file: lib/Service/favorites_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritesService {
  static const String baseUrl =
      'https://therockofpraise.org'; // Replace with your API URL

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Add song to favorites
  static Future<Map<String, dynamic>> addToFavorites({
    required String userId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/favorites/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'songId': songId,
          'songName': songName,
          'artistName': artistName,
          'songImage': songImage,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to add to favorites: $e'};
    }
  }

  // Remove song from favorites
  static Future<Map<String, dynamic>> removeFromFavorites({
    required String userId,
    required int songId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/favorites/remove'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'songId': songId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove from favorites: $e',
      };
    }
  }

  // Get all favorite songs for a user
  static Future<Map<String, dynamic>> getFavorites(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      String url = '$baseUrl/api/favorites/$userId';
      Map<String, String> queryParams = {};

      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      if (queryParams.isNotEmpty) {
        url +=
            '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch favorites: $e'};
    }
  }

  // Check if song is favorited
  static Future<Map<String, dynamic>> checkFavoriteStatus(
    String userId,
    int songId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/check/$userId/$songId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check favorite status: $e',
      };
    }
  }

  // Get favorite statistics
  static Future<Map<String, dynamic>> getFavoriteStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/stats/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch favorite stats: $e',
      };
    }
  }
}

// Model classes for favorites
class FavoriteSong {
  final int id;
  final int userId;
  final int songId;
  final String songName;
  final String artistName;
  final String? songImage;
  final String? lyricsSi;
  final String? lyricsEn;
  final String? lyricsTa;
  final int? duration;
  final DateTime createdAt;

  FavoriteSong({
    required this.id,
    required this.userId,
    required this.songId,
    required this.songName,
    required this.artistName,
    this.songImage,
    this.lyricsSi,
    this.lyricsEn,
    this.lyricsTa,
    this.duration,
    required this.createdAt,
  });

  factory FavoriteSong.fromJson(Map<String, dynamic> json) {
    return FavoriteSong(
      id: json['id'],
      userId: json['user_id'],
      songId: json['song_id'],
      songName: json['song_name'],
      artistName: json['artist_name'],
      songImage: json['song_image'],
      lyricsSi: json['lyrics_si'],
      lyricsEn: json['lyrics_en'],
      lyricsTa: json['lyrics_ta'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Helper method to get lyrics based on language
  String? getLyrics(String language) {
    switch (language.toLowerCase()) {
      case 'si':
      case 'sinhala':
        return lyricsSi;
      case 'en':
      case 'english':
        return lyricsEn;
      case 'ta':
      case 'tamil':
        return lyricsTa;
      default:
        return lyricsEn ?? lyricsSi ?? lyricsTa;
    }
  }

  // Helper method to format duration
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class FavoriteStats {
  final int totalFavorites;
  final int favoriteArtists;
  final DateTime? lastAdded;
  final List<ArtistCount> topArtists;

  FavoriteStats({
    required this.totalFavorites,
    required this.favoriteArtists,
    this.lastAdded,
    required this.topArtists,
  });

  factory FavoriteStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'];
    return FavoriteStats(
      totalFavorites: stats['total_favorites'] ?? 0,
      favoriteArtists: stats['favorite_artists'] ?? 0,
      lastAdded:
          stats['last_added'] != null
              ? DateTime.parse(stats['last_added'])
              : null,
      topArtists:
          (stats['topArtists'] as List? ?? [])
              .map((artist) => ArtistCount.fromJson(artist))
              .toList(),
    );
  }
}

class ArtistCount {
  final String artistName;
  final int count;

  ArtistCount({required this.artistName, required this.count});

  factory ArtistCount.fromJson(Map<String, dynamic> json) {
    return ArtistCount(artistName: json['artist_name'], count: json['count']);
  }
}
