// Create this file: lib/Service/setlist_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class SetListService {
  static const String baseUrl =
      'https://therockofpraise.org'; // Replace with your API URL

  // Models
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Get all folders for a user
  static Future<Map<String, dynamic>> getFolders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/setlist/folders/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch folders: $e'};
    }
  }

  // Create new folder
  static Future<Map<String, dynamic>> createFolder(
    String userId,
    String folderName, {
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/setlist/folders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'folderName': folderName,
          'description': description,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create folder: $e'};
    }
  }

  // Add song to folder
  static Future<Map<String, dynamic>> addSongToFolder({
    required int folderId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
    required String lyricsFormat,
    required String savedLyrics,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/setlist/songs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'folderId': folderId,
          'songId': songId,
          'songName': songName,
          'artistName': artistName,
          'songImage': songImage,
          'lyricsFormat': lyricsFormat,
          'savedLyrics': savedLyrics,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to add song: $e'};
    }
  }

  // Get songs in a folder
  static Future<Map<String, dynamic>> getFolderSongs(int folderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/setlist/songs/$folderId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch songs: $e'};
    }
  }

  // Remove song from setlist
  static Future<Map<String, dynamic>> removeSongFromSetlist(
    int setlistSongId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/setlist/songs/$setlistSongId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove song: $e'};
    }
  }

  // Delete folder
  static Future<Map<String, dynamic>> deleteFolder(int folderId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/setlist/folders/$folderId'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete folder: $e'};
    }
  }
}

// Models for type safety
class SetListFolder {
  final int id;
  final int userId;
  final String folderName;
  final String? description;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  SetListFolder({
    required this.id,
    required this.userId,
    required this.folderName,
    this.description,
    required this.songCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SetListFolder.fromJson(Map<String, dynamic> json) {
    return SetListFolder(
      id: json['id'],
      userId: json['user_id'],
      folderName: json['folder_name'],
      description: json['description'],
      songCount: json['song_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class SetListSong {
  final int id;
  final int folderId;
  final int songId;
  final String songName;
  final String artistName;
  final String? songImage;
  final String lyricsFormat;
  final String? savedLyrics;
  final int orderIndex;
  final DateTime createdAt;

  SetListSong({
    required this.id,
    required this.folderId,
    required this.songId,
    required this.songName,
    required this.artistName,
    this.songImage,
    required this.lyricsFormat,
    this.savedLyrics,
    required this.orderIndex,
    required this.createdAt,
  });

  factory SetListSong.fromJson(Map<String, dynamic> json) {
    return SetListSong(
      id: json['id'],
      folderId: json['folder_id'],
      songId: json['song_id'],
      songName: json['song_name'],
      artistName: json['artist_name'],
      songImage: json['song_image'],
      lyricsFormat: json['lyrics_format'],
      savedLyrics: json['saved_lyrics'],
      orderIndex: json['order_index'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
