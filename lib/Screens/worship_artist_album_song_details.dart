import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_worship_entity_service.dart';
import 'package:lyrics/Service/worship_entity_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Screens/DrawerScreens/premium_screen.dart';

class WorshipArtistAlbumSongDetails extends StatefulWidget {
  final int worshipTeamId;
  final String artistName;
  final String? artistImage;

  const WorshipArtistAlbumSongDetails({
    super.key,
    required this.worshipTeamId,
    required this.artistName,
    this.artistImage,
  });

  @override
  State<WorshipArtistAlbumSongDetails> createState() => _WorshipArtistAlbumSongDetailsState();
}

class _WorshipArtistAlbumSongDetailsState extends State<WorshipArtistAlbumSongDetails> {
  final OfflineWorshipEntityService _worshipService = OfflineWorshipEntityService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  WorshipArtistModel? artist;
  List<WorshipAlbumModel> albums = [];
  List<WorshipSongModel> songs = [];
  WorshipAlbumModel? selectedAlbum;

  bool isLoadingArtist = true;
  bool isLoadingAlbums = true;
  bool isLoadingSongs = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
    _loadArtistAlbums();
    _loadArtistSongs();
  }

  @override
  void dispose() {
    _worshipService.dispose();
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    try {
      final result = await _worshipService.getWorshipArtistById(widget.worshipTeamId);
      if (result['success']) {
        setState(() {
          artist = result['artist'];
          isLoadingArtist = false;
        });
      } else {
        setState(() {
          isLoadingArtist = false;
          errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        isLoadingArtist = false;
        errorMessage = 'Error loading worship team: ${e.toString()}';
      });
    }
  }

  Future<void> _loadArtistAlbums() async {
    try {
      final result = await _worshipService.getWorshipArtistAlbums(widget.worshipTeamId);
      if (result['success']) {
        final List<WorshipAlbumModel> loadedAlbums = List<WorshipAlbumModel>.from(result['albums']);
        setState(() {
          albums = loadedAlbums;
          isLoadingAlbums = false;
        });
      } else {
        setState(() {
          isLoadingAlbums = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingAlbums = false;
      });
      print('Error loading albums: $e');
    }
  }

  Future<void> _loadArtistSongs() async {
    try {
      final result = await _worshipService.getWorshipArtistSongs(widget.worshipTeamId);
      if (result['success']) {
        final List<WorshipSongModel> loadedSongs = List<WorshipSongModel>.from(result['songs']);
        setState(() {
          songs = loadedSongs;
          isLoadingSongs = false;
        });

        // If only one song, navigate directly to MusicPlayer
        if (loadedSongs.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigateToSong(loadedSongs[0]);
            }
          });
        }
      } else {
        setState(() {
          isLoadingSongs = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingSongs = false;
      });
      print('Error loading songs: $e');
    }
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
                        const Text(
                          'To access song lyrics while offline, please upgrade to the Rock of Praise Pro.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect to the internet and upgrade to Pro for full offline access.',
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
                  'Pro Version Includes:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPremiumFeatureItem('Full offline access to all lyrics', Icons.menu_book),
                _buildPremiumFeatureItem('Featured Songs collection', Icons.auto_awesome),
                _buildPremiumFeatureItem('My Set List to save your favorite songs', Icons.library_music),
                _buildPremiumFeatureItem('Worship Notes for your personal reflections', Icons.edit_note),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(isOffline ? 'Use Online Only' : 'Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumFeatureItem(String feature, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
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

  Future<void> _loadAlbumSongs(int albumId) async {
    setState(() {
      isLoadingSongs = true;
      selectedAlbum = albums.firstWhere((album) => album.id == albumId);
    });

    try {
      final result = await _worshipService.getWorshipAlbumSongs(albumId);
      if (result['success']) {
        final List<WorshipSongModel> albumSongs =
            (result['songs'] as List<dynamic>)
                .map(
                  (song) => song is WorshipSongModel ? song : WorshipSongModel.fromJson(song),
                )
                .toList();

        setState(() {
          songs = albumSongs;
          isLoadingSongs = false;
        });
      } else {
        setState(() {
          isLoadingSongs = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load album songs')));
      }
    } catch (e) {
      setState(() {
        isLoadingSongs = false;
      });
      print('Error loading album songs: $e');
    }
  }

  void _resetToAllSongs() async {
    setState(() {
      selectedAlbum = null;
    });
    await _loadArtistSongs();
  }

  void _navigateToSong(WorshipSongModel song) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true, feature: 'song lyrics');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayer(
          backgroundImage: song.image ?? song.albumImage ?? '',
          song: song.songname,
          artist: song.artistName ?? widget.artistName,
          id: song.id!,
          lyrics: song.lyricsEn ?? song.lyricsSi ?? song.lyricsTa,
          isWorshipTeam: true,
        ),
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          CachedImageWidget(
            imageUrl: artist?.image ?? widget.artistImage,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(40),
            errorWidget: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.person, color: Colors.white54, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artistName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (!isLoadingArtist && artist != null) ...[
                  Text(
                    '${albums.length} Albums • ${artist!.songCount ?? 0} Songs',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (artist!.bio != null && artist!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      artist!.bio!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Albums',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (selectedAlbum != null)
                TextButton(
                  onPressed: _resetToAllSongs,
                  child: const Text(
                    'Show All Songs',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 160,
          child: isLoadingAlbums
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : albums.isEmpty
                  ? const Center(child: Text('No albums found', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        final isSelected = selectedAlbum?.id == album.id;
                        return Padding(
                          padding: EdgeInsets.only(right: index < albums.length - 1 ? 15 : 0),
                          child: GestureDetector(
                            onTap: () => _loadAlbumSongs(album.id!),
                            child: _buildAlbumCard(album, isSelected),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(WorshipAlbumModel album, bool isSelected) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        children: [
          CachedImageWidget(
            imageUrl: album.image,
            width: 110,
            height: 110,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            errorWidget: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.album, color: Colors.white54, size: 40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${album.songCount ?? 0} Songs',
            style: TextStyle(
              color: isSelected ? Colors.blue[300] : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            selectedAlbum != null ? '${selectedAlbum!.name} Songs' : 'All Songs',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        isLoadingSongs
            ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
            : songs.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No songs found for this artist', style: TextStyle(color: Colors.white70))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: songs.length,
                    itemBuilder: (context, index) => _buildSongCard(songs[index], index + 1),
                  ),
      ],
    );
  }

  Widget _buildSongCard(WorshipSongModel song, int trackNumber) {
    return ListTile(
      contentPadding: const EdgeInsets.all(8),
      leading: SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedImageWidget(
            imageUrl: song.image ?? song.albumImage,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(trackNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            errorWidget: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(trackNumber.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ),
      title: Text(song.songname, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song.albumName ?? 'Unknown Album', style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (song.duration != null) Text(song.formattedDuration, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
      onTap: () => _navigateToSong(song),
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
                    const Text('Worship Team Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArtistHeader(),
                      const SizedBox(height: 20),
                      _buildAlbumsSection(),
                      const SizedBox(height: 30),
                      _buildSongsSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
