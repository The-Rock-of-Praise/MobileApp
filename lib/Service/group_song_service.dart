import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lyrics/OfflineService/offline_groupe_service.dart';

class GroupSongService {
  static const String baseUrl =
      'https://api.therockofpraise.org/api'; // Change to your server URL
  static String? _authToken;

  // Headers for requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Set authentication token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  static void clearAuthToken() {
    _authToken = null;
  }

  // Generic GET request
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic PUT request
  static Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Generic DELETE request
  static Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['error'] ?? data['message'] ?? 'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  // Multipart request for file uploads
  static Future<Map<String, dynamic>> _multipartRequest(
    String endpoint,
    String method,
    Map<String, String> fields,
    File? imageFile,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest(method, uri);

      // Add headers
      request.headers.addAll(_headers);
      request.headers.remove('Content-Type'); // Let multipart handle this

      // Add fields
      request.fields.addAll(fields);

      // Add image file if provided
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Upload error: $e');
    }
  }

  // ============================================================================
  // GROUP SONGS ENDPOINTS
  // ============================================================================

  // Get all group songs
  static Future<List<GroupSongModel>> getGroupSongs() async {
    final response = await _get('/group-songs');
    return (response['data'] as List)
        .map((json) => GroupSongModel.fromJson(json))
        .toList();
  }

  // Get group song by ID
  static Future<GroupSongModel> getGroupSong(int id) async {
    final response = await _get('/group-songs/$id');
    return GroupSongModel.fromJson(response['data']);
  }

  // Get group songs by language
  static Future<List<GroupSongModel>> getGroupSongsByLanguage(
    String language,
  ) async {
    final response = await _get('/group-songs/language/$language');
    print('Response from getGroupSongsByLanguage: $response');
    return (response['data'] as List)
        .map((json) => GroupSongModel.fromJson(json))
        .toList();
  }

  // Create group song
  static Future<GroupSongModel> createGroupSong({
    required String songName,
    required List<int> artistIds,
    String? albumName,
    String? lyricsSi,
    String? lyricsEn,
    String? lyricsTa,
    required List<String> languages,
    String? releaseDate,
    String? duration,
    File? image,
  }) async {
    final body = {
      'songname': songName,
      'artist_ids': artistIds,
      if (albumName != null) 'album_name': albumName,
      if (lyricsSi != null) 'lyrics_si': lyricsSi,
      if (lyricsEn != null) 'lyrics_en': lyricsEn,
      if (lyricsTa != null) 'lyrics_ta': lyricsTa,
      'language': languages,
      if (releaseDate != null) 'release_date': releaseDate,
      if (duration != null) 'duration': duration,
    };

    if (image != null) {
      final fields = body.map((key, value) => MapEntry(key, value.toString()));
      final response = await _multipartRequest(
        '/group-songs',
        'POST',
        fields,
        image,
      );
      return GroupSongModel.fromJson(response['data']);
    } else {
      final response = await _post('/group-songs', body);
      return GroupSongModel.fromJson(response['data']);
    }
  }

  // Update group song
  static Future<GroupSongModel> updateGroupSong({
    required int id,
    required String songName,
    required List<int> artistIds,
    String? albumName,
    String? lyricsSi,
    String? lyricsEn,
    String? lyricsTa,
    required List<String> languages,
    String? releaseDate,
    String? duration,
    File? image,
  }) async {
    final body = {
      'songname': songName,
      'artist_ids': artistIds,
      if (albumName != null) 'album_name': albumName,
      if (lyricsSi != null) 'lyrics_si': lyricsSi,
      if (lyricsEn != null) 'lyrics_en': lyricsEn,
      if (lyricsTa != null) 'lyrics_ta': lyricsTa,
      'language': languages,
      if (releaseDate != null) 'release_date': releaseDate,
      if (duration != null) 'duration': duration,
    };

    if (image != null) {
      final fields = body.map((key, value) => MapEntry(key, value.toString()));
      final response = await _multipartRequest(
        '/group-songs/$id',
        'PUT',
        fields,
        image,
      );
      return GroupSongModel.fromJson(response['data']);
    } else {
      final response = await _put('/group-songs/$id', body);
      return GroupSongModel.fromJson(response['data']);
    }
  }

  // Delete group song
  static Future<void> deleteGroupSong(int id) async {
    await _delete('/group-songs/$id');
  }

  // Search group songs
  static Future<List<GroupSongModel>> searchGroupSongs(
    String query, {
    String? language,
  }) async {
    String endpoint = '/group-songs/search/$query';
    if (language != null) {
      endpoint += '?language=$language';
    }
    final response = await _get(endpoint);
    return (response['data'] as List)
        .map((json) => GroupSongModel.fromJson(json))
        .toList();
  }

  // Get group song lyrics by language
  static Future<Map<String, dynamic>> getGroupSongLyrics(
    int id,
    String language,
  ) async {
    final response = await _get('/group-songs/$id/lyrics/$language');
    return response['data'];
  }

  // Get group song lyrics by format
  static Future<Map<String, dynamic>> getGroupSongLyricsByFormat({
    required String title,
    required String format,
  }) async {
    final response = await _get(
      '/group-songs/lyrics/format?title=$title&format=$format',
    );
    return response['data'];
  }

  // Get random group songs
  static Future<List<GroupSongModel>> getRandomGroupSongs(
    int count, {
    String? language,
  }) async {
    String endpoint = '/group-songs/random/$count';
    if (language != null) {
      endpoint += '?language=$language';
    }
    final response = await _get(endpoint);
    return (response['data'] as List)
        .map((json) => GroupSongModel.fromJson(json))
        .toList();
  }

  // Get group songs by artist
  static Future<List<GroupSongModel>> getGroupSongsByArtist(
    int artistId,
  ) async {
    final response = await _get('/group-songs/artist/$artistId');
    return (response['data'] as List)
        .map((json) => GroupSongModel.fromJson(json))
        .toList();
  }

  // ============================================================================
  // GENERAL ENDPOINTS
  // ============================================================================

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    return await _get('/health');
  }

  // Global search
  static Future<SearchResult> search({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _get('/search?q=$query&page=$page&limit=$limit');
    return SearchResult.fromJson(response);
  }

  // Get all users (admin endpoint)
  static Future<List<User>> getUsers() async {
    final response = await _get('/users');
    return (response['data'] as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  // Delete user (admin endpoint)
  static Future<void> deleteUser(int id) async {
    await _delete('/users/$id');
  }

  // Get user statistics (admin endpoint)
  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await _get('/users/stats');
    return response['data'];
  }
}

// ============================================================================
// EXCEPTION CLASS
// ============================================================================

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}

// ============================================================================
// MODEL CLASSES
// ============================================================================

class Artist {
  final int id;
  final String name;
  final String bio;
  final String? image;
  final List<String> languages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Artist({
    required this.id,
    required this.name,
    required this.bio,
    this.image,
    required this.languages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      bio: json['bio'],
      image: json['image'],
      languages: json['languages']?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'image': image,
      'languages': languages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Album {
  final int id;
  final String name;
  final int artistId;
  final String artistName;
  final String? artistImage;
  final String description;
  final String? image;
  final String? releaseDate;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.name,
    required this.artistId,
    required this.artistName,
    this.artistImage,
    required this.description,
    this.image,
    this.releaseDate,
    required this.songCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      artistId: json['artist_id'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      description: json['description'],
      image: json['image'],
      releaseDate: json['release_date'],
      songCount: json['song_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Song {
  final int id;
  final String songName;
  final int artistId;
  final String artistName;
  final String? artistImage;
  final int? albumId;
  final String? albumName;
  final String? lyricsSi;
  final String? lyricsEn;
  final String? lyricsTa;
  final String? image;
  final List<String> languages;
  final String? releaseDate;
  final String? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    required this.id,
    required this.songName,
    required this.artistId,
    required this.artistName,
    this.artistImage,
    this.albumId,
    this.albumName,
    this.lyricsSi,
    this.lyricsEn,
    this.lyricsTa,
    this.image,
    required this.languages,
    this.releaseDate,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      songName: json['songname'],
      artistId: json['artist_id'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      albumId: json['album_id'],
      albumName: json['album_name'],
      lyricsSi: json['lyrics_si'],
      lyricsEn: json['lyrics_en'],
      lyricsTa: json['lyrics_ta'],
      image: json['image'],
      languages: json['languages']?.cast<String>() ?? [],
      releaseDate: json['release_date'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}

class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime createdAt;
  final UserProfile? profile;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullname'],
      email: json['email'],
      phoneNumber: json['phonenumber'],
      createdAt: DateTime.parse(json['created_at']),
      profile: json['profile_id'] != null ? UserProfile.fromJson(json) : null,
    );
  }
}

class UserProfile {
  final int id;
  final String? country;
  final String? dateOfBirth;
  final String? gender;
  final String? preferredLanguage;
  final String? bio;
  final String? profileImage;
  final String? accountType;

  UserProfile({
    required this.id,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.preferredLanguage,
    this.bio,
    this.profileImage,
    this.accountType,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['profile_id'],
      country: json['country'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      preferredLanguage: json['preferred_language'],
      bio: json['bio'],
      profileImage: json['profile_image'],
      accountType: json['account_type'],
    );
  }
}

class SearchResult {
  final List<Album> albums;
  final List<Song> songs;
  final List<Artist> artists;
  final SearchPagination pagination;

  SearchResult({
    required this.albums,
    required this.songs,
    required this.artists,
    required this.pagination,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      albums:
          (json['data']['albums'] as List)
              .map((album) => Album.fromJson(album))
              .toList(),
      songs:
          (json['data']['songs'] as List)
              .map((song) => Song.fromJson(song))
              .toList(),
      artists:
          (json['data']['artists'] as List)
              .map((artist) => Artist.fromJson(artist))
              .toList(),
      pagination: SearchPagination.fromJson(json['data']['pagination']),
    );
  }
}

class SearchPagination {
  final int page;
  final int limit;
  final int total;

  SearchPagination({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
    );
  }
}
