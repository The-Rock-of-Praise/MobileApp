import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_artist_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:lyrics/Screens/music_player.dart';

import '../Service/song_service.dart';

class AllSongs extends StatefulWidget {
  final ArtistModel? artist;
  final int? artistId;
  final String? artistName;

  const AllSongs({super.key, this.artist, this.artistId, this.artistName});

  @override
  State<AllSongs> createState() => _AllSongsState();
}

class _AllSongsState extends State<AllSongs> {
  final OfflineArtistService _artistService = OfflineArtistService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  List<dynamic> songs = [];
  bool isLoading = true;
  bool _isOnline = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _loadArtistSongs();
  }

  @override
  void dispose() {
    _artistService.dispose();
    super.dispose();
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

        // Reload data when coming back online
        if (_isOnline && wasOffline) {
          _refreshSongs();
        }
      }
    });
  }

  Future<void> _loadArtistSongs() async {
    if (widget.artist?.id == null && widget.artistId == null) {
      setState(() {
        errorMessage = 'No artist ID provided';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final artistId = widget.artist?.id ?? widget.artistId!;
      final result = await _artistService.getArtistSongs(artistId);

      print('Songs result: $result');

      if (result['success']) {
        setState(() {
          songs = result['songs'] ?? [];
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load songs';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading songs: $e';
        isLoading = false;
      });
      print('Error loading artist songs: $e');
    }
  }

  Future<void> _refreshSongs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _loadArtistSongs();
  }

  String _getArtistName() {
    if (widget.artist != null) {
      return widget.artist!.name;
    } else if (widget.artistName != null) {
      return widget.artistName!;
    }
    return 'Unknown Artist';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _getArtistName(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshSongs,
          ),
        ],
      ),
      body: MainBAckgound(child: _buildBody()),
    );
  }

  Widget _buildBody() {
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
              'Loading songs...',
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
            const Icon(Icons.error_outline, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshSongs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              'No songs found for ${_getArtistName()}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshSongs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    print('Songs loaded: $songs');
    return RefreshIndicator(
      onRefresh: _refreshSongs,
      color: Colors.white,
      backgroundColor: const Color(0xFF1E3A5F),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SongCard(
                song: songs[index],
                onTap: () => _navigateToMusicPlayer(songs[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String> getLyricscode() async {
    final language = await LanguageService.getLanguage();
    switch (language) {
      case 'Sinhala':
        return 'lyrics_si';
      case 'Tamil':
        return 'lyrics_ta';
      case 'English':
      default:
        return 'lyrics_en';
    }
  }

  void _navigateToMusicPlayer(dynamic songData) async {
    final lang = await getLyricscode();
    print('Selected language code: $songData');

    // Handle different song types
    String? backgroundImage;
    String songName;
    String artistName;
    String? lyrics;
    int songId;
    List<GroupSongArtist>? artists;
    bool isGroupSong = false;

    if (songData is SongModel) {
      backgroundImage =
          songData.image ?? songData.albumImage ?? songData.artistImage;
      songName = songData.songname;
      artistName = songData.artistName ?? _getArtistName();
      songId = songData.id ?? 0;
      switch (lang) {
        case 'lyrics_si':
          lyrics = songData.lyricsSi;
          break;
        case 'lyrics_ta':
          lyrics = songData.lyricsTa;
          break;
        default:
          lyrics = songData.lyricsEn;
      }
    } else if (songData is GroupSongModel) {
      isGroupSong = true;
      backgroundImage = songData.image;
      songName = songData.songName;
      artistName = songData.artists.map((a) => a.name).join(', ');
      artists = songData.artists;
      songId = songData.id;
      switch (lang) {
        case 'lyrics_si':
          lyrics = songData.lyricsSi;
          break;
        case 'lyrics_ta':
          lyrics = songData.lyricsTa;
          break;
        default:
          lyrics = songData.lyricsEn;
      }
    } else if (songData is Map) {
      backgroundImage = songData['image'];
      songName = songData['songname'] ?? 'Unknown Song';
      artistName = songData['artist_name'] ?? _getArtistName();
      songId = songData['id'] ?? 0;
      lyrics = songData[lang];
    } else {
      // Unknown type, show error
      print('Unknown song data type: ${songData.runtimeType}');
      return;
    }

    // Navigate to music player with song data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MusicPlayer(
              backgroundImage: backgroundImage,
              song: songName,
              artist: isGroupSong ? null : artistName,
              artists: isGroupSong ? artists : null,
              lyrics: lyrics,
              id: songId,
            ),
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final dynamic song;
  final VoidCallback? onTap;

  const SongCard({super.key, required this.song, this.onTap});

  String _getSongName() {
    if (song is SongModel) {
      return (song as SongModel).songname;
    } else if (song is GroupSongModel) {
      return (song as GroupSongModel).songName;
    } else if (song is Map) {
      return song['songname'] ?? 'Unknown Song';
    }
    return 'Unknown Song';
  }

  String _getArtistName() {
    if (song is SongModel) {
      return (song as SongModel).artistName ?? 'Unknown Artist';
    } else if (song is GroupSongModel) {
      final artists = (song as GroupSongModel).artists;
      return artists.map((a) => a.name).join(', ').isNotEmpty
          ? artists.map((a) => a.name).join(', ')
          : 'Unknown Artist';
    } else if (song is Map) {
      return song['artist_name'] ?? 'Unknown Artist';
    }
    return 'Unknown Artist';
  }

  String? _getImage() {
    if (song is SongModel) {
      final s = song as SongModel;
      return s.image ?? s.albumImage ?? s.artistImage;
    } else if (song is GroupSongModel) {
      return (song as GroupSongModel).image;
    } else if (song is Map) {
      return song['image'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Album Art
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(),
            ),
          ),

          // Song Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getSongName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getArtistName(),
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Play Button
          // Padding(
          //   padding: const EdgeInsets.only(right: 16),
          //   child: Container(
          //     width: 40,
          //     height: 40,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: Colors.white.withOpacity(0.2),
          //     ),
          //     child: const Icon(
          //       Icons.play_arrow,
          //       color: Colors.white,
          //       size: 20,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = _getImage();

    return CachedImageWidget(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      placeholder: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
          ),
        ),
      ),
      errorWidget: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white, size: 30),
      ),
    );
  }

}

// Alternative card with more song information
class DetailedSongCard extends StatelessWidget {
  final dynamic song;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;

  const DetailedSongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(),
              ),
            ),

            // Song Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song['title'] ?? 'Unknown Song',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song['artist_name'] ?? 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song['album_name'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        song['album_name'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // More button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: onMorePressed,
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = song['image'];

    return CachedImageWidget(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
      placeholder: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
          ),
        ),
      ),
      errorWidget: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white, size: 30),
      ),
    );
  }

}
