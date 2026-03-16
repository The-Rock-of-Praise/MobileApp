import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/Screens/music_player.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/Service/setlist_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import offline services
import 'package:lyrics/OfflineService/connectivity_manager.dart';

class MySetList extends StatefulWidget {
  const MySetList({super.key});

  @override
  State<MySetList> createState() => _MySetListState();
}

class _MySetListState extends State<MySetList> {
  List<SetListFolder> folders = [];
  bool isLoading = true;
  String? currentUserId;

  // Offline support
  final OfflineSetlistService _setlistService = OfflineSetlistService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  bool _isOnline = false;
  String? _dataSource;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _initializeSetList();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline ? '🌐 Back online' : '📱 Offline mode'),
            duration: Duration(seconds: 2),
            backgroundColor: _isOnline ? Colors.green : Colors.orange,
          ),
        );

        // Sync when coming back online
        if (_isOnline && wasOffline) {
          _syncDataWhenOnline();
        }
      }
    });
  }

  Future<void> _syncDataWhenOnline() async {
    try {
      await _setlistService.syncPendingChanges();

      // Reload folders to get updated data
      await _loadFolders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Set lists synchronized'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  Future<void> _initializeSetList() async {
    try {
      currentUserId = await UserService.getUserID();
      if (currentUserId != null) {
        await _loadFolders();
      }
    } catch (e) {
      print('Error initializing setlist: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFolders() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _setlistService.getFolders(currentUserId!);
      if (result['success'] == true) {
        final foldersData = result['data'] as List<dynamic>? ?? [];
        setState(() {
          folders =
              foldersData
                  .map((folderJson) => SetListFolder.fromJson(folderJson))
                  .toList();
          _dataSource = result['source'];
        });

        _showDataSourceIndicator(_dataSource ?? 'unknown');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load folders');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading folders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDataSourceIndicator(String source) {
    if (!mounted) return;

    String message;
    Color color;

    switch (source) {
      case 'online':
        message = '🌐 Live folders';
        color = Colors.green;
        break;
      case 'cache':
        message = '📱 Cached folders';
        color = Colors.orange;
        break;
      case 'local':
        message = '💾 Local folders';
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

  Future<void> _createNewFolder() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Row(
            children: [
              const Text(
                'Create New Folder',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              // Connection indicator
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Creating offline - will sync when online',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: 2,
              ),
            ],
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
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true && currentUserId != null) {
      final folderName = nameController.text.trim();
      final description = descriptionController.text.trim();

      try {
        final createResult = await _setlistService.createFolder(
          currentUserId!,
          folderName,
          description: description.isEmpty ? null : description,
        );

        if (createResult['success'] == true) {
          final isPending = createResult['pending_sync'] ?? false;
          if (isPending) {
            _showSuccessSnackBar(
              'Folder created locally, will sync when online',
            );
          } else {
            _showSuccessSnackBar('Folder created successfully');
          }
          await _loadFolders(); // Refresh the list
        } else {
          _showErrorSnackBar(
            createResult['message'] ?? 'Failed to create folder',
          );
        }
      } catch (e) {
        _showErrorSnackBar('Error creating folder: $e');
      }
    }
  }

  Future<void> _deleteFolder(SetListFolder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Row(
            children: [
              const Text(
                'Delete Folder',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              // Connection indicator
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Marking for deletion - will sync when online',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Are you sure you want to delete "${folder.folderName}"?\nThis will remove all songs in this folder.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final result = await _setlistService.deleteFolder(folder.id);
        if (result['success'] == true) {
          final isPending = result['pending_sync'] ?? false;
          if (isPending) {
            _showSuccessSnackBar(
              'Folder marked for deletion, will sync when online',
            );
          } else {
            _showSuccessSnackBar('Folder deleted successfully');
          }
          await _loadFolders();
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to delete folder');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting folder: $e');
      }
    }
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

  Color _getSourceColor(String source) {
    switch (source) {
      case 'online':
        return Colors.green;
      case 'cache':
        return Colors.orange;
      case 'local':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFolderCard(SetListFolder folder) {
    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to folder contents
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FolderSongsScreen(
                    folder: folder,
                    setlistService: _setlistService,
                    isOnline: _isOnline,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder, color: Colors.blue, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            folder.folderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Connection indicator for each folder
                        Icon(
                          _isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: _isOnline ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (folder.description != null &&
                        folder.description!.isNotEmpty)
                      Text(
                        folder.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.music_note, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        // Text(
                        //   '${folder.songCount} songs',
                        //   style: const TextStyle(
                        //     color: Colors.white54,
                        //     fontSize: 12,
                        //   ),
                        // ),
                        if (_dataSource != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getSourceColor(
                                _dataSource!,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSourceColor(_dataSource!),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _dataSource!.toUpperCase(),
                              style: TextStyle(
                                color: _getSourceColor(_dataSource!),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                color: const Color(0xFF3A3A3A),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteFolder(folder);
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                            if (!_isOnline) ...[
                              const Spacer(),
                              const Icon(
                                Icons.cloud_off,
                                color: Colors.orange,
                                size: 14,
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF173857),
        title: Row(
          children: [
            const Text('My Set Lists', style: TextStyle(color: Colors.white)),
            const Spacer(),
            // Online/Offline indicator in app bar
            Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.orange,
              size: 20,
            ),
            if (_dataSource != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSourceColor(_dataSource!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSourceColor(_dataSource!),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _dataSource!.toUpperCase(),
                  style: TextStyle(
                    color: _getSourceColor(_dataSource!),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewFolder),
        ],
      ),
      body: MainBAckgound(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : folders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: _loadFolders,
                  child: ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      return _buildFolderCard(folders[index]);
                    },
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFolder,
        backgroundColor: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            if (!_isOnline) ...[
              const SizedBox(width: 4),
              const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOnline ? Icons.folder_open : Icons.cloud_off,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _isOnline ? 'No Set Lists Yet' : 'No Set Lists Available Offline',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOnline
                ? 'Create your first set list to\norganize your favorite songs'
                : 'Connect to internet to see your set lists\nor create new ones offline',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewFolder,
            icon: Icon(_isOnline ? Icons.add : Icons.cloud_off),
            label: Text(_isOnline ? 'Create Set List' : 'Create Offline'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOnline ? Colors.blue : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          if (!_isOnline) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Offline mode: Set lists created will sync when you\'re back online',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _setlistService.dispose();
    super.dispose();
  }
}

// Updated Folder Songs Screen with offline support
class FolderSongsScreen extends StatefulWidget {
  final SetListFolder folder;
  final OfflineSetlistService setlistService;
  final bool isOnline;

  const FolderSongsScreen({
    super.key,
    required this.folder,
    required this.setlistService,
    required this.isOnline,
  });

  @override
  State<FolderSongsScreen> createState() => _FolderSongsScreenState();
}

class _FolderSongsScreenState extends State<FolderSongsScreen> {
  List<SetListSong> songs = [];
  bool isLoading = true;
  String? _dataSource;
  bool _isOnline = false;
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnline;
    _initializeConnectivity();
    _loadSongs();
  }

  Future<void> _initializeConnectivity() async {
    // Listen to connectivity changes
    _connectivityManager.connectivityStream.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (mounted) {
        setState(() {});

        // Show connectivity status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline ? '🌐 Back online' : '📱 Offline mode'),
            duration: Duration(seconds: 2),
            backgroundColor: _isOnline ? Colors.green : Colors.orange,
          ),
        );

        // Sync when coming back online
        if (_isOnline && wasOffline) {
          _syncDataWhenOnline();
        }
      }
    });
  }

  Future<void> _syncDataWhenOnline() async {
    try {
      await widget.setlistService.syncPendingChanges();
      await _loadSongs(); // Reload songs

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Songs synchronized'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  Future<void> _loadSongs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await widget.setlistService.getFolderSongs(
        widget.folder.id,
      );
      if (result['success'] == true) {
        final songsData = result['data'] as List<dynamic>? ?? [];
        setState(() {
          songs =
              songsData
                  .map((songJson) => SetListSong.fromJson(songJson))
                  .toList();
          _dataSource = result['source'];
        });

        _showDataSourceIndicator(_dataSource ?? 'unknown');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to load songs');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading songs: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDataSourceIndicator(String source) {
    if (!mounted) return;

    String message;
    Color color;

    switch (source) {
      case 'online':
        message = '🌐 Live songs';
        color = Colors.green;
        break;
      case 'cache':
        message = '📱 Cached songs';
        color = Colors.orange;
        break;
      case 'local':
        message = '💾 Local songs';
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

  Future<void> _removeSong(SetListSong song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Row(
            children: [
              const Text('Remove Song', style: TextStyle(color: Colors.white)),
              const Spacer(),
              // Connection indicator
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Marking for removal - will sync when online',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Remove "${song.songName}" from this set list?',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
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

    if (confirm == true) {
      try {
        final result = await widget.setlistService.removeSongFromSetlist(
          song.id,
        );
        if (result['success'] == true) {
          final isPending = result['pending_sync'] ?? false;
          if (isPending) {
            _showSuccessSnackBar(
              'Song marked for removal, will sync when online',
            );
          } else {
            _showSuccessSnackBar('Song removed successfully');
          }
          await _loadSongs();
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to remove song');
        }
      } catch (e) {
        _showErrorSnackBar('Error removing song: $e');
      }
    }
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

  Color _getSourceColor(String source) {
    switch (source) {
      case 'online':
        return Colors.green;
      case 'cache':
        return Colors.orange;
      case 'local':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSongCard(SetListSong song) {
    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to music player with saved lyrics
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MusicPlayer(
                    backgroundImage:
                        song.songImage ?? 'assets/Rectangle 29.png',
                    song: song.songName,
                    artist: song.artistName,
                    lyrics: song.savedLyrics,
                    language: song.lyricsFormat,
                    id: song.songId, // Use songId instead of id for music player
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Song image with cached loading
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      song.songImage != null && song.songImage!.isNotEmpty
                          ? CachedImageWidget(
                            imageUrl:
                                song.songImage!.startsWith('http')
                                    ? song.songImage
                                    : null,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[700],
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
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
                              width: 60,
                              height: 60,
                              color: Colors.grey[700],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          )
                          : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[700],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              // Song details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.songName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Connection indicator for each song
                        Icon(
                          _isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: _isOnline ? Colors.green : Colors.orange,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artistName,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getFormatDisplayName(song.lyricsFormat),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_dataSource != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getSourceColor(
                                _dataSource!,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSourceColor(_dataSource!),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _dataSource!.toUpperCase(),
                              style: TextStyle(
                                color: _getSourceColor(_dataSource!),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                    _removeSong(song);
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remove',
                              style: TextStyle(color: Colors.white),
                            ),
                            if (!_isOnline) ...[
                              const Spacer(),
                              const Icon(
                                Icons.cloud_off,
                                color: Colors.orange,
                                size: 14,
                              ),
                            ],
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

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'tamil_only':
        return 'Tamil Only';
      case 'tamil_english':
        return 'Tamil + English';
      case 'tamil_sinhala':
        return 'Tamil + Sinhala';
      case 'all_three':
        return 'All Languages';
      case 'english_only':
        return 'English Only';
      case 'sinhala_only':
        return 'Sinhala Only';
      default:
        return format;
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
            Expanded(
              child: Text(
                widget.folder.folderName,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Online/Offline indicator in app bar
            Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.orange,
              size: 20,
            ),
            if (_dataSource != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSourceColor(_dataSource!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSourceColor(_dataSource!),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _dataSource!.toUpperCase(),
                  style: TextStyle(
                    color: _getSourceColor(_dataSource!),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MainBAckgound(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : songs.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: _loadSongs,
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return _buildSongCard(songs[index]);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOnline ? Icons.music_note : Icons.cloud_off,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _isOnline ? 'No Songs Yet' : 'No Songs Available Offline',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOnline
                ? 'Add songs from the music player\nto start building your set list'
                : 'Connect to internet to see your songs\nor add new ones from the music player',
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (!_isOnline) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Offline Mode',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Songs added to this set list will sync when you\'re back online',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
