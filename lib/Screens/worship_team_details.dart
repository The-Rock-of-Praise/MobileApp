import 'package:flutter/material.dart';
import 'package:lyrics/Models/worship_team_model.dart';
import 'package:lyrics/Service/artist_service.dart';
import 'package:lyrics/Service/song_service.dart';
import 'package:lyrics/OfflineService/offline_album_service.dart';
import 'package:lyrics/OfflineService/offline_artist_service.dart';
import 'package:lyrics/Service/album_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';

class WorshipTeamDetails extends StatefulWidget {
  final int? worshipTeamId;
  final String worshipTeamName;
  final String? worshipTeamImage;
  final WorshipTeamModel? selectedTeam;

  const WorshipTeamDetails({
    super.key,
    required this.worshipTeamId,
    required this.worshipTeamName,
    this.worshipTeamImage,
    this.selectedTeam,
  });

  @override
  State<WorshipTeamDetails> createState() => _WorshipTeamDetailsState();
}

class _WorshipTeamDetailsState extends State<WorshipTeamDetails> {
  final OfflineAlbumService _albumService = OfflineAlbumService();
  final OfflineArtistService _artistService = OfflineArtistService();

  ArtistModel? artist;
  List<AlbumModel> albums = [];
  List<SongModel> songs = [];
  AlbumModel? selectedAlbum;
  WorshipTeamModel? displayedTeam;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    displayedTeam = widget.selectedTeam;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    // Artist details, Albums සහ Songs ඔක්කොම එකවර load කිරීම
    final artistResult = await _artistService.getArtistById(widget.worshipTeamId ?? 0);
    final albumsResult = await _artistService.getArtistAlbums(widget.worshipTeamId ?? 0);
    final songsResult = await _artistService.getArtistSongs(widget.worshipTeamId ?? 0);

    setState(() {
      if (artistResult['success']) artist = artistResult['artist'];
      
      if (albumsResult['success']) {
        albums = (albumsResult['albums'] as List).map((e) => e as AlbumModel).toList();
      }
      
      if (songsResult['success']) {
        final loadedSongs = (songsResult['songs'] as List).map((e) => e as SongModel).toList();
        songs = loadedSongs;

        // If only one song, navigate directly to MusicPlayer
        if (loadedSongs.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MusicPlayer(
                    backgroundImage: loadedSongs[0].image ?? loadedSongs[0].albumImage ?? '',
                    song: loadedSongs[0].songname,
                    artist: loadedSongs[0].artistName ?? widget.worshipTeamName,
                    id: loadedSongs[0].id!,
                  ),
                ),
              );
            }
          });
        }
      }
      isLoading = false;
    });
  }

  Future<void> _loadAlbumSongs(AlbumModel album) async {
    setState(() {
      isLoading = true;
      selectedAlbum = album;
    });
    final result = await _albumService.getAlbumSongs(album.id!);
    setState(() {
      if (result['success']) {
        songs = (result['songs'] as List).map((e) => e as SongModel).toList();
      }
      isLoading = false;
    });
  }

  // Navigate to MusicPlayer for the first song in the album
  Future<void> _openAlbumInPlayer(AlbumModel album) async {
    final result = await _albumService.getAlbumSongs(album.id!);
    if (result['success']) {
      final List songsList = result['songs'] as List; 
      if (songsList.isNotEmpty) {
        final SongModel firstSong = songsList.first as SongModel;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayer(
              backgroundImage: firstSong.image ?? firstSong.albumImage ?? album.image ?? '',
              song: firstSong.songname,
              artist: firstSong.artistName ?? widget.worshipTeamName,
              id: firstSong.id!,
            ),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No songs available for this album')),
    );
  }

  // Navigate to MusicPlayer from team card
  void _openTeamInPlayer(WorshipTeamModel team) {
    // The team itself is the playable item
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayer(
          backgroundImage: team.image ?? '',
          song: team.songname,
          artist: team.artistName ?? widget.worshipTeamName,
          id: team.id,
          isWorshipTeam: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBAckgound(
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // Top header with back button and title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Worship Team Details',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                            // Artist / Team header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  CachedImageWidget(
                                    imageUrl: artist?.image ?? widget.worshipTeamImage,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(widget.worshipTeamName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('${albums.length} Albums • ${songs.length} Songs', style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Albums
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Albums', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (selectedAlbum != null)
                                    TextButton(onPressed: _loadAllData, child: const Text('Show All Songs', style: TextStyle(color: Colors.amber))),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            SizedBox(
                              height: 160,
                              child: albums.isEmpty
                                  ? const Center(child: Text('No albums found', style: TextStyle(color: Colors.white70)))
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: albums.length,
                                      itemBuilder: (context, index) {
                                        final album = albums[index];
                                        return Padding(
                                          padding: EdgeInsets.only(right: index < albums.length - 1 ? 15 : 0),
                                          child: GestureDetector(
                                            onTap: () => _openAlbumInPlayer(album),
                                            child: _buildAlbumCard(album),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            const SizedBox(height: 30),

                            // Songs
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(selectedAlbum != null ? '${selectedAlbum!.name} Songs' : 'Top Songs', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),

                            const SizedBox(height: 10),

                            // Display selected team card if available
                            if (displayedTeam != null) ...[
                              SizedBox(
                                height: 130,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  children: [_buildTeamCard(displayedTeam!)],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            songs.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text('No songs found', style: const TextStyle(color: Colors.white70)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: songs.length,
                                    itemBuilder: (context, index) => _buildSongTile(songs[index]),
                                  ),

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

  // Album Card Widget
  Widget _buildAlbumCard(AlbumModel album) {
    bool isSelected = selectedAlbum?.id == album.id;
    return GestureDetector(
      onTap: () => _loadAlbumSongs(album),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedImageWidget(
                  imageUrl: album.image,
                  height: 130,
                  width: 130,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(album.name, 
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white, 
                fontWeight: FontWeight.w500,
                fontSize: 13
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // Team Card Widget for Top Songs display
  Widget _buildTeamCard(WorshipTeamModel team) {
    return GestureDetector(
      onTap: () => _openTeamInPlayer(team),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: CachedImageWidget(
                imageUrl: team.image ?? '',
                width: 140,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.songname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(team.artistName ?? widget.worshipTeamName, style: const TextStyle(color: Colors.white60, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Song Tile Widget
  Widget _buildSongTile(SongModel song) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MusicPlayer(
              backgroundImage: song.image ?? song.albumImage ?? '',
              song: song.songname,
              artist: song.artistName ?? widget.worshipTeamName,
              id: song.id!,
            ),
          ),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedImageWidget(
          imageUrl: song.image ?? song.albumImage,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(song.songname, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(song.artistName ?? widget.worshipTeamName, 
        style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 28),
    );
  }
}