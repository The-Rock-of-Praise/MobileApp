import 'dart:ui'; // මෙය අනිවාර්යයෙන්ම තිබිය යුතුය
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/Const/const.dart';
import 'package:lyrics/Models/artist_model.dart';
import 'package:lyrics/Models/song_model.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_album_service.dart';
import 'package:lyrics/OfflineService/offline_artist_service.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/OfflineService/offline_worship_team_service.dart';
import 'package:lyrics/Models/worship_team_model.dart';
import 'package:lyrics/Service/worship_entity_service.dart';
import 'package:lyrics/OfflineService/offline_worship_entity_service.dart';
import 'package:lyrics/Service/group_song_service.dart';
import 'package:lyrics/Service/worship_team_service.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/OfflineService/offline_song_service.dart';
import 'package:lyrics/OfflineService/sync_manager.dart';
import 'package:lyrics/Screens/DrawerScreens/about_app.dart';
import 'package:lyrics/Screens/DrawerScreens/featured_songs.dart';
import 'package:lyrics/Screens/DrawerScreens/how_ro_read_lyrics.dart';
import 'package:lyrics/Screens/DrawerScreens/my_set_list.dart';
import 'package:lyrics/Screens/DrawerScreens/privacy_policy.dart';
import 'package:lyrics/Screens/DrawerScreens/setting_screen.dart';
import 'package:lyrics/Screens/DrawerScreens/worship_note_screen.dart';
import 'package:lyrics/Screens/Profile/profile.dart';
import 'package:lyrics/Screens/DrawerScreens/premium_screen.dart';
import 'package:lyrics/Screens/ablum_page.dart';
import 'package:lyrics/Screens/all_songs.dart';
import 'package:lyrics/Screens/artist_page.dart';
import 'package:lyrics/Screens/language_screen.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/Screens/worship_team.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/Service/search_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/Service/theme_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lyrics/Screens/worship_artist_page.dart';
import 'package:lyrics/Screens/worship_artist_album_song_details.dart';
import 'package:lyrics/Screens/notification_screen.dart';
import 'package:lyrics/OfflineService/offline_notification_service.dart';

import '../collaborations.dart';
import '../worship_team_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // final SearchService _searchService = SearchService(
  //   baseUrl: 'http://145.223.21.62:3100',
  // );
  // final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  String selectedTheme = 'Dark';
  bool isAutomaticTheme = false;

  // API Services
  // final ArtistService _artistService = ArtistService();
  // final AlbumService _albumService = AlbumService();

  final OfflineArtistService _artistService = OfflineArtistService();
  final OfflineAlbumService _albumService = OfflineAlbumService();
  final OfflineUserService _userService = OfflineUserService();
  final OfflineGroupSongService _groupSongService = OfflineGroupSongService();
  final OfflineWorshipTeamService _worshipTeamService =
      OfflineWorshipTeamService();
  final OfflineWorshipEntityService _worshipEntityService =
      OfflineWorshipEntityService();
  final OfflineNotificationService _notificationService =
      OfflineNotificationService();
  final OfflineSongService _songService =
      OfflineSongService(); // Use offline service for language filtering
  late final OfflineSearchService _searchService;

  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final SyncManager _syncManager = SyncManager();
  bool _isOnline = false;

  // Data lists
  List<ArtistModel> artists = [];
  List<AlbumModel> albums = [];
  List<AlbumModel> latestAlbums = [];
  List<Map<String, dynamic>> recentReleases =
      []; // Combined songs and group-songs
  List<GroupSongModel> groupSongs = [];
  // Worship teams list (use dedicated model)
  List<WorshipTeamModel> worshipTeams = [];
  List<WorshipArtistModel> worshipArtists = [];
  List<WorshipAlbumModel> worshipAlbums = [];
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? _currentUser;
  Map<String, dynamic>? _profileDetails;

  String? currentLanguage;
  String? languageDisplayName;

  // Loading states
  bool isLoadingArtists = true;
  bool isLoadingAlbums = true;
  bool isLoadingGroupSongs = true;
  bool isLoadingRecentReleases = true;
  bool isLoadingWorshipArtists = true;
  bool isLoadingWorshipAlbums = true;
  int unreadNotificationCount = 0;

  bool isPremium = false;

  int _currentCarouselIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? profileImageUrl;

  final List<String> premiumFeatures = [
    'Unlimited offline access',
    'Download songs & albums',
    'No advertisements',
    'High quality audio',
    'Exclusive premium content',
    'Priority customer support',
  ];

  // Icons for each premium feature (shown only when offline)
  final List<IconData> premiumFeatureIcons = [
    Icons.offline_pin,
    Icons.download,
    Icons.block,
    Icons.high_quality,
    Icons.star,
    Icons.support_agent,
  ];

  @override
  void initState() {
    super.initState();
    _searchService =
        OfflineSearchService(baseUrl: 'https://api.therockofpraise.org');
    _initializeConnectivity();
    loadPremiumStatus();
    _loadThemeSettings();
    _loadData();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      await _notificationService.syncNotifications();
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  Future<void> _loadThemeSettings() async {
    try {
      final theme = await ThemeService.getTheme();
      final automaticTheme = await ThemeService.getAutomaticTheme();

      setState(() {
        selectedTheme = theme;
        isAutomaticTheme = automaticTheme;
      });
    } catch (e) {
      print('Error loading theme settings: $e');
    }
  }
  // Future<void> _loadData() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   final List<Future> loads = [
  //     loadPremiumStatus().catchError(
  //       (e) => print('premium status load error: $e'),
  //     ),
  //     _loadProfileData().catchError((e) => print('Profile load error: $e')),
  //     _loadArtists().catchError((e) => print('Artists load error: $e')),
  //     // _loadAlbums().catchError((e) => print('Albums load error: $e')),
  //     getLang().catchError((e) => print('lang album load error: $e')),
  //     _loadLatestAlbums().catchError((e) => print('Latest albums error: $e')),
  //   ];

  //   try {
  //     await Future.wait(loads);
  //   } catch (e) {
  //     print('Composite load error: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Widget _buildPremiumFeatureItem(String feature, bool showIcons, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (showIcons) ...[
            Icon(premiumFeatureIcons[index], color: Colors.amber, size: 20),
            SizedBox(width: 12),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to premium upgrade screen
  void _navigateToPremiumUpgrade() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumScreen()),
    );
    
    if (result == true) {
      // User successfully upgraded, reload premium status to update UI
      loadPremiumStatus();
    }
  }

  void _showConnectivityInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Connect to Internet',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To upgrade to Premium and enable offline features:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),
              _buildConnectivityStep('1', 'Connect to Wi-Fi or mobile data'),
              _buildConnectivityStep('2', 'Tap "Get Premium" to upgrade'),
              _buildConnectivityStep('3', 'Enjoy unlimited offline access'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premium subscription requires internet connection for initial setup.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectivityStep(String step, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeConnectivity() async {
    // Check initial connectivity
    _isOnline = await _connectivityManager.isConnected();

    // Listen to connectivity changes
    _connectivityManager.connectivityStream.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (mounted) {
        setState(() {});

        // Show connectivity status
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(_isOnline ? '🌐 Back online' : '📱 Offline mode'),
        //     duration: Duration(seconds: 2),
        //     backgroundColor: _isOnline ? Colors.green : Colors.orange,
        //   ),
        // );

        // Trigger sync when coming back online
        if (_isOnline && wasOffline) {
          _performBackgroundSync();
        }
      }
    });
  }

  Future<void> _performBackgroundSync() async {
    try {
      await _syncManager.performFullSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data synchronized'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
        // Reload data after sync
        _loadData();
      }
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final List<Future> loads = [
      loadPremiumStatus().catchError(
        (e) => print('premium status load error: $e'),
      ),
      _loadProfileData().catchError((e) => print('Profile load error: $e')),
      _loadArtists().catchError((e) => print('Artists load error: $e')),
      getLang().catchError((e) => print('lang album load error: $e')),
      _loadLatestAlbums().catchError((e) => print('Latest albums error: $e')),
      _loadRecentReleases().catchError(
        (e) => print('Recent releases load error: $e'),
      ),
      _loadGroupSongs().catchError((e) => print('Group songs load error: $e')),
      _loadWorshipTeams().catchError(
        (e) => print('Worship teams load error: $e'),
      ),
      _loadWorshipArtists().catchError(
        (e) => print('Worship artists load error: $e'),
      ),
      _loadWorshipAlbums().catchError(
        (e) => print('Worship albums load error: $e'),
      ),
    ];

    try {
      await Future.wait(loads);
    } catch (e) {
      print('Composite load error: $e');
      // Even if some operations fail, we should show what we can
      setState(() {
        _errorMessage = 'Some content may not be up to date';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGroupSongs() async {
    try {
      setState(() => isLoadingGroupSongs = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);
      print('Loading group songs for language: $langcode');

      // Load group songs via offline service
      final result = await OfflineGroupSongService().getGroupSongsByLanguage(
        langcode,
      );

      if (result['success'] == true) {
        final groupSongsData = result['groupSongs'] as List<dynamic>? ?? [];
        final List<GroupSongModel> loadedGroupSongs =
            groupSongsData
                .map(
                  (item) =>
                      item is GroupSongModel
                          ? item
                          : GroupSongModel.fromJson(
                            item as Map<String, dynamic>,
                          ),
                )
                .toList();

        setState(() {
          groupSongs = loadedGroupSongs;
          isLoadingGroupSongs = false;
        });
      } else {
        setState(() => isLoadingGroupSongs = false);
        _showErrorMessage(result['message'] ?? 'Failed to load group songs');
      }
    } catch (e) {
      print('Group songs load error: $e');
      setState(() => isLoadingGroupSongs = false);
      _showErrorMessage('Error loading group songs: ${e.toString()}');
    }
  }

  Future<void> _loadWorshipTeams() async {
    try {
      setState(() => isLoadingGroupSongs = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);
      print('Loading worship teams for language: $langcode');

      // Load worship teams via offline service
      final result = await _worshipTeamService.getWorshipTeamsByLanguage(
        langcode,
      );
      print('Worship teams by language response: $result');

      if (result['success']) {
        final teamsData = result['worshipTeams'] as List<dynamic>? ?? [];
        final List<WorshipTeamModel> loadedTeams = [];
        for (var songData in teamsData) {
          try {
            WorshipTeamModel wt;
            if (songData is WorshipTeamModel) {
              wt = songData;
            } else if (songData is Map<String, dynamic>) {
              wt = WorshipTeamModel.fromJson(songData);
            } else {
              continue;
            }
            loadedTeams.add(wt);
          } catch (e) {
            print('Error parsing worship team item: $e');
          }
        }

        setState(() {
          worshipTeams = loadedTeams;
          isLoadingGroupSongs = false;
        });

        print('✅ Loaded ${loadedTeams.length} worship teams');
      } else {
        setState(() => isLoadingGroupSongs = false);
        _showErrorMessage(result['message'] ?? 'Failed to load worship teams');
      }
    } catch (e) {
      print('Worship teams load error: $e');
      setState(() => isLoadingGroupSongs = false);
      _showErrorMessage('Error loading worship teams: ${e.toString()}');
    }
  }

  Future<void> _loadWorshipArtists() async {
    try {
      setState(() => isLoadingWorshipArtists = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);
      print('Loading worship artists for language: $langcode');

      // Load worship artists via offline service
      final result = await _worshipEntityService.getWorshipArtistsByLanguage(
        langcode,
      );

      if (result['success']) {
        final List<WorshipArtistModel> loadedArtists =
            List<WorshipArtistModel>.from(result['artists']);

        setState(() {
          worshipArtists = loadedArtists;
          isLoadingWorshipArtists = false;
        });

        print('✅ Loaded ${loadedArtists.length} worship artists');
      } else {
        setState(() => isLoadingWorshipArtists = false);
        _showErrorMessage(result['message'] ?? 'Failed to load worship artists');
      }
    } catch (e) {
      print('Worship artists load error: $e');
      setState(() => isLoadingWorshipArtists = false);
      _showErrorMessage('Error loading worship artists: ${e.toString()}');
    }
  }

  Future<void> _loadWorshipAlbums() async {
    try {
      setState(() => isLoadingWorshipAlbums = true);
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);
      
      final result = await _worshipEntityService.getLatestWorshipAlbums(lang: langcode);
      if (result['success']) {
        setState(() {
          worshipAlbums = List<WorshipAlbumModel>.from(result['albums']);
          isLoadingWorshipAlbums = false;
        });
      } else {
        setState(() => isLoadingWorshipAlbums = false);
      }
    } catch (e) {
      print('Worship albums load error: $e');
      setState(() => isLoadingWorshipAlbums = false);
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showOfflineMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<int> _getArtistTotalSongCount(int? artistId) async {
    if (artistId == null) return 0;

    try {
      final result = await _artistService.getArtistSongs(artistId);
      if (result['success']) {
        final songs = result['songs'] as List<dynamic>? ?? [];
        return songs.length;
      }
    } catch (e) {
      print('Error getting artist song count: $e');
    }
    return 0;
  }

  Future<void> loadPremiumStatus() async {
    final ispremiun = await UserService.getIsPremium();
    print('premium state is: $ispremiun');
    setState(() {
      isPremium = ispremiun == '1';
    });
  }

  Future<void> getLang() async {
    try {
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);
      print('Loading data for language: $langcode');

      // Store current language for comparison
      final oldLanguage = currentLanguage;
      currentLanguage = langcode;

      // If language changed or first load, refresh albums
      if (oldLanguage != langcode || albums.isEmpty) {
        await _loadAlbumsByLanguage(langcode);
      }
    } catch (e) {
      print('Error in getLang: $e');
      // Fallback to default language
      await _loadAlbumsByLanguage('en');
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Load basic user info
      // final userResult = await _userService.getCurrentUserProfile();
      // if (!userResult['success']) {
      //   throw Exception(userResult['message'] ?? 'Failed to load user profile');
      // }

      // _currentUser = userResult['user'] as UserModel?;
      final userID = await UserService.getUserID();

      // Load extended profile details if user exists
      final profileResult = await _userService.getFullProfile(userID);

      print('profile result in home ${profileResult['profile']}');
      if (profileResult['success']) {
        _profileDetails = profileResult['profile'] as Map<String, dynamic>?;
      }

      setState(() {
        profileImageUrl =
            _profileDetails?['profile']?['profile_image'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLatestAlbums() async {
    try {
      final result = await _albumService.getLatestAlbums();
      if (result['success']) {
        final albumsList = result['albums'] as List<dynamic>?;
        setState(() {
          latestAlbums = albumsList?.cast<AlbumModel>() ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading latest albums: $e')),
        );
      }
    }
  }

  Future<void> _loadRecentReleases() async {
    try {
      setState(() => isLoadingRecentReleases = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);

      // Fetch songs by language using offline service (which handles online + cache)
      final songsResult = await _songService.getSongsByLanguage(langcode);

      // Fetch group songs by language
      final groupSongsResult = await OfflineGroupSongService()
          .getGroupSongsByLanguage(langcode);

      List<Map<String, dynamic>> combinedReleases = [];

      // Process songs (already filtered by language from API)
      if (songsResult['success']) {
        final songsData = songsResult['songs'] as List<dynamic>? ?? [];
        final songs =
            songsData
                .map(
                  (item) =>
                      item is SongModel
                          ? item
                          : SongModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        // Add songs to combined list
        for (var song in songs) {
          combinedReleases.add({
            'type': 'song',
            'id': song.id,
            'title': song.songname,
            'artistName': song.artistName ?? 'Unknown Artist',
            'image': song.image ?? song.albumImage ?? song.artistImage,
            'releaseDate': song.releaseDate,
            'data': song,
          });
        }
      }

      // Process group songs
      if (groupSongsResult['success'] == true) {
        final groupSongsData =
            groupSongsResult['groupSongs'] as List<dynamic>? ?? [];
        final groupSongs =
            groupSongsData
                .map(
                  (item) =>
                      item is GroupSongModel
                          ? item
                          : GroupSongModel.fromJson(
                            item as Map<String, dynamic>,
                          ),
                )
                .toList();

        // Add group songs to combined list (already filtered by language from API)
        for (var groupSong in groupSongs) {
          final artistNames = groupSong.artists.map((a) => a.name).join(', ');

          combinedReleases.add({
            'type': 'group_song',
            'id': groupSong.id,
            'title': groupSong.songName,
            'artistName':
                artistNames.isNotEmpty ? artistNames : 'Unknown Artist',
            'image': groupSong.image,
            'releaseDate': groupSong.releaseDate,
            'data': groupSong,
          });
        }
      }

      // Sort by release_date descending (most recent first)
      combinedReleases.sort((a, b) {
        final aDate = a['releaseDate'];
        final bDate = b['releaseDate'];

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        try {
          final aDateTime = DateTime.parse(aDate);
          final bDateTime = DateTime.parse(bDate);
          return bDateTime.compareTo(aDateTime); // Descending order
        } catch (e) {
          return 0;
        }
      });

      // Take only the latest 10 items
      final latest10 =
          combinedReleases.length > 10
              ? combinedReleases.sublist(0, 10)
              : combinedReleases;

      if (mounted) {
        setState(() {
          recentReleases = latest10;
          isLoadingRecentReleases = false;
        });
      }
    } catch (e) {
      print('Exception loading recent releases: $e');
      if (mounted) {
        setState(() {
          isLoadingRecentReleases = false;
        });
      }
    }
  }

  Future<void> _loadArtists() async {
    try {
      setState(() => isLoadingArtists = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);

      // Use the language-specific endpoint
      final result = await _artistService.getArtistsByLanguage(langcode);
      print('Artists by language response: $result');

      if (result['success']) {
        final List<ArtistModel> loadedArtists = [];

        // Parse artists with error handling
        final artistsData = result['artists'] as List<dynamic>? ?? [];
        print('📊 Raw artists data count: ${artistsData.length}');

        for (var artistData in artistsData) {
          try {
            ArtistModel artist;
            if (artistData is ArtistModel) {
              artist = artistData;
            } else if (artistData is Map<String, dynamic>) {
              artist = ArtistModel.fromJson(artistData);
            } else {
              print(
                '⚠️ Skipping non-parseable artist data type: ${artistData.runtimeType}',
              );
              continue;
            }
            loadedArtists.add(artist);
          } catch (e) {
            print('❌ Error parsing artist: $e');
            print('Artist data: $artistData');
          }
        }

        print('✅ Successfully loaded ${loadedArtists.length} artists');
        setState(() {
          artists = loadedArtists;
          isLoadingArtists = false;
          currentLanguage = result['language'] ?? langcode;
          languageDisplayName =
              result['languageDisplayName'] ?? langcode.toUpperCase();
        });

        // Show offline indicator if using cached data
      } else {
        print('❌ Artist loading failed: ${result['message']}');
        setState(() => isLoadingArtists = false);
        _showErrorMessage(result['message'] ?? 'Failed to load artists');
      }
    } catch (e) {
      print('❌ Exception loading artists: $e');
      setState(() => isLoadingArtists = false);
      _showErrorMessage('Error loading artists: ${e.toString()}');
    }
  }
  // Future<void> _loadArtists() async {
  //   try {
  //     final result = await _artistService.getAllArtists();
  //     print('artist data in home: $result'); // Print the entire result first

  //     if (result['success']) {
  //       // No need to cast here since getAllArtists already returns List<ArtistModel>
  //       setState(() {
  //         artists = result['artists'] ?? [];
  //         isLoadingArtists = false;
  //       });
  //     } else {
  //       setState(() {
  //         isLoadingArtists = false;
  //       });
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(result['message'] ?? 'Failed to load artists'),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoadingArtists = false;
  //     });
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error loading artists: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }

  // Future<void> _loadAlbums() async {
  //   try {
  //     setState(() => isLoadingAlbums = true);

  //     final result = await _albumService.getAllAlbums();
  //     print('Raw albums API response: ${result.toString()}');

  //     if (result['success'] == true) {
  //       // Handle both List<dynamic> and List<AlbumModel> cases
  //       final List<dynamic> rawAlbums = result['albums'] ?? [];
  //       final List<AlbumModel> loadedAlbums = [];

  //       for (var albumData in rawAlbums) {
  //         try {
  //           AlbumModel album;
  //           if (albumData is AlbumModel) {
  //             album = albumData; // Already an AlbumModel
  //           } else if (albumData is Map<String, dynamic>) {
  //             album = AlbumModel.fromJson(albumData); // Parse from JSON
  //           } else {
  //             print('Invalid album data type: ${albumData.runtimeType}');
  //             continue;
  //           }
  //           loadedAlbums.add(album);
  //         } catch (e) {
  //           print('Failed to parse album: $albumData');
  //           print('Error: $e');
  //         }
  //       }

  //       setState(() {
  //         albums = loadedAlbums;
  //         isLoadingAlbums = false;
  //       });
  //     } else {
  //       setState(() => isLoadingAlbums = false);
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(result['message'] ?? 'Failed to load albums'),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e, stack) {
  //     print('Error in _loadAlbums: $e');
  //     print('Stack trace: $stack');
  //     setState(() => isLoadingAlbums = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error loading albums: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }

  Future<void> _loadAlbumsByLanguage(String language) async {
    try {
      setState(() => isLoadingAlbums = true);

      final result = await _albumService.getAlbumsByLanguage(language);
      print('Albums by language response: ${result.toString()}');

      if (result['success'] == true) {
        final List<AlbumModel> loadedAlbums = [];

        // Parse albums with error handling
        final albumsData = result['albums'] as List<dynamic>? ?? [];
        for (var albumData in albumsData) {
          try {
            AlbumModel album;
            if (albumData is AlbumModel) {
              album = albumData;
            } else if (albumData is Map<String, dynamic>) {
              album = AlbumModel.fromJson(albumData);
            } else {
              continue;
            }
            loadedAlbums.add(album);
          } catch (e) {
            print('Error parsing album: $e');
          }
        }

        setState(() {
          albums = loadedAlbums;
          isLoadingAlbums = false;
          currentLanguage = result['language'] ?? language;
          languageDisplayName =
              result['languageDisplayName'] ?? language.toUpperCase();
        });

        // Show offline indicator if using cached data
        if (result['source'] == 'cache' ||
            result['source'] == 'cache_fallback') {
          // _showOfflineMessage('Albums loaded from offline cache');
        }
      } else {
        setState(() => isLoadingAlbums = false);
        _showErrorMessage(result['message'] ?? 'Failed to load albums');
      }
    } catch (e, stack) {
      print('Error in _loadAlbumsByLanguage: $e');
      print('Stack trace: $stack');
      setState(() => isLoadingAlbums = false);
      _showErrorMessage('Error loading albums: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupSongService.dispose();
    _artistService.dispose();
    _albumService.dispose();
    _songService.dispose();
    super.dispose();
  }

  void _searchArtists(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await _searchService.search(query);
      final groupSongResult = await _groupSongService.searchGroupSongs(query);

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (result['success']) {
            _searchResults = [
              ...(result['artists'] as List<dynamic>? ?? []),
              ...(result['albums'] as List<dynamic>? ?? []),
              ...(result['songs'] as List<dynamic>? ?? []),
              ...(groupSongResult['groupSongs'] as List<dynamic>? ?? []),
            ];
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Search failed')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  Widget _buildGroupSongSearchItem(GroupSongModel groupSong) {
    return ListTile(
      leading: CachedImageWidget(
        imageUrl: groupSong.image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        errorWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.group, color: Colors.white54, size: 24),
        ),
      ),
      title: Text(
        groupSong.songName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Group Song • ${groupSong.artists.map((a) => a.name).join(', ')}',
        style: const TextStyle(color: Colors.white70),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        // Your navigation logic here
      },
    );
  }

  // Add this method to build search results
  Widget _buildSearchResults() {
    if (!_isSearching && _searchResults.isEmpty) return const SizedBox();

    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Text(
            'Search Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final item = _searchResults[index];

            if (item is ArtistModel) {
              return _buildArtistSearchItem(item);
            } else if (item is AlbumModel) {
              return _buildAlbumSearchItem(item);
            } else if (item is SongModel) {
              return _buildSongSearchItem(item);
            } else if (item is GroupSongModel) {
              // Add this condition
              return _buildGroupSongSearchItem(item);
            } else {
              return const SizedBox();
            }
          },
        ),
      ],
    );
  }

  Widget _buildArtistSearchItem(ArtistModel artist) {
    return ListTile(
      leading: CachedImageWidget(
        imageUrl: artist.image,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(20), // Make it circular
        errorWidget: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(Icons.person, color: Colors.white54, size: 20),
        ),
      ),
      title: Text(artist.name, style: const TextStyle(color: Colors.white)),
      subtitle: const Text('Artist', style: TextStyle(color: Colors.white70)),
      onTap: () => _navigateToArtistAlbums(artist),
    );
  }

  Widget _buildAlbumSearchItem(AlbumModel album) {
    return ListTile(
      leading: CachedImageWidget(
        imageUrl: album.image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        errorWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.album, color: Colors.white54, size: 24),
        ),
      ),
      title: Text(album.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        'Album • ${album.artistName ?? 'Unknown Artist'}',
        style: const TextStyle(color: Colors.white70),
      ),
      onTap: () => _navigateToAlbumSongs(album),
    );
  }

  Widget _buildSongSearchItem(SongModel song) {
    return ListTile(
      leading: CachedImageWidget(
        imageUrl: song.image ?? song.albumImage,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        errorWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.music_note, color: Colors.white54, size: 24),
        ),
      ),
      title: Text(song.songname, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        'Song • ${song.artistName ?? 'Unknown Artist'}',
        style: const TextStyle(color: Colors.white70),
      ),
      onTap: () async {
        final isConnected = await _connectivityManager.isConnected();
        final isPremiumStr = await UserService.getIsPremium();
        final isPremium = isPremiumStr == '1';

        // If user is offline and not premium, show premium dialog
        if (!isConnected && !isPremium) {
          _showPremiumDialog(isOffline: true, feature: 'albums and songs');
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MusicPlayer(
                  backgroundImage: song.image ?? song.albumImage ?? '',
                  song: song.songname,
                  artist: song.artistName ?? 'Unknown Artist',
                  id: song.id!,
                ),
          ),
        );
      },
    );
  }

  Widget _buildGroupSongCard(GroupSongModel groupSong) {
    return Container(
      width: 120,
      height: 150,
      // decoration: BoxDecoration(
      //   color: Colors.white.withOpacity(0.05),
      //   borderRadius: BorderRadius.circular(15),
      //   border: Border.all(color: Colors.white.withOpacity(0.1)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedImageWidget(
              imageUrl: groupSong.image,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 110,
                height: 110,
                color: Colors.grey[800],
                child: const Icon(Icons.person, color: Colors.white24, size: 40),
              ),
            ),
          ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              groupSong.songName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '${groupSong.artists.length} Artists',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorshipTeamCard(WorshipTeamModel wt) {
    return Container(
      width: 120,
      height: 150,
      // decoration: BoxDecoration(
      //   color: Colors.white.withOpacity(0.05),
      //   borderRadius: BorderRadius.circular(15),
      //   border: Border.all(color: Colors.white.withOpacity(0.1)),
      // ),
      decoration: BoxDecoration(
        color: Colors.transparent, 
        border: Border.all(color: Colors.transparent, width: 0), 
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        // 1. Image එක
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedImageWidget(
              imageUrl: wt.image,
              width: 110,
              height: 110, // Image එකේ උස පමණක්
              fit: BoxFit.cover,
              errorWidget: Container(
                color: Colors.grey[800],
                child: const Icon(Icons.group, color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        
        // 2. Image එක සහ Text අතර පරතරය
        const SizedBox(height: 15),

        // 3. පහළින් ඇති Text කොටස
       Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            wt.songname,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible, // ellipsis වෙනුවට visible දාන්න
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            wt.artistName ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
    );
  }

  void _showWorshipTeamDetail(WorshipTeamModel wt) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    // If user is offline and not premium, show premium dialog
    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'worship team songs');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MusicPlayer(
              backgroundImage: wt.image,
              song: wt.songname,
              id: wt.id ?? 0,
              artist: wt.artistName ?? 'Unknown Artist',
              isWorshipTeam: true,
              lyrics: wt.lyricsEn,
            ),
      ),
    );
  }

  // Add this method to navigate to group song
  void _navigateToGroupSong(GroupSongModel groupSong) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    // If user is offline and not premium, show premium dialog
    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'albums and songs');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MusicPlayer(
              backgroundImage: groupSong.image,
              song: groupSong.songName,
              id: groupSong.id,
              artists: groupSong.artists,
            ),
      ),
    );
  }

  Widget _buildFeaturedAlbumsCarousel() {
    // Show loading indicator while data is loading
    if (isLoadingRecentReleases) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (recentReleases.isEmpty) {
      return const SizedBox(height: 50);
    }

    return Column(
      children: [
        // Add padding to give space for the overflowing image
        Padding(
          padding: const EdgeInsets.only(
            top: 0.0,
          ), // More space for image overflow
           child: SizedBox(
            height: 200, // Increase total height to accommodate overflow
            child: CarouselSlider.builder(
  carouselController: _carouselController,
  itemCount: recentReleases.length,
  options: CarouselOptions(
    height: 160,
    viewportFraction: 0.9,
    enlargeCenterPage: true,
    autoPlay: true,
    autoPlayInterval: const Duration(seconds: 5),
    onPageChanged: (index, reason) {
      setState(() {
        _currentCarouselIndex = index;
      });
    },
  ),
  itemBuilder: (context, index, realIndex) {
  final item = recentReleases[index];
  final isGroupSong = item['type'] == 'group_song';

  return GestureDetector(
    onTap: () async {
      // ... onTap logic එක (වෙනසක් කර නැත)
      final isConnected = await _connectivityManager.isConnected();
      final isPremiumStr = await UserService.getIsPremium();
      final isPremium = isPremiumStr == '1';

      if (!isConnected && !isPremium) {
        _showPremiumDialog(isOffline: true, feature: 'songs');
        return;
      }

      if (isGroupSong) {
        final groupSong = item['data'] as GroupSongModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayer(
              backgroundImage: groupSong.image,
              song: groupSong.songName,
              id: groupSong.id,
              artists: groupSong.artists,
            ),
          ),
        );
      } else {
        final song = item['data'] as SongModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayer(
              backgroundImage: song.image ?? song.albumImage ?? '',
              song: song.songname,
              artist: song.artistName ?? 'Unknown Artist',
              id: song.id!,
            ),
          ),
        );
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 1. Background Image
              Positioned.fill(
                child: (item['image'] != null)
                    ? CachedImageWidget(
                        imageUrl: item['image'],
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey[900]),
              ),

              // 2. සංශෝධිත Gradient Overlay (Dark to Navy Blue)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.9),      // වම් පැත්ත තද කළු/Dark
                        // const Color(0xFF000080).withOpacity(0.8), // Navy Blue
                        // const Color(0xFF000080).withOpacity(0.2), // ලා Navy Blue
                        Colors.transparent,                 // කෙළවර විනිවිද පෙනෙන
                      ],
                    ),
                  ),
                ),
              ),

              // 3. සංශෝධිත Text Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Latest Release - වම්පස ඉහළට
                    Text(
                      isGroupSong ? 'Latest Collaboration' : 'Latest Release',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Spacer(), // මැද ඉඩ ලබා දී අකුරු පහළට තල්ලු කරයි

                    // Song Name සහ Artist - වම්පස පහළට
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        item['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17, // Font size එක 20 සිට 17 ට අඩු කළා
                          fontWeight: FontWeight.bold, // Bold කර ඇත
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(1, 1))
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['artistName'] ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Artist font size එකත් 14 සිට 13 ට අඩු කළා
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
},
),),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              recentReleases.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _carouselController.animateToPage(entry.key),
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(
                            _currentCarouselIndex == entry.key ? 0.9 : 0.4,
                          ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildCustomDrawer(),
        body: MainBAckgound(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(),
                            ),
                          );
                          _loadNotificationCount(); // Refresh count when coming back
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 26),
                            if (unreadNotificationCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    unreadNotificationCount > 9
                                        ? '9+'
                                        : unreadNotificationCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Featured Albums Carousel
                _buildFeaturedAlbumsCarousel(),

                const SizedBox(height: 20),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF363636),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search songs, albums, artists...',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isSearching = false;
                            _searchResults.clear();
                          });
                        }
                      },
                      onSubmitted: _searchArtists,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                _buildSearchResults(),

                // Artists Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Artists',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoadingArtists)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ArtistPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Artists Grid
                SizedBox(
                  height: 180,
                  child:
                      isLoadingArtists
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : artists.isEmpty
                          ? const Center(
                            child: Text(
                              'No artists found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: artists.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < artists.length - 1 ? 15 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    _navigateToArtistAlbums(artists[index]);
                                  },
                                  child: _buildArtistCard(artists[index]),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 23),

                // Albums Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Albums',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoadingAlbums)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AblumPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Albums Grid
                SizedBox(
                  height: 180,
                  child:
                      isLoadingAlbums
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : albums.isEmpty
                          ? const Center(
                            child: Text(
                              'No albums found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: albums.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < albums.length - 1 ? 15 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    _navigateToAlbumSongs(albums[index]);
                                  },
                                  child: _buildAlbumCard(albums[index]),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 23),

                //group songs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Worship Teams',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoadingWorshipArtists)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorshipArtistPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                //worship teams grid
                SizedBox(
                  height: 180,
                  child:
                      isLoadingWorshipArtists
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : worshipArtists.isEmpty
                          ? const Center(
                            child: Text(
                              'No worship artists found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: worshipArtists.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      index < worshipArtists.length - 1 ? 15 : 0,
                                ),
                                child: GestureDetector(
                                  onTap:
                                      () => _navigateToWorshipArtistDetails(
                                        worshipArtists[index],
                                      ),
                                  child: _buildWorshipArtistCard(
                                    worshipArtists[index],
                                  ),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 23),

                // Worship Albums Section
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text(
                //         'Worship Albums',
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 18,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       if (isLoadingWorshipAlbums)
                //         const SizedBox(
                //           width: 20,
                //           height: 20,
                //           child: CircularProgressIndicator(
                //             strokeWidth: 2,
                //             valueColor: AlwaysStoppedAnimation<Color>(
                //               Colors.white,
                //             ),
                //           ),
                //         ),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 15),

                // SizedBox(
                //   height: 190,
                //   child:
                //       isLoadingWorshipAlbums
                //           ? const Center(
                //             child: CircularProgressIndicator(
                //               valueColor: AlwaysStoppedAnimation<Color>(
                //                 Colors.white,
                //               ),
                //             ),
                //           )
                //           : worshipAlbums.isEmpty
                //           ? const Center(
                //             child: Text(
                //               'No worship albums found',
                //               style: TextStyle(color: Colors.white70),
                //             ),
                //           )
                //           : ListView.builder(
                //             scrollDirection: Axis.horizontal,
                //             padding: const EdgeInsets.symmetric(horizontal: 20),
                //             itemCount: worshipAlbums.length,
                //             itemBuilder: (context, index) {
                //               return Padding(
                //                 padding: EdgeInsets.only(
                //                   right:
                //                       index < worshipAlbums.length - 1 ? 15 : 0,
                //                 ),
                //                 child: GestureDetector(
                //                   onTap: () {
                //                     _navigateToWorshipAlbumDetails(
                //                       worshipAlbums[index],
                //                     );
                //                   },
                //                   child: _buildWorshipAlbumCard(
                //                     worshipAlbums[index],
                //                   ),
                //                 ),
                //               );
                //             },
                //           ),
                // ),

                // const SizedBox(height: 30),

                //collaborations section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Collaborations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoadingGroupSongs)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CollaborationsPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                SizedBox(
                  height: 180,
                  child:
                      isLoadingGroupSongs
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : groupSongs.isEmpty
                          ? const Center(
                            child: Text(
                              'No collaborations found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: groupSongs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < groupSongs.length - 1 ? 15 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    _navigateToGroupSong(groupSongs[index]);
                                  },
                                  child: _buildGroupSongCard(groupSongs[index]),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToArtistAlbums(ArtistModel artist) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    // If user is offline and not premium, show premium dialog
    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'albums and songs');
      return;
    }
    // Navigate to artist's albums/songs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllSongs(artistId: artist.id, artistName: artist.name),
      ),
    );
  }

  void _navigateToWorshipArtistDetails(WorshipArtistModel artist) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'albums and songs');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorshipArtistAlbumSongDetails(
              artistId: artist.id!,
              artistName: artist.name,
              artistImage: artist.image,
            ),
      ),
    );
  }

  Widget _buildWorshipArtistCard(WorshipArtistModel artist) {
    return Container(
      width: 120,
      height: 150,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedImageWidget(
                imageUrl: artist.image,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[800],
                  child:
                      const Icon(Icons.person, color: Colors.white24, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              artist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '${artist.albumCount ?? 0} Albums',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorshipAlbumCard(WorshipAlbumModel album) {
    return Container(
      width: 120,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedImageWidget(
                imageUrl: album.image,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey[800],
                  child:
                      const Icon(Icons.album, color: Colors.white24, size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  album.artistName ?? 'Unknown Artist',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWorshipAlbumDetails(WorshipAlbumModel album) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorshipArtistAlbumSongDetails(
              artistId: album.artistId,
              artistName: album.artistName ?? 'Unknown Artist',
              artistImage: album.artistImage,
            ),
      ),
    );
  }

  void _showPremiumDialog({
    bool isOffline = false,
    String feature = 'this content',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOffline ? Icons.wifi_off : Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOffline ? 'Offline Access Restricted' : 'Premium Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.1),
                        Colors.orange.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOffline) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'You are currently offline',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'To access $feature while offline, you need a Premium subscription.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connect to the internet and upgrade to Premium for full offline access.',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ] else ...[
                        Text(
                          'Access to $feature requires a Premium subscription.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Premium features list
                Text(
                  'Premium Features Include:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),

                ...premiumFeatures.asMap().entries.map(
                  (entry) => _buildPremiumFeatureItem(
                    entry.value,
                    isOffline,
                    entry.key,
                  ),
                ),

                SizedBox(height: 16),

                // Special offline benefits
                if (isOffline) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Offline Benefits',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Access all content without internet\n• Auto-sync when connection returns\n• Seamless offline experience',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // Maybe Later button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(
                isOffline ? 'Use Online Only' : 'Maybe Later',
                style: TextStyle(fontSize: 14),
              ),
            ),

            // Connect to Internet button (only for offline)
            if (isOffline) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showConnectivityInstructions();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: Text(
                  'Connect to Internet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            // Buy Now / Upgrade button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPremiumUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upgrade, size: 18),
                  SizedBox(width: 8),
                  Text(
                    isOffline ? 'Get Premium' : 'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAlbumSongs(AlbumModel album) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'albums and songs');
      return;
    }
    // Navigate to album's songs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllSongs(
              artistId: album.artistId,
              artistName: album.artistName,
            ),
      ),
    );
  }

  Widget _buildCustomDrawer() {
    final headerBgColor = ThemeService.getProfileHeaderColor(
      selectedTheme,
      isAutomaticTheme,
    );

  // Facebook Dark Style Colors & Glass Effect Settings
  final Color glassBackground = Colors.black.withOpacity(0.75); 
  final Color dividerColor = Colors.white.withOpacity(0.1);
  final Color fColorWhite = Colors.white.withOpacity(0.9);

  return Drawer(
    backgroundColor: Colors.transparent, // වීදුරු පෙනුම සඳහා මෙය transparent විය යුතුය
    elevation: 0,
    child: Stack(
      children: [
        // 1. Frosted Glass Effect Layer
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur ප්‍රමාණය
            child: Container(
              decoration: BoxDecoration(
                color: glassBackground,
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
                ),
              ),
            ),
          ),
        ),

        // 2. Main Content
        Column(
          children: [
            // --- Profile Header Section ---
            Container(
              height: MediaQuery.of(context).size.height * 0.22,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/drawer.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.srcOver,
                  ),
                ),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    padding: EdgeInsets.only(top: 50, left: 20, right: 15, bottom: 20),
                    color: Colors.black.withOpacity(0.2),
                    child: Row(
                      children: [
                        // Profile Avatar
                        Stack(
  clipBehavior: Clip.none,
  children: [
    // Gradient Border එක (Premium නම් පමණක් පෙන්වයි)
    Container(
      padding: const EdgeInsets.all(3), // Border එකේ මහත තීරණය කරන්නේ මෙතැනින්
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // isPremium true නම් පමණක් gradient එක පෙන්වයි, නැත්නම් සාමාන්‍ය border එකක්
        gradient: isPremium
            ? const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: !isPremium 
            ? Border.all(color: Colors.white.withOpacity(0.2), width: 2) 
            : null,
      ),
      child: Container(
        // පින්තූරය වටේට පොඩි කලු ඉරක් තැබීමෙන් පින්තූරය කැපී පෙනේ
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2), 
        ),
        child: CachedImageWidget(
          imageUrl: profileImageUrl,
          width: 65,
          height: 65,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(32.5),
          errorWidget: CircleAvatar(
            radius: 32.5,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white, size: 35),
          ),
        ),
      ),
    ),
    
    // PRO Badge එක
  //   if (isPremium)
  //     Positioned(
  //       right: -5,
  //       bottom: 0,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [Colors.redAccent, Colors.red.shade900],
  //           ),
  //           borderRadius: BorderRadius.circular(12),
  //           boxShadow: const [
  //             BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
  //           ],
  //         ),
  //         child: const Text(
  //           'PRO',
  //           style: TextStyle(
  //             color: Colors.white, 
  //             fontSize: 9, 
  //             fontWeight: FontWeight.bold, 
  //             letterSpacing: 0.5
  //           ),
  //         ),
  //       ),
  //     ),
  
  
  // 
  ],
),
                        SizedBox(width: 15),
                        // Name and Top Icons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _profileDetails?['fullname'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
                                    },
                                    child: Stack(
                                      children: [
                                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                        if (unreadNotificationCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
                                    },
                                    child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                                  ),
                                ],
                              ),
                              Text(
                                isPremium ? "Premium Member" : "Standard Account",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Menu Items Section ---
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildDrawerItem(Icons.home_outlined, 'Home', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                  }),
                  _buildDrawerItem(
                    Icons.notifications_outlined, 
                    'Notifications', 
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
                      _loadNotificationCount();
                    },
                    badgeCount: unreadNotificationCount,
                  ),
                  _buildDrawerItem(Icons.language_outlined, 'Languages', onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => LanguageScreen()));
                    if (result != null && result != currentLanguage) _loadData();
                  }),
                  _buildDrawerItem(Icons.star_outline, 'Featured Songs', showLock: !isPremium, onTap: isPremium ? () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FeaturedSongs()));
                  } : null),
                  _buildDrawerItem(Icons.bookmark_outline, 'My Set List', showLock: !isPremium, onTap: isPremium ? () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MySetList()));
                  } : null),
                  _buildDrawerItem(Icons.note_alt_outlined, 'Worship Notes', showLock: !isPremium, onTap: isPremium ? () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WorshipNotesScreen()));
                  } : null),
                  _buildDrawerItem(Icons.auto_stories_outlined, 'How to Read Lyrics', showLock: !isPremium, onTap: isPremium ? () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HowToReadLyrics()));
                  } : null),
                  
                  if (!isPremium)
                    _buildDrawerItem(Icons.workspace_premium_outlined, 'Go Premium', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumScreen()));
                    }),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Divider(color: dividerColor, thickness: 0.8),
                  ),

                  _buildDrawerItem(Icons.settings_suggest_outlined, 'App Settings', onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                    if (result != null) { await _loadThemeSettings(); _loadData(); }
                  }),
                  _buildDrawerItem(Icons.gpp_maybe_outlined, 'Privacy Policy', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicy()));
                  }),

                  _buildDrawerItem(Icons.info_outline, 'About this App', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AboutApp()));
                  }),

                  // --- Footer Section ---
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Opacity(
                      opacity: 0.7,
                      child: Column(
                        children: [
                          Text('A Vision by Johnson Shan', style: TextStyle(color: fColorWhite, fontSize: 13, fontWeight: FontWeight.w500)),
                          SizedBox(height: 5),
                          Text(
                            'Designed & Developed by JS Christian Productions',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: fColorWhite, fontSize: 13),
                          ),
                          Text(
                            'www.therockofpraise.org',
                            style: TextStyle(color: Colors.lightBlueAccent, fontSize: 14, decoration: TextDecoration.underline),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '© 2026 The Rock of Praise. All rights reserved.',
                            style: TextStyle(color: fColorWhite.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    Function? onTap,
    bool showLock = false,
    int badgeCount = 0,
  }) {
    Color fColor;

    if (isAutomaticTheme) {
      // Use system theme to determine color
      final systemBrightness =
          WidgetsBinding.instance.window.platformBrightness;
      fColor =
          systemBrightness == Brightness.dark ? Colors.white : Colors.black;
    } else {
      // Use selected theme
      fColor = selectedTheme == 'Light' ? Colors.black : Colors.white;
    }

    return ListTile(
      leading: Icon(icon, color: fColor, size: 24),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : showLock
              ? Icon(Icons.lock, color: fColor, size: 20)
              : null,
      title: Text(
        title,
        style: TextStyle(
          color: fColor,
          fontSize: 22,
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          Navigator.pop(context);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
  return Container(
    width: 120,
    height: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // පින්තූරයට පමණක් BoxDecoration එක එකතු කළා
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedImageWidget(
              imageUrl: artist.image,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 110,
                height: 110,
                color: Colors.grey[800],
                child: const Icon(Icons.person, color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 15),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            artist.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        FutureBuilder<int>(
          future: _getArtistTotalSongCount(artist.id),
          builder: (context, snapshot) {
            final count =
                snapshot.data ??
                artist.totalSongCount ??
                artist.songCount ??
                0;
            return Text(
              '$count Songs',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 15),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildAlbumCard(AlbumModel album) {
  return Container(
    width: 120,
    height: 150,
    // මුළු Card එකටම තිබ්බ decoration එක අයින් කළා
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // පින්තූරයට පමණක් Border එක දැමීම සඳහා මෙතනට Container එකක් එකතු කළා
        Container(
          decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)), // Image එකට පමණක් Border එක
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedImageWidget(
              imageUrl: album.image,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 110,
                height: 110,
                color: Colors.grey[800],
                child: const Icon(Icons.album, color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 15),
        
        // පහළ Text කොටස් වලට Border එක බලපාන්නේ නැත
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            album.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            album.artistName ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
}
