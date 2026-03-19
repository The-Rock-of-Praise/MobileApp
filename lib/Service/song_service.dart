import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lyrics/Service/base_api.dart';

class SongModel {
  final int? id;
  final String songname;
  final String? lyricsSi;
  final String? lyricsEn;
  final String? lyricsTa;
  final int artistId;
  final int? albumId;
  final int? duration;
  final int? trackNumber;
  final String? artistName;
  final String? artistImage;
  final String? albumName;
  final String? image;
  final String? albumImage;
  final String? releaseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int synced; // 0 = not synced, 1 = synced, -1 = marked for deletion

  SongModel({
    this.id,
    required this.songname,
    this.lyricsSi,
    this.lyricsEn,
    this.lyricsTa,
    required this.artistId,
    this.albumId,
    this.duration,
    this.trackNumber,
    this.artistName,
    this.artistImage,
    this.albumName,
    this.albumImage,
    this.releaseDate,
    this.createdAt,
    this.image,
    this.updatedAt,
    this.synced = 0,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'],
      songname: json['songname'] ?? '',
      lyricsSi: json['lyrics_si'],
      lyricsEn: json['lyrics_en'],
      lyricsTa: json['lyrics_ta'],
      artistId: json['artist_id'] ?? 0,
      albumId: json['album_id'],
      duration: json['duration'],
      trackNumber: json['track_number'],
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      albumName: json['album_name'],
      albumImage: json['album_image'],
      image: json['image'],
      releaseDate: json['release_date'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      synced: json['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'songname': songname,
      'lyrics_si': lyricsSi,
      'lyrics_en': lyricsEn,
      'lyrics_ta': lyricsTa,
      'artist_id': artistId,
      'album_id': albumId,
      'duration': duration,
      'track_number': trackNumber,
      'image': image,
      'release_date': releaseDate,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songname': songname,
      'lyrics_si': lyricsSi,
      'lyrics_en': lyricsEn,
      'lyrics_ta': lyricsTa,
      'artist_id': artistId,
      'album_id': albumId,
      'duration': duration,
      'track_number': trackNumber,
      'artist_name': artistName,
      'artist_image': artistImage,
      'album_name': albumName,
      'album_image': albumImage,
      'image': image,
      'release_date': releaseDate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'synced': synced,
    };
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Check if lyrics exist for a language
  bool hasLyrics(String language) {
    switch (language.toLowerCase()) {
      case 'si':
        return lyricsSi != null && lyricsSi!.isNotEmpty;
      case 'en':
        return lyricsEn != null && lyricsEn!.isNotEmpty;
      case 'ta':
        return lyricsTa != null && lyricsTa!.isNotEmpty;
      default:
        return false;
    }
  }

  // Get lyrics by language
  String? getLyrics(String language) {
    switch (language.toLowerCase()) {
      case 'si':
        return lyricsSi;
      case 'en':
        return lyricsEn;
      case 'ta':
        return lyricsTa;
      default:
        return null;
    }
  }

  SongModel copyWith({
    int? id,
    String? songname,
    String? lyricsSi,
    String? lyricsEn,
    String? lyricsTa,
    int? artistId,
    int? albumId,
    int? duration,
    int? trackNumber,
    String? artistName,
    String? artistImage,
    String? albumName,
    String? image,
    String? albumImage,
    String? releaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? synced,
  }) {
    return SongModel(
      id: id ?? this.id,
      songname: songname ?? this.songname,
      lyricsSi: lyricsSi ?? this.lyricsSi,
      lyricsEn: lyricsEn ?? this.lyricsEn,
      lyricsTa: lyricsTa ?? this.lyricsTa,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      artistName: artistName ?? this.artistName,
      artistImage: artistImage ?? this.artistImage,
      albumName: albumName ?? this.albumName,
      image: image ?? this.image,
      albumImage: albumImage ?? this.albumImage,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

class LyricsModel {
  final int id;
  final String songname;
  final String language;
  final String lyrics;
  final String artistName;
  final String? albumName;

  LyricsModel({
    required this.id,
    required this.songname,
    required this.language,
    required this.lyrics,
    required this.artistName,
    this.albumName,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    return LyricsModel(
      id: json['id'],
      songname: json['songname'] ?? '',
      language: json['language'] ?? '',
      lyrics: json['lyrics'] ?? '',
      artistName: json['artist_name'] ?? '',
      albumName: json['album_name'],
    );
  }
}

class SongService {
  final BaseApiService _apiService;
  static const String baseUrl = 'https://api.therockofpraise.org/api';

  SongService({BaseApiService? apiService})
    : _apiService = apiService ?? BaseApiService();

  // Get all songs
  Future<Map<String, dynamic>> getAllSongs() async {
    try {
      final result = await _apiService.get('/songs');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Songs fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch songs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Updated SongService method to handle the new response format
  Future<Map<String, dynamic>> getSongLyricsByFormat(
    String songTitle,
    String format,
  ) async {
    try {
      final result = await _apiService.get(
        '/songs/lyrics/format?title=${Uri.encodeComponent(songTitle)}&format=$format',
      );

      print('Lyrics by format result: $result');

      if (result['success'] == true) {
        final data = result['data']['data'];

        if (data == null) {
          return {'success': false, 'message': 'No data received from server'};
        }

        // Safely extract the lyrics map and display order
        final lyricsMap =
            data['lyrics'] != null
                ? Map<String, dynamic>.from(data['lyrics'])
                : <String, dynamic>{};

        final displayOrder =
            data['displayOrder'] != null
                ? List<String>.from(data['displayOrder'])
                : <String>[];

        final availableLanguages =
            data['availableLanguages'] != null
                ? List<String>.from(data['availableLanguages'])
                : <String>[];

        return {
          'success': true,
          'song': data['song'] ?? 'Unknown Song',
          'artist': data['artist'] ?? 'Unknown Artist',
          'format': data['format'] ?? format,
          'formatDisplayName': data['formatDisplayName'] ?? format,
          'lyrics': lyricsMap,
          'displayOrder': displayOrder,
          'availableLanguages': availableLanguages,
          'totalLanguages': data['totalLanguages'] ?? 0,
          'message': 'Lyrics fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch lyrics',
        };
      }
    } catch (e) {
      print('Error in getSongLyricsByFormat: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSongIdByName(
    String songName,
    String artistName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/songs/get-id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'songName': songName, 'artistName': artistName}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to get song ID: $e'};
    }
  }

  // Get song lyrics by language
  Future<Map<String, dynamic>> getSongLyrics(
    String songTitle,
    String languageCode,
  ) async {
    try {
      final result = await _apiService.get(
        '/songs/lyrics?title=${Uri.encodeComponent(songTitle)}&language=$languageCode',
      );
      print('lyrics ; $result');
      if (result['success']) {
        return {
          'success': true,
          'lyrics': result['data']['lyrics'],
          'message': 'Lyrics fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Lyrics not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get random songs
  Future<Map<String, dynamic>> getRandomSongs({int count = 10}) async {
    try {
      if (count > 50) {
        return {'success': false, 'message': 'Maximum 50 songs allowed'};
      }

      final result = await _apiService.get('/songs/random/$count');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Random songs fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch random songs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get songs by language
  Future<Map<String, dynamic>> getSongsByLanguage(String languageCode) async {
    try {
      final result = await _apiService.get('/songs/language/$languageCode');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Songs fetched successfully for language: $languageCode',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch songs by language',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get default random songs (10 songs)
  Future<Map<String, dynamic>> getDefaultRandomSongs() async {
    try {
      final result = await _apiService.get('/songs/random');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Random songs fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch random songs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  //get all songs

  // Get songs by category
  Future<Map<String, dynamic>> getSongsByCategory(String category) async {
    try {
      final result = await _apiService.get('/songs/category/$category');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Category songs fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch category songs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get songs with specific lyrics language available
  Future<Map<String, dynamic>> getSongsWithLyrics(String language) async {
    try {
      final result = await getAllSongs();

      if (result['success']) {
        final List<SongModel> allSongs = result['songs'];
        final List<SongModel> songsWithLyrics =
            allSongs.where((song) => song.hasLyrics(language)).toList();

        return {
          'success': true,
          'songs': songsWithLyrics,
          'message':
              'Songs with ${language.toUpperCase()} lyrics fetched successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Dispose
  void dispose() {
    _apiService.dispose();
  }

  // Get song by ID
  Future<Map<String, dynamic>> getSongById(int id) async {
    try {
      final result = await _apiService.get('/songs/$id');

      if (result['success']) {
        final SongModel song = SongModel.fromJson(result['data']['data']);

        return {
          'success': true,
          'song': song,
          'message': 'Song fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Song not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Create song
  Future<Map<String, dynamic>> createSong(SongModel song) async {
    try {
      final result = await _apiService.post('/songs', song.toCreateJson());

      if (result['success']) {
        final SongModel createdSong = SongModel.fromJson(
          result['data']['data'],
        );

        return {
          'success': true,
          'song': createdSong,
          'message': result['data']['message'] ?? 'Song created successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to create song',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Update song
  Future<Map<String, dynamic>> updateSong(int id, SongModel song) async {
    try {
      final result = await _apiService.put('/songs/$id', song.toCreateJson());

      if (result['success']) {
        final SongModel updatedSong = SongModel.fromJson(
          result['data']['data'],
        );

        return {
          'success': true,
          'song': updatedSong,
          'message': result['data']['message'] ?? 'Song updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to update song',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Delete song
  Future<Map<String, dynamic>> deleteSong(int id) async {
    try {
      final result = await _apiService.delete('/songs/$id');

      if (result['success']) {
        return {
          'success': true,
          'message': result['data']['message'] ?? 'Song deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to delete song',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Search songs
  Future<Map<String, dynamic>> searchSongs(String query) async {
    try {
      final result = await _apiService.get('/songs/search/$query');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Songs search completed successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Search failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred:$e'};
    }
  }

  // Get latest songs using uploaded date
  Future<Map<String, dynamic>> getLatestSongs() async {
    try {
      final result = await _apiService.get('/songs/latest');

      if (result['success']) {
        final List<dynamic> songsData = result['data']['data'] ?? [];
        final List<SongModel> songs =
            songsData.map((json) => SongModel.fromJson(json)).toList();

        return {
          'success': true,
          'songs': songs,
          'message': 'Latest songs fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch latest songs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
