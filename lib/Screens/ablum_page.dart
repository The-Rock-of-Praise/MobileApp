import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_album_service.dart';
import 'package:lyrics/Screens/DrawerScreens/premium_screen.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/Screens/all_songs.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class AblumPage extends StatefulWidget {
  const AblumPage({super.key});

  @override
  State<AblumPage> createState() => _AblumPageState();
}

class _AblumPageState extends State<AblumPage> {
  final OfflineAlbumService _albumService = OfflineAlbumService();
  final TextEditingController _searchController = TextEditingController();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  List<AlbumModel> allAlbums = [];
  List<AlbumModel> filteredAlbums = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentLanguage;
  String? languageDisplayName;

  @override
  void initState() {
    super.initState();
    _loadAllAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _albumService.dispose();
    super.dispose();
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
                          'To access song lyrics while offline, please upgrade to the Rock of Praise Pro.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connect to the internet and upgrade to Pro for full offline access.',
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
                  'Pro Version Includes:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),

                ...premiumFeatures.asMap().entries.map(
                  (entry) => _buildPremiumFeatureItem(entry.value, isOffline, entry.key),
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

  // Premium features list
  final List<String> premiumFeatures = [
    'Full offline access to all lyrics',
    'Featured Songs collection',
    'My Set List to save your favorite songs',
    'Worship Notes for your personal reflections',
    'How to Read Lyrics guide',
    'No advertisements',
    'Auto-sync when connection returns',
    'Priority support for Pro users'
  ];

  // Icons for each premium feature (shown only when offline)
  final List<IconData> premiumFeatureIcons = [
    Icons.menu_book,           // 📖 Full offline access
    Icons.auto_awesome,        // 💫 Featured Songs
    Icons.library_music,       // 🎵 My Set List
    Icons.edit_note,           // 📝 Worship Notes
    Icons.local_library,       // 📚 How to Read Lyrics
    Icons.block,               // 🚫 No advertisements
    Icons.sync,                // 🔄 Auto-sync
    Icons.chat_bubble,         // 💬 Priority support
  ];

  Widget _buildPremiumFeatureItem(String feature, bool showIcons, int index) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (showIcons) ...[
            Icon(
              premiumFeatureIcons[index],
              color: Colors.amber,
              size: 20,
            ),
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
  void _navigateToPremiumUpgrade() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumScreen()),
    );
  }

  // Show connectivity instructions
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

  Future<void> _loadAllAlbums() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);

      // Load albums by language
      final result = await _albumService.getAlbumsByLanguage(langcode);

      if (result['success']) {
        final List<AlbumModel> loadedAlbums =
            (result['albums'] as List<dynamic>)
                .map(
                  (album) =>
                      album is AlbumModel ? album : AlbumModel.fromJson(album),
                )
                .toList();

        setState(() {
          allAlbums = loadedAlbums;
          filteredAlbums = List.from(allAlbums);
          currentLanguage = result['language'];
          languageDisplayName = result['languageDisplayName'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load albums';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading albums: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _filterAlbums(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredAlbums = List.from(allAlbums);
      } else {
        filteredAlbums =
            allAlbums
                .where(
                  (album) =>
                      album.name.toLowerCase().contains(query.toLowerCase()) ||
                      (album.artistName?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
      }
    });
  }

  void _navigateToAlbumSongs(AlbumModel album) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    // Check for offline + non-premium
    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'artist content');
      return;
    }
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

  Widget _buildAlbumCard(AlbumModel album) {
    return GestureDetector(
      onTap: () => _navigateToAlbumSongs(album),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Album Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                child: CachedImageWidget(
                  imageUrl: album.image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  placeholder: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.album,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            // Album Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      album.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.artistName ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBAckgound(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Albums',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (languageDisplayName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          languageDisplayName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

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
                      hintText: 'Search albums or artists...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: _filterAlbums,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Albums Count
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        '${filteredAlbums.length} Albums',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 15),

              // Content Area
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading albums...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllAlbums,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredAlbums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.album_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No albums found for "${_searchController.text}"'
                  : 'No albums available',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterAlbums('');
                },
                child: const Text(
                  'Clear search',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllAlbums,
      color: Colors.white,
      backgroundColor: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Adjust this to make cards taller/shorter
          ),
          itemCount: filteredAlbums.length,
          itemBuilder: (context, index) {
            return _buildAlbumCard(filteredAlbums[index]);
          },
        ),
      ),
    );
  }
}
