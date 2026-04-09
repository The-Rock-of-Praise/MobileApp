import 'package:lyrics/Service/base_api.dart';

class WorshipArtistModel {
  final int? id;
  final String name;
  final String? image;
  final String? bio;
  final int? albumCount;
  final int? songCount;
  final String? language;
  final List<String>? languages;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int synced;

  WorshipArtistModel({
    this.id,
    required this.name,
    this.image,
    this.bio,
    this.albumCount,
    this.songCount,
    this.language,
    this.languages,
    this.createdAt,
    this.updatedAt,
    this.synced = 0,
  });

  factory WorshipArtistModel.fromJson(Map<String, dynamic> json) {
    return WorshipArtistModel(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'],
      bio: json['bio'],
      albumCount: json['album_count'] ?? json['albumCount'],
      songCount: json['song_count'] ?? json['songCount'],
      language: json['language'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : (json['artist_languages'] != null
              ? List<String>.from(json['artist_languages'])
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      synced: json['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'bio': bio,
      'language': language,
      'album_count': albumCount,
      'song_count': songCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'synced': synced,
    };
  }
}

class WorshipAlbumModel {
  final int? id;
  final String name;
  final String? image;
  final int artistId;
  final String? artistName;
  final String? artistImage;
  final String? releaseDate;
  final String? description;
  final int? songCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int synced;

  WorshipAlbumModel({
    this.id,
    required this.name,
    this.image,
    required this.artistId,
    this.artistName,
    this.artistImage,
    this.releaseDate,
    this.description,
    this.songCount,
    this.createdAt,
    this.updatedAt,
    this.synced = 0,
  });

  factory WorshipAlbumModel.fromJson(Map<String, dynamic> json) {
    return WorshipAlbumModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown Album',
      image: json['image'],
      artistId: json['artist_id'] ?? 0,
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      releaseDate: json['release_date'],
      description: json['description'],
      songCount: json['song_count'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      synced: json['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'artist_id': artistId,
      'artist_name': artistName,
      'artist_image': artistImage,
      'release_date': releaseDate,
      'description': description,
      'song_count': songCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'synced': synced,
    };
  }
}

class WorshipSongModel {
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
  final int synced;

  WorshipSongModel({
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

  factory WorshipSongModel.fromJson(Map<String, dynamic> json) {
    return WorshipSongModel(
      id: json['id'],
      songname: json['songname'] ?? json['title'] ?? '',
      lyricsSi: json['lyrics_si'] ?? (json['language'] == 'si' ? json['content'] : null),
      lyricsEn: json['lyrics_en'] ?? (json['language'] == 'en' ? json['content'] : null),
      lyricsTa: json['lyrics_ta'] ?? (json['language'] == 'ta' ? json['content'] : null),
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      synced: json['synced'] ?? 0,
    );
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

  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class WorshipEntityService {
  final BaseApiService _apiService;

  WorshipEntityService({BaseApiService? apiService})
      : _apiService = apiService ?? BaseApiService();

  // Get all worship artists
  Future<Map<String, dynamic>> getAllWorshipArtists() async {
    try {
      final result = await _apiService.get('/worship-artists');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipArtistModel> items =
            data.map((e) => WorshipArtistModel.fromJson(e)).toList();
        return {
          'success': true,
          'artists': items,
          'message': 'Worship artists fetched successfully',
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get worship artist by ID
  Future<Map<String, dynamic>> getWorshipArtistById(int id) async {
    try {
      final result = await _apiService.get('/worship-artists/$id');
      if (result['success']) {
        final data = result['data']['data'];
        if (data == null) {
          return {'success': false, 'message': 'Artist not found'};
        }
        return {
          'success': true,
          'artist': WorshipArtistModel.fromJson(data),
          'message': 'Worship artist fetched successfully',
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get worship artists by language
  Future<Map<String, dynamic>> getWorshipArtistsByLanguage(String lang) async {
    try {
      final result = await _apiService.get('/worship-artists/language/$lang');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipArtistModel> items =
            data.map((e) => WorshipArtistModel.fromJson(e)).toList();
        return {
          'success': true,
          'artists': items,
          'message': 'Worship artists fetched successfully',
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get latest worship albums
  Future<Map<String, dynamic>> getLatestWorshipAlbums({String? language}) async {
    try {
      final endpoint = language != null ? '/worship-albums?language=$language' : '/worship-albums';
      final result = await _apiService.get(endpoint);
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipAlbumModel> items =
            data.map((e) => WorshipAlbumModel.fromJson(e)).toList();
        return {
          'success': true,
          'albums': items,
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get worship artist's albums
  Future<Map<String, dynamic>> getWorshipArtistAlbums(int artistId) async {
    try {
      final result = await _apiService.get('/worship-artists/$artistId/albums');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipAlbumModel> items =
            data.map((e) => WorshipAlbumModel.fromJson(e)).toList();
        return {
          'success': true,
          'albums': items,
          'message': 'Worship albums fetched successfully',
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get worship artist's songs
  Future<Map<String, dynamic>> getWorshipArtistSongs(int artistId) async {
    try {
      final result = await _apiService.get('/worship-artists/$artistId/songs');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipSongModel> items =
            data.map((e) => WorshipSongModel.fromJson(e)).toList();
        return {
          'success': true,
          'songs': items,
          'message': 'Worship songs fetched successfully',
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get worship album's songs
  Future<Map<String, dynamic>> getWorshipAlbumSongs(int albumId) async {
    try {
      final result = await _apiService.get('/worship-songs/album/$albumId');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        final List<WorshipSongModel> items =
            data.map((e) => WorshipSongModel.fromJson(e)).toList();
        return {
          'success': true,
          'songs': items,
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  void dispose() {
    _apiService.dispose();
  }
}
