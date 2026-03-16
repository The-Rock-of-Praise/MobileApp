import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_song_service.dart';
import 'package:lyrics/OfflineService/offline_favorites_service.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Models/song_model.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class FeaturedSongs extends StatefulWidget {
  const FeaturedSongs({super.key});

  @override
  State<FeaturedSongs> createState() => _FeaturedSongsState();
}

class _FeaturedSongsState extends State<FeaturedSongs> {
  // Replace online services with offline services
  final OfflineSongService _songService = OfflineSongService();
  final OfflineFavoritesService _favoritesService = OfflineFavoritesService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  List<SongModel> featuredSongs = [];
  FavoriteStats? stats;
  bool isLoading = true;
  bool isLoadingMore = false;
  String? currentUserId;

  // Connectivity state
  bool _isOnline = false;
  String? _dataSource;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _initializeFavorites();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    _songService.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    // Check initial connectivity
    _isOnline = await _connectivityManager.isConnected();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityManager.connectivityStream.listen((
      result,
    ) {
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

        // Sync when coming back online
        if (_isOnline && wasOffline) {
          _syncDataWhenOnline();
        }
      }
    });
  }

  Future<void> _syncDataWhenOnline() async {
    try {
      // Sync favorites
      await _favoritesService.syncPendingChanges();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Data synchronized'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && _hasMore) {
        _loadMoreFavorites();
      }
    }
  }

  Future<void> _initializeFavorites() async {
    try {
      currentUserId = await UserService.getUserID();
      if (currentUserId != null) {
        await _loadFavorites();
        await _loadStats();
      }
    } catch (e) {
      print('Error initializing favorites: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites({bool isRefresh = false}) async {
    if (currentUserId == null) return;

    if (isRefresh) {
      setState(() {
        _currentOffset = 0;
        _hasMore = true;
        featuredSongs.clear();
      });
    }

    setState(() {
      if (isRefresh) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      // Use offline favorites service instead of online service
      final result = await _favoritesService.getFavorites(
        currentUserId!,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (result['success'] == true) {
        final favoritesList = result['favorites'] as List;
        final List<SongModel> newFavorites = [];

        // Convert favorite data to SongModel
        for (final favoriteData in favoritesList) {
          print('song models, $favoriteData');
          try {
            final songModel = SongModel(
              artistId: favoriteData['song_id'],
              id: favoriteData['id'],
              songname: favoriteData['song_name'],
              artistName: favoriteData['artist_name'],
              image: favoriteData['song_image'],
              // Add other fields as needed
            );
            newFavorites.add(songModel);
          } catch (e) {
            print('Error converting favorite to song model: $e');
          }
        }

        setState(() {
          if (isRefresh) {
            featuredSongs = newFavorites;
          } else {
            featuredSongs.addAll(newFavorites);
          }

          _currentOffset += _pageSize;
          _hasMore = newFavorites.length == _pageSize;
          _dataSource = result['source'];
        });

        _showDataSourceIndicator(_dataSource ?? 'unknown');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load favorites');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading favorites: $e');
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreFavorites() async {
    await _loadFavorites();
  }

  Future<void> _loadStats() async {
    if (currentUserId == null) return;

    try {
      // Use offline favorites service for stats
      final result = await _favoritesService.getFavoriteStats(currentUserId!);
      if (result['success'] == true) {
        setState(() {
          // Convert stats data
          final statsData = result['stats'];
          stats = FavoriteStats(
            totalFavorites: statsData['total_favorites'] ?? 0,
            favoriteArtists: statsData['favorite_artists'] ?? 0,
            lastAdded:
                statsData['last_added'] != null
                    ? DateTime.parse(statsData['last_added'])
                    : null,
            topArtists:
                (statsData['topArtists'] as List? ?? [])
                    .map(
                      (artist) => TopArtist(
                        artistName: artist['artist_name'] ?? '',
                        count: artist['count'] ?? 0,
                      ),
                    )
                    .toList(),
          );
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _removeFavorite(SongModel song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Remove Favorite',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Remove "${song.songname}" from favorites?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm == true && currentUserId != null) {
      try {
        // Use offline favorites service
        final result = await _favoritesService.removeFromFavorites(
          userId: currentUserId!,
          songId: song.id!,
        );

        if (result['success'] == true) {
          setState(() {
            featuredSongs.removeWhere((fav) => fav.id == song.id);
          });

          String message = 'Removed from favorites';
          if (result['source'] == 'local' || result['pending_sync'] == true) {
            message += ' (will sync when online)';
          }
          _showSuccessSnackBar(message);

          await _loadStats(); // Refresh stats
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to remove favorite');
        }
      } catch (e) {
        _showErrorSnackBar('Error removing favorite: $e');
      }
    }
  }

  void _navigateToMusicPlayer(SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MusicPlayer(
              id: song.id ?? 0,
              backgroundImage: song.image ?? 'assets/Rectangle 29.png',
              song: song.songname ?? '',
              artist: song.artistName ?? '',
              lyrics: song.lyricsEn,
              language: 'en',
            ),
      ),
    );
  }

  void _showDataSourceIndicator(String source) {
    if (!mounted) return;

    String message;
    Color color;

    switch (source) {
      case 'online':
        message = '🌐 Live data';
        color = Colors.green;
        break;
      case 'cache':
        message = '📱 Cached data';
        color = Colors.orange;
        break;
      case 'local':
        message = '💾 Local data';
        color = Colors.blue;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
        backgroundColor: color,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildStatsCard() {
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Your Music Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Add connectivity indicator
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Favorite Songs',
                  stats!.totalFavorites.toString(),
                  Icons.music_note,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Artists',
                  stats!.favoriteArtists.toString(),
                  Icons.person,
                ),
              ),
            ],
          ),
          if (stats!.topArtists.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Top Artists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  stats!.topArtists.take(3).map((artist) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${artist.artistName} (${artist.count})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSongCard(SongModel song) {
    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToMusicPlayer(song),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Song image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      song.image != null && song.image!.isNotEmpty
                          ? (song.image!.startsWith('http')
                              ? Image.network(
                                song.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultImage();
                                },
                              )
                              : Image.asset(
                                song.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultImage();
                                },
                              ))
                          : _buildDefaultImage(),
                ),
              ),
              const SizedBox(width: 16),
              // Song details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.songname ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artistName ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (song.duration != null) ...[
                          Icon(
                            Icons.access_time,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(song.duration!),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.favorite, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Added ${_getRelativeTime((song.createdAt != null ? song.createdAt!.toIso8601String() : DateTime.now().toIso8601String()))}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Offline indicator
                        if (!_isOnline)
                          Icon(Icons.cloud_off, color: Colors.orange, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                color: const Color(0xFF3A3A3A),
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeFavorite(song);
                  } else if (value == 'play') {
                    _navigateToMusicPlayer(song);
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'play',
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Play', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove from Favorites',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[700],
      child: const Icon(Icons.music_note, color: Colors.white, size: 30),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getRelativeTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF173857),
        title: Row(
          children: [
            const Text('Featured Songs', style: TextStyle(color: Colors.white)),
            const Spacer(),
            // Connection status indicator
            Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: _isOnline ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFavorites(isRefresh: true),
          ),
        ],
      ),
      body: MainBAckgound(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : currentUserId == null
                ? _buildLoginPrompt()
                : featuredSongs.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: () => _loadFavorites(isRefresh: true),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Stats card
                      if (stats != null && stats!.totalFavorites > 0)
                        SliverToBoxAdapter(child: _buildStatsCard()),

                      // Songs list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < featuredSongs.length) {
                              return _buildSongCard(featuredSongs[index]);
                            } else if (isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            } else if (!_hasMore && featuredSongs.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const Center(
                                  child: Text(
                                    'No more songs to load',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          childCount:
                              featuredSongs.length +
                              (isLoadingMore ? 1 : 0) +
                              (!_hasMore && featuredSongs.isNotEmpty ? 1 : 0),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Please Log In',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in to view your favorite songs',
            style: TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to login screen
              // Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: const Text('Log In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOnline ? Icons.favorite_border : Icons.cloud_off,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _isOnline ? 'No Favorite Songs Yet' : 'Offline Mode',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOnline
                ? 'Start adding songs to your favorites\nby tapping the heart icon while listening'
                : 'Your favorites will appear when you\'re back online\nor when cached data is available',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back or to song browser
              Navigator.pop(context);
            },
            icon: Icon(_isOnline ? Icons.explore : Icons.refresh),
            label: Text(_isOnline ? 'Explore Songs' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Add these models if they don't exist in your project
class FavoriteStats {
  final int totalFavorites;
  final int favoriteArtists;
  final DateTime? lastAdded;
  final List<TopArtist> topArtists;

  FavoriteStats({
    required this.totalFavorites,
    required this.favoriteArtists,
    this.lastAdded,
    required this.topArtists,
  });
}

class TopArtist {
  final String artistName;
  final int count;

  TopArtist({required this.artistName, required this.count});
}
