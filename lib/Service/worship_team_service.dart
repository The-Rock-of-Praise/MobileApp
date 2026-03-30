import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lyrics/Service/base_api.dart';
import 'package:lyrics/Models/worship_team_model.dart';
import 'package:lyrics/Service/group_song_service.dart';

class WorshipTeamService {
  final BaseApiService _apiService;
  static const String baseUrl = 'https://therockofpraise.org/api';
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

  WorshipTeamService({BaseApiService? apiService})
    : _apiService = apiService ?? BaseApiService();

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

  // Get all worship team songs
  Future<Map<String, dynamic>> getAllWorshipTeams() async {
    try {
      final result = await _apiService.get('/worship-teams');
      if (result['success'] == true) {
        final List<dynamic> data =
            result['data'] ?? result['data']['data'] ?? [];
        final List<WorshipTeamModel> items =
            (data)
                .map(
                  (e) => WorshipTeamModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
                .cast<WorshipTeamModel>();
        return {
          'success': true,
          'worshipTeams': items,
          'message': 'Worship teams fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to fetch worship teams',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getWorshipTeamById(int id) async {
    try {
      final result = await _apiService.get('/worship-teams/$id');
      if (result['success'] == true) {
        final data = result['data'];
        final WorshipTeamModel item = WorshipTeamModel.fromJson(
          data as Map<String, dynamic>,
        );
        return {'success': true, 'worshipTeam': item};
      }
      return {'success': false, 'message': result['message'] ?? 'Not found'};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> searchWorshipTeams(String query) async {
    try {
      final result = await _apiService.get(
        '/worship-teams/search/${Uri.encodeComponent(query)}',
      );
      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        final items =
            data
                .map(
                  (e) => WorshipTeamModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();
        return {'success': true, 'worshipTeams': items};
      }
      return {
        'success': false,
        'message': result['message'] ?? 'Search failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getWorshipTeamsByLanguage(
    String language,
  ) async {
    try {
      final response = await _get('/worship-teams/language/$language');
      print('Response from getWorshipTeamsByLanguage: $response');

      // Handle different response formats
      List<dynamic> dataList = [];
      if (response['data'] != null) {
        dataList = response['data'] as List;
      } else if (response['success'] == true && response.containsKey('data')) {
        dataList = response['data'] as List;
      }

      final items =
          dataList
              .map(
                (json) =>
                    WorshipTeamModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      return {
        'success': true,
        'worshipTeams': items,
        'total': response['total'] ?? items.length,
        'message': 'Worship teams fetched successfully',
      };
    } catch (e) {
      print('Error in getWorshipTeamsByLanguage: $e');
      return {
        'success': false,
        'worshipTeams': [],
        'message': 'Failed to fetch worship teams: ${e.toString()}',
      };
    }
  }

  // Get worship team lyrics by title and format - MATCHING GROUP SONG SERVICE PATTERN
  static Future<Map<String, dynamic>> getWorshipTeamLyricsByFormat({
    required String title,
    required String format,
  }) async {
    // Try the dedicated lyrics endpoint first (if it exists)
    try {
      final response = await _get(
        '/worship-teams/lyrics/format?title=${Uri.encodeComponent(title)}&format=$format',
      );
      return response['data'];
    } catch (e) {
      print('❌ Lyrics endpoint not available, falling back to search: $e');
    }

    // Fallback: search by title and build lyrics response
    try {
      final response = await _get(
        '/worship-teams/search/${Uri.encodeComponent(title)}',
      );

      if (response['data'] == null || (response['data'] as List).isEmpty) {
        throw ApiException('Worship team song not found: $title');
      }

      final List<dynamic> dataList = response['data'] as List;

      // Find exact match or first result
      Map<String, dynamic>? teamData;
      for (var item in dataList) {
        if ((item['songname'] as String?)?.toLowerCase() ==
            title.toLowerCase()) {
          teamData = item as Map<String, dynamic>;
          break;
        }
      }
      teamData ??= dataList.first as Map<String, dynamic>;

      // Build lyrics response matching group song format
      final lyricsMap = <String, dynamic>{};
      final displayOrder = <String>[];

      switch (format) {
        case 'tamil_only':
          if (teamData['lyrics_ta'] != null &&
              (teamData['lyrics_ta'] as String).trim().isNotEmpty) {
            lyricsMap['ta'] = teamData['lyrics_ta'];
            displayOrder.add('ta');
          }
          break;
        case 'english_only':
          if (teamData['lyrics_en'] != null &&
              (teamData['lyrics_en'] as String).trim().isNotEmpty) {
            lyricsMap['en'] = teamData['lyrics_en'];
            displayOrder.add('en');
          }
          break;
        case 'sinhala_only':
          if (teamData['lyrics_si'] != null &&
              (teamData['lyrics_si'] as String).trim().isNotEmpty) {
            lyricsMap['si'] = teamData['lyrics_si'];
            displayOrder.add('si');
          }
          break;
        case 'tamil_english':
          if (teamData['lyrics_ta'] != null &&
              (teamData['lyrics_ta'] as String).trim().isNotEmpty) {
            lyricsMap['ta'] = teamData['lyrics_ta'];
            displayOrder.add('ta');
          }
          if (teamData['lyrics_en'] != null &&
              (teamData['lyrics_en'] as String).trim().isNotEmpty) {
            lyricsMap['en'] = teamData['lyrics_en'];
            displayOrder.add('en');
          }
          break;
        case 'tamil_sinhala':
          if (teamData['lyrics_ta'] != null &&
              (teamData['lyrics_ta'] as String).trim().isNotEmpty) {
            lyricsMap['ta'] = teamData['lyrics_ta'];
            displayOrder.add('ta');
          }
          if (teamData['lyrics_si'] != null &&
              (teamData['lyrics_si'] as String).trim().isNotEmpty) {
            lyricsMap['si'] = teamData['lyrics_si'];
            displayOrder.add('si');
          }
          break;
        case 'all_three':
        default:
          if (teamData['lyrics_ta'] != null &&
              (teamData['lyrics_ta'] as String).trim().isNotEmpty) {
            lyricsMap['ta'] = teamData['lyrics_ta'];
            displayOrder.add('ta');
          }
          if (teamData['lyrics_si'] != null &&
              (teamData['lyrics_si'] as String).trim().isNotEmpty) {
            lyricsMap['si'] = teamData['lyrics_si'];
            displayOrder.add('si');
          }
          if (teamData['lyrics_en'] != null &&
              (teamData['lyrics_en'] as String).trim().isNotEmpty) {
            lyricsMap['en'] = teamData['lyrics_en'];
            displayOrder.add('en');
          }
          break;
      }

      return {
        'song': teamData['songname'],
        'artist': teamData['artist_name'] ?? 'Unknown Artist',
        'format': format,
        'lyrics': lyricsMap,
        'displayOrder': displayOrder,
        'totalLanguages': displayOrder.length,
      };
    } catch (e) {
      throw ApiException('Failed to get worship team lyrics: $e');
    }
  }

  void dispose() {
    _apiService.dispose();
  }
}
