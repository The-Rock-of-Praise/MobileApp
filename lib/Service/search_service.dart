// lib/Service/search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/song_service.dart';

class SearchService {
  final String baseUrl;

  SearchService({required this.baseUrl});

  Future<Map<String, dynamic>> search(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/search?q=${Uri.encodeQueryComponent(query)}&page=$page&limit=$limit',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      print('Search Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'albums':
                (data['data']['albums'] as List)
                    .map((album) => AlbumModel.fromJson(album))
                    .toList(),
            'songs':
                (data['data']['songs'] as List)
                    .map((song) => SongModel.fromJson(song))
                    .toList(),
            'artists':
                (data['data']['artists'] as List)
                    .map((artist) => ArtistModel.fromJson(artist))
                    .toList(),
          };
        } else {
          return {
            'success': false,
            'message': data['error'] ?? 'Search failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
