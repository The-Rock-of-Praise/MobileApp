import 'package:flutter/material.dart';
import 'package:lyrics/Models/artist_model.dart';
import 'package:lyrics/Models/song_model.dart';
import 'package:lyrics/OfflineService/offline_album_service.dart';
import 'package:lyrics/OfflineService/offline_artist_service.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class ArtistAlbumSongDetails extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String? artistImage;

  const ArtistAlbumSongDetails({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImage,
  });

  @override
  State<ArtistAlbumSongDetails> createState() => _ArtistAlbumSongDetailsState();
}

class _ArtistAlbumSongDetailsState extends State<ArtistAlbumSongDetails> {
  final OfflineAlbumService _albumService = OfflineAlbumService();
  final OfflineArtistService _artistService = OfflineArtistService();
  final ArtistService _onlineArtistService = ArtistService();
  final SongService _songService = SongService();

  ArtistModel? artist;
  List<AlbumModel> albums = [];
  List<SongModel> songs = [];
  AlbumModel? selectedAlbum;

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
    _albumService.dispose();
    _artistService.dispose();
    _onlineArtistService.dispose();
    _songService.dispose();
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    try {
      final result = await _artistService.getArtistById(widget.artistId);
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
      final result = await _artistService.getArtistAlbums(widget.artistId);
      if (result['success']) {
        final List<AlbumModel> loadedAlbums =
            (result['albums'] as List<dynamic>)
                .map(
                  (album) =>
                      album is AlbumModel ? album : AlbumModel.fromJson(album),
                )
                .toList();

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
      final result = await _artistService.getArtistSongs(widget.artistId);
      if (result['success']) {
        final List<SongModel> loadedSongs =
            (result['songs'] as List<dynamic>)
                .map(
                  (song) => song is SongModel ? song : SongModel.fromJson(song),
                )
                .toList();

        setState(() {
          songs = loadedSongs;
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

  Future<void> _loadAlbumSongs(int albumId) async {
    setState(() {
      isLoadingSongs = true;
      selectedAlbum = albums.firstWhere((album) => album.id == albumId);
    });

    try {
      final result = await _albumService.getAlbumSongs(albumId);
      if (result['success']) {
        final List<SongModel> albumSongs =
            (result['songs'] as List<dynamic>)
                .map(
                  (song) => song is SongModel ? song : SongModel.fromJson(song),
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

  void _navigateToSong(SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MusicPlayer(
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
          // Artist Image
          CachedImageWidget(
            imageUrl: artist?.image ?? widget.artistImage,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(40),
            placeholder: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(40),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.person, color: Colors.white54, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          // Artist Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
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
              Text(
                'Albums',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          child:
              isLoadingAlbums
                  ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      final isSelected = selectedAlbum?.id == album.id;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < albums.length - 1 ? 15 : 0,
                        ),
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

  Widget _buildAlbumCard(AlbumModel album, bool isSelected) {
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
            placeholder: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              ),
            ),
            errorWidget: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
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
            selectedAlbum != null
                ? '${selectedAlbum!.name} Songs'
                : 'All Songs',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        isLoadingSongs
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
            : songs.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  selectedAlbum != null
                      ? 'No songs found in this album'
                      : 'No songs found for this artist',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return _buildSongCard(songs[index], index + 1);
              },
            ),
      ],
    );
  }

  Widget _buildSongCard(SongModel song, int trackNumber) {
    return ListTile(
      contentPadding: EdgeInsets.all(8),
      leading: SizedBox(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              (song.image ?? song.albumImage) != null
                  ? CachedImageWidget(
                    imageUrl: song.image ?? song.albumImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          trackNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trackNumber.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        trackNumber.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
        ),
      ),
      title: Text(
        song.songname,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.albumName ?? selectedAlbum?.name ?? 'Unknown Album',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (song.duration != null)
            Text(
              song.formattedDuration,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
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
              // Header with back button
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
                      'Artist Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artist Header
                      _buildArtistHeader(),

                      const SizedBox(height: 20),

                      // Albums Section
                      _buildAlbumsSection(),

                      const SizedBox(height: 30),

                      // Songs Section
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
