import 'package:flutter/material.dart';
import 'package:lyrics/Models/artist_model.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_worship_entity_service.dart';
import 'package:lyrics/Screens/DrawerScreens/premium_screen.dart';
import 'package:lyrics/Screens/worship_artist_album_song_details.dart';
import 'package:lyrics/Service/worship_entity_service.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class WorshipArtistPage extends StatefulWidget {
  const WorshipArtistPage({super.key});

  @override
  State<WorshipArtistPage> createState() => _WorshipArtistPageState();
}

class _WorshipArtistPageState extends State<WorshipArtistPage> {
  final OfflineWorshipEntityService _artistService = OfflineWorshipEntityService();
  final TextEditingController _searchController = TextEditingController();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  List<WorshipArtistModel> allArtists = [];
  List<WorshipArtistModel> filteredArtists = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentLanguage;
  String? languageDisplayName;

  @override
  void initState() {
    super.initState();
    _loadAllArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _artistService.dispose();
    super.dispose();
  }

  void _showPremiumDialog({
    bool isOffline = false,
    String feature = 'this content',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOffline ? 'Offline Access Restricted' : 'Premium Required',
                  style: const TextStyle(
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
                Container(
                  padding: const EdgeInsets.all(16),
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
                        const Row(
                          children: [
                            Icon(Icons.wifi_off, color: Colors.orange, size: 20),
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
                        const SizedBox(height: 12),
                        Text(
                          'To access $feature while offline, you need a Premium subscription.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect to the internet and upgrade to Premium for full offline access.',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ] else ...[
                        Text(
                          'Access to $feature requires a Premium subscription.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Premium Features Include:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...premiumFeatures.asMap().entries.map(
                  (entry) => _buildPremiumFeatureItem(entry.value, isOffline, entry.key),
                ),
                const SizedBox(height: 16),
                if (isOffline) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.offline_bolt, color: Colors.blue, size: 16),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(
                isOffline ? 'Use Online Only' : 'Maybe Later',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (isOffline) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showConnectivityInstructions();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text(
                  'Connect to Internet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPremiumUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upgrade, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isOffline ? 'Get Premium' : 'Buy Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  final List<String> premiumFeatures = [
    'Unlimited offline access',
    'Download songs & albums',
    'No advertisements',
    'High quality audio',
    'Exclusive premium content',
    'Priority customer support',
  ];

  final List<IconData> premiumFeatureIcons = [
    Icons.offline_pin,
    Icons.download,
    Icons.block,
    Icons.high_quality,
    Icons.star,
    Icons.support_agent,
  ];

  Widget _buildPremiumFeatureItem(String feature, bool showIcons, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (showIcons) ...[
            Icon(premiumFeatureIcons[index], color: Colors.amber, size: 20),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPremiumUpgrade() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
  }

  void _showConnectivityInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text('Connect to Internet', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('To upgrade to Premium and enable offline features:', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 16),
              _buildConnectivityStep('1', 'Connect to Wi-Fi or mobile data'),
              _buildConnectivityStep('2', 'Tap "Get Premium" to upgrade'),
              _buildConnectivityStep('3', 'Enjoy unlimited offline access'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
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
              child: const Text('Got it', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectivityStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _loadAllArtists() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);

      final result = await _artistService.getWorshipArtistsByLanguage(langcode);

      if (result['success']) {
        List<WorshipArtistModel> artists = result['artists'] ?? [];

        // If no artists found for the current language, load ALL artists as fallback
        if (artists.isEmpty) {
          final allResult = await _artistService.getWorshipArtists();
          if (allResult['success']) {
            artists = allResult['artists'] ?? [];
          }
        }

        setState(() {
          allArtists = artists;
          filteredArtists = List.from(allArtists);
          languageDisplayName = lang;
          isLoading = false;
        });
      } else {
        // On failure, also try to load all artists
        final allResult = await _artistService.getWorshipArtists();
        if (allResult['success']) {
          setState(() {
            allArtists = allResult['artists'] ?? [];
            filteredArtists = List.from(allArtists);
            languageDisplayName = 'All';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'Failed to load artists';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading artists: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _filterArtists(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredArtists = List.from(allArtists);
      } else {
        filteredArtists = allArtists
            .where((artist) => artist.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToArtistSongs(WorshipArtistModel artist) async {
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
        builder: (context) => WorshipArtistAlbumSongDetails(
          artistId: artist.id!,
          artistName: artist.name,
          artistImage: artist.image,
        ),
      ),
    );
  }

  Widget _buildArtistCard(WorshipArtistModel artist) {
    return GestureDetector(
      onTap: () => _navigateToArtistSongs(artist),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                child: CachedImageWidget(
                  imageUrl: artist.image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.person, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      artist.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${artist.albumCount ?? 0} Albums',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Worship Teams',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (languageDisplayName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          languageDisplayName!,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFF363636), borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search worship teams...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onChanged: _filterArtists,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        '${filteredArtists.length} Artists',
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
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
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            SizedBox(height: 16),
            Text('Loading artists...', style: TextStyle(color: Colors.white70, fontSize: 16)),
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
            Text(errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllArtists,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredArtists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty ? Icons.search_off : Icons.person_outline,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty ? 'No artists found for "${_searchController.text}"' : 'No artists available',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: filteredArtists.length,
      itemBuilder: (context, index) => _buildArtistCard(filteredArtists[index]),
    );
  }
}
