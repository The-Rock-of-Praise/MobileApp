import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class CollaborationsPage extends StatefulWidget {
  const CollaborationsPage({super.key});

  @override
  State<CollaborationsPage> createState() => _CollaborationsPageState();
}

class _CollaborationsPageState extends State<CollaborationsPage> {
  final OfflineGroupSongService _groupSongService = OfflineGroupSongService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  List<GroupSongModel> groupSongs = [];
  List<GroupSongModel> filteredGroupSongs = [];
  bool isLoading = true;
  bool _isOnline = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _loadGroupSongs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    _isOnline = await _connectivityManager.isConnected();

    _connectivityManager.connectivityStream.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (mounted) {
        setState(() {});
        if (_isOnline && wasOffline) {
          _refreshGroupSongs();
        }
      }
    });
  }

  Future<void> _loadGroupSongs() async {
    try {
      setState(() => isLoading = true);

      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langcode = LanguageService.getLanguageCode(lang);

      // Load group songs by language
      final result = await _groupSongService.getGroupSongsByLanguage(langcode);

      if (result['success'] == true) {
        final groupSongsData = result['groupSongs'] as List<dynamic>? ?? [];
        final loadedGroupSongs =
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
          filteredGroupSongs = loadedGroupSongs;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to load collaborations',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collaborations: $e')),
        );
      }
    }
  }

  Future<void> _refreshGroupSongs() async {
    await _loadGroupSongs();
  }

  void _filterGroupSongs(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredGroupSongs = groupSongs;
      } else {
        filteredGroupSongs =
            groupSongs.where((groupSong) {
              final songNameMatch =
                  groupSong.songName.toLowerCase().contains(
                    query.toLowerCase(),
                  );
              final artistsMatch = groupSong.artists.any(
                (artist) =>
                    artist.name.toLowerCase().contains(query.toLowerCase()),
              );
              return songNameMatch || artistsMatch;
            }).toList();
      }
    });
  }

  void _navigateToGroupSong(GroupSongModel groupSong) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    if (!isConnected && !isPremium) {
      _showPremiumDialog();
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Premium Feature',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This feature requires an active internet connection or premium subscription.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Collaborations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: MainBAckgound(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterGroupSongs,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search collaborations...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon:
                        searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                searchController.clear();
                                _filterGroupSongs('');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : filteredGroupSongs.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No collaborations found'
                                    : 'No results for "$searchQuery"',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _refreshGroupSongs,
                          color: Colors.white,
                          backgroundColor: Colors.grey[900],
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                            itemCount: filteredGroupSongs.length,
                            itemBuilder: (context, index) {
                              return _buildGroupSongCard(
                                filteredGroupSongs[index],
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSongCard(GroupSongModel groupSong) {
    final artistNames = groupSong.artists.map((a) => a.name).join(', ');

    return GestureDetector(
      onTap: () => _navigateToGroupSong(groupSong),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedImageWidget(
                imageUrl: groupSong.image,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: double.infinity,
                  height: 140,
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),
                errorWidget: Container(
                  width: double.infinity,
                  height: 140,
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Song Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupSong.songName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artistNames.isNotEmpty ? artistNames : 'Unknown Artists',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
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
}
