import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_worship_entity_service.dart';
import 'package:lyrics/Service/worship_entity_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class WorshipArtistAlbumSongDetails extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String? artistImage;

  const WorshipArtistAlbumSongDetails({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImage,
  });

  @override
  State<WorshipArtistAlbumSongDetails> createState() => _WorshipArtistAlbumSongDetailsState();
}

class _WorshipArtistAlbumSongDetailsState extends State<WorshipArtistAlbumSongDetails> {
  final OfflineWorshipEntityService _worshipService = OfflineWorshipEntityService();

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
      final result = await _worshipService.getWorshipArtistById(widget.artistId);
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
        errorMessage = 'Error loading artist: ${e.toString()}';
      });
    }
  }

  Future<void> _loadArtistAlbums() async {
    try {
      final result = await _worshipService.getWorshipArtistAlbums(widget.artistId);
      if (result['success']) {
        setState(() {
          albums = List<WorshipAlbumModel>.from(result['albums']);
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
      final result = await _worshipService.getWorshipArtistSongs(widget.artistId);
      if (result['success']) {
        setState(() {
          songs = List<WorshipSongModel>.from(result['songs']);
          isLoadingSongs = false;
        });
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

  void _navigateToSong(WorshipSongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayer(
          backgroundImage: song.image ?? song.albumImage ?? '',
          song: song.songname,
          artist: song.artistName ?? widget.artistName,
          id: song.id!,
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
                    '${albums.length} Albums • ${songs.length} Songs',
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Albums',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                        return Padding(
                          padding: EdgeInsets.only(right: index < albums.length - 1 ? 15 : 0),
                          child: _buildAlbumCard(album),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(WorshipAlbumModel album) {
    return Container(
      width: 110,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
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
          Text(album.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          Text('${album.songCount ?? 0} Songs', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'All Songs',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
