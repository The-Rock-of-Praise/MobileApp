import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/database_helper.dart';
import 'package:lyrics/Service/worship_team_service.dart';
import 'package:lyrics/Models/worship_team_model.dart';
import 'package:sqflite/sqflite.dart';

class OfflineWorshipTeamService {
  final WorshipTeamService _onlineService;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  OfflineWorshipTeamService({WorshipTeamService? onlineService})
    : _onlineService = onlineService ?? WorshipTeamService();

  Future<Map<String, dynamic>> getAllWorshipTeams() async {
    final isConnected = await _connectivityManager.isConnected();
    if (isConnected) {
      try {
        final result = await _onlineService.getAllWorshipTeams();
        print(result);
        if (result['success']) {
          final teams =
              (result['worshipTeams'] as List).cast<WorshipTeamModel>();
          await _cacheWorshipTeams(teams);
          return {...result, 'source': 'online'};
        }
      } catch (e) {
        print('⚠️ Online worship teams fetch failed: $e');
        // fallthrough to cache
      }
    }
    return await _getCachedWorshipTeams();
  }

  Future<Map<String, dynamic>> getWorshipTeamsByLanguage(
    String language,
  ) async {
    // For simplicity, fetch all and filter by language
    // final result = await getAllWorshipTeams();
    final isconnected = await _connectivityManager.isConnected();
    print('Checking connectivity for language $language: $isconnected');

    if (isconnected) {
      try {
        final result = await WorshipTeamService.getWorshipTeamsByLanguage(
          language,
        );
        // result is now a Map<String, dynamic> with 'success' and 'worshipTeams' keys
        if (result['success'] == true) {
          // Cache the fetched worship teams for offline access
          final worshipTeamsData =
              result['worshipTeams'] as List<dynamic>? ?? [];
          final teams =
              worshipTeamsData
                  .map(
                    (item) =>
                        item is WorshipTeamModel
                            ? item
                            : WorshipTeamModel.fromJson(
                              item as Map<String, dynamic>,
                            ),
                  )
                  .toList();
          await _cacheWorshipTeams(teams);

          return {
            'success': true,
            'worshipTeams': result['worshipTeams'],
            'language': language,
            'source': 'online',
          };
        }
      } catch (e) {
        print('Error fetching worship teams online: $e');
      }
    }

    // Fallback: return cached worship teams filtered by language when possible
    try {
      final db = await _dbHelper.database;
      // Try to find rows where language matches or artist_languages contains the code
      final maps = await db.query(
        'worship_teams',
        where: 'language = ? OR artist_languages LIKE ?',
        whereArgs: [language, '%$language%'],
        orderBy: 'created_at DESC',
      );
      final items = maps.map((m) => WorshipTeamModel.fromJson(m)).toList();
      return {'success': true, 'worshipTeams': items, 'source': 'cache'};
    } catch (e) {
      print('⚠️ Error reading cached worship teams by language: $e');
      return _getCachedWorshipTeams();
    }
  }

  // Get worship team lyrics by format with offline support - MATCHING GROUP SONG PATTERN
  Future<Map<String, dynamic>> getWorshipTeamLyricsByFormat({
    required String title,
    required String format,
  }) async {
    final isConnected = await _connectivityManager.isConnected();

    if (isConnected) {
      try {
        final result = await WorshipTeamService.getWorshipTeamLyricsByFormat(
          title: title,
          format: format,
        );
        return {'success': true, 'data': result, 'source': 'online'};
      } catch (e) {
        print('❌ Online fetch failed, using cache: $e');
      }
    }

    return await _getCachedWorshipTeamLyricsByFormat(title, format);
  }

  // Get cached worship team lyrics by format
  Future<Map<String, dynamic>> _getCachedWorshipTeamLyricsByFormat(
    String title,
    String format,
  ) async {
    final db = await _dbHelper.database;

    // Ensure table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_teams (
        id INTEGER PRIMARY KEY,
        songname TEXT,
        name TEXT,
        lyrics_si TEXT,
        lyrics_en TEXT,
        lyrics_ta TEXT,
        artist_id INTEGER,
        artist_name TEXT,
        artist_image TEXT,
        duration INTEGER,
        notes TEXT,
        image TEXT,
        artist_languages TEXT,
        language TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    final maps = await db.query(
      'worship_teams',
      where: 'songname LIKE ?',
      whereArgs: ['%$title%'],
      limit: 1,
    );

    if (maps.isEmpty) {
      return {
        'success': false,
        'message': 'Worship team song not found in cache: $title',
      };
    }

    final team = WorshipTeamModel.fromJson(maps.first);

    // Parse format and build lyrics response
    final lyricsResponse = <String, dynamic>{};
    final displayOrder = <String>[];
    bool hasRequiredLyrics = false;

    switch (format) {
      case 'tamil_only':
        if (team.lyricsTa != null && team.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = team.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        break;
      case 'english_only':
        if (team.lyricsEn != null && team.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = team.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
      case 'sinhala_only':
        if (team.lyricsSi != null && team.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = team.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        break;
      case 'tamil_english':
        if (team.lyricsTa != null && team.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = team.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (team.lyricsEn != null && team.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = team.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
      case 'tamil_sinhala':
        if (team.lyricsTa != null && team.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = team.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (team.lyricsSi != null && team.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = team.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        break;
      case 'all_three':
        if (team.lyricsTa != null && team.lyricsTa!.trim().isNotEmpty) {
          lyricsResponse['ta'] = team.lyricsTa;
          displayOrder.add('ta');
          hasRequiredLyrics = true;
        }
        if (team.lyricsSi != null && team.lyricsSi!.trim().isNotEmpty) {
          lyricsResponse['si'] = team.lyricsSi;
          displayOrder.add('si');
          hasRequiredLyrics = true;
        }
        if (team.lyricsEn != null && team.lyricsEn!.trim().isNotEmpty) {
          lyricsResponse['en'] = team.lyricsEn;
          displayOrder.add('en');
          hasRequiredLyrics = true;
        }
        break;
    }

    if (!hasRequiredLyrics) {
      return {
        'success': false,
        'message':
            'No lyrics available for this song in $format format from cache',
      };
    }

    return {
      'success': true,
      'song': team.songname,
      'artist': team.artistName ?? 'Unknown Artist',
      'format': format,
      'lyrics': lyricsResponse,
      'displayOrder': displayOrder,
      'availableLanguages': _getAvailableLanguages(team),
      'totalLanguages': displayOrder.length,
      'message': 'Worship team lyrics loaded from cache',
      'source': 'cache',
    };
  }

  List<String> _getAvailableLanguages(WorshipTeamModel team) {
    final available = <String>[];
    if (team.lyricsTa != null && team.lyricsTa!.trim().isNotEmpty) {
      available.add('ta');
    }
    if (team.lyricsSi != null && team.lyricsSi!.trim().isNotEmpty) {
      available.add('si');
    }
    if (team.lyricsEn != null && team.lyricsEn!.trim().isNotEmpty) {
      available.add('en');
    }
    return available;
  }

  Future<void> _cacheWorshipTeams(List<WorshipTeamModel> teams) async {
    final db = await _dbHelper.database;
    // Ensure table exists (simple create)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_teams (
        id INTEGER PRIMARY KEY,
        songname TEXT,
        name TEXT,
        lyrics_si TEXT,
        lyrics_en TEXT,
        lyrics_ta TEXT,
        artist_id INTEGER,
        artist_name TEXT,
        artist_image TEXT,
        duration INTEGER,
        notes TEXT,
        image TEXT,
        artist_languages TEXT,
        language TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    for (final t in teams) {
      final map = t.toJson();
      // Ensure artist_languages is stored as a JSON string
      if (map.containsKey('artist_languages')) {
        try {
          final langs = map['artist_languages'];
          if (langs is List) {
            map['artist_languages'] = langs.join(',');
          } else if (langs is String) {
            // keep as-is
          } else {
            map['artist_languages'] = '';
          }
        } catch (_) {
          map['artist_languages'] = '';
        }
      }

      try {
        await db.insert(
          'worship_teams',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('⚠️ Failed to cache worship team id=${t.id}: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _getCachedWorshipTeams() async {
    final db = await _dbHelper.database;
    final maps = await db.query('worship_teams', orderBy: 'created_at DESC');
    final items = maps.map((m) => WorshipTeamModel.fromJson(m)).toList();
    return {
      'success': true,
      'worshipTeams': items,
      'message': 'Worship teams loaded from cache',
      'source': 'cache',
    };
  }

  void dispose() {
    // nothing to dispose for now
  }
}
