import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/Screens/add_note_screen.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class WorshipNotesScreen extends StatefulWidget {
  const WorshipNotesScreen({super.key});

  @override
  State<WorshipNotesScreen> createState() => _WorshipNotesScreenState();
}

class _WorshipNotesScreenState extends State<WorshipNotesScreen> {
  final OfflineWorshipNotesService _notesService = OfflineWorshipNotesService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  String selectedFilter = 'All';
  List<NoteItem> allNotes = [];
  bool isLoading = true;
  bool hasError = false;
  bool _isOnline = false;
  String? _dataSource;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _fetchNotes();
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

        // Sync when coming back online
        if (_isOnline && wasOffline) {
          _syncDataWhenOnline();
        }
      }
    });
  }

  Future<void> _syncDataWhenOnline() async {
    try {
      await _notesService.syncPendingChanges();

      // Reload notes to get updated data
      await _fetchNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Worship notes synchronized'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  Future<void> _fetchNotes() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final result = await _notesService.getUserWorshipNotes();
      if (result['success']) {
        final notesData = result['notes'] as List<dynamic>;
        setState(() {
          allNotes =
              notesData.map((note) {
                return NoteItem(
                  id: note['id'].toString(),
                  title: note['note'] ?? 'No title',
                  date: DateTime.parse(note['created_at']),
                  content: note['note'],
                );
              }).toList();
          _dataSource = result['source'];
        });

        _showDataSourceIndicator(_dataSource ?? 'unknown');
      } else {
        setState(() {
          hasError = true;
        });
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      _showErrorSnackBar('Failed to load notes: $e');
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
        message = '🌐 Live notes';
        color = Colors.green;
        break;
      case 'cache':
        message = '📱 Cached notes';
        color = Colors.orange;
        break;
      case 'local':
        message = '💾 Local notes';
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

  List<NoteItem> getFilteredNotes() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    if (selectedFilter == 'All') return allNotes;
    if (selectedFilter == 'Previous 7 Days') {
      return allNotes.where((note) => note.date.isAfter(sevenDaysAgo)).toList();
    }
    if (selectedFilter == 'Previous 30 Days') {
      return allNotes
          .where((note) => note.date.isAfter(thirtyDaysAgo))
          .toList();
    }
    return allNotes;
  }

  Map<String, List<NoteItem>> groupNotesByDate() {
    final filteredNotes = getFilteredNotes();
    final Map<String, List<NoteItem>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    for (final note in filteredNotes) {
      final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
      String category;

      if (noteDate == today) {
        category = 'Today';
      } else if (noteDate == yesterday) {
        category = 'Yesterday';
      } else if (noteDate.isAfter(now.subtract(Duration(days: 7)))) {
        category = 'Previous 7 Days';
      } else if (noteDate.isAfter(now.subtract(Duration(days: 30)))) {
        category = 'Previous 30 Days';
      } else {
        category = DateFormat('MMMM yyyy').format(noteDate);
      }

      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(note);
    }

    return grouped;
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E3A5F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter by',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
              SizedBox(height: 20),
              ...['All', 'Previous 7 Days', 'Previous 30 Days'].map(
                (filter) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    filter,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing:
                      selectedFilter == filter
                          ? Icon(Icons.check, color: Colors.white)
                          : null,
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotes = groupNotesByDate();

    return Scaffold(
      backgroundColor: Color(0xFF1E3A5F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Worship Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Online/Offline indicator
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
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white, size: 24),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddNoteScreen(
                        notesService: _notesService,
                        isOnline: _isOnline,
                      ),
                ),
              );
              if (result != null && result['success']) {
                _fetchNotes(); // Refresh the list after adding a new note
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 24),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF0F1B2E)],
          ),
        ),
        child:
            isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOnline ? Icons.error_outline : Icons.cloud_off,
                        color: _isOnline ? Colors.red : Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isOnline
                            ? 'Failed to load notes'
                            : 'No cached notes available',
                        style: TextStyle(
                          color: _isOnline ? Colors.red : Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isOnline ? Colors.red : Colors.orange,
                        ),
                        child: Text(_isOnline ? 'Retry' : 'Try Again'),
                      ),
                    ],
                  ),
                )
                : allNotes.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOnline ? Icons.note_add : Icons.cloud_off,
                        size: 80,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isOnline
                            ? 'No notes found'
                            : 'No notes available offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOnline
                            ? 'Create your first worship note'
                            : 'Connect to internet or create notes offline',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddNoteScreen(
                                    notesService: _notesService,
                                    isOnline: _isOnline,
                                  ),
                            ),
                          );
                          if (result != null && result['success']) {
                            _fetchNotes();
                          }
                        },
                        icon: Icon(_isOnline ? Icons.add : Icons.cloud_off),
                        label: Text(
                          _isOnline ? 'Create Note' : 'Create Offline',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isOnline ? Colors.blue : Colors.orange,
                          foregroundColor: Colors.white,
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
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'Offline mode: Notes created will sync when you\'re back online',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _fetchNotes,
                  color: Colors.white,
                  backgroundColor: Color(0xFF1E3A5F),
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      ...groupedNotes.entries.map((entry) {
                        final category = entry.key;
                        final notes = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Header
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 12,
                                top:
                                    category == groupedNotes.keys.first
                                        ? 0
                                        : 24,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_dataSource != null)
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
                              ),
                            ),
                            // Notes in this category
                            ...notes.map(
                              (note) => GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddNoteScreen(
                                            existingNoteId: note.id,
                                            existingNoteContent: note.content,
                                            notesService: _notesService,
                                            isOnline: _isOnline,
                                          ),
                                    ),
                                  );
                                  if (result != null && result['success']) {
                                    _fetchNotes(); // Refresh after editing
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    note.title.length > 50
                                                        ? '${note.title.substring(0, 50)}...'
                                                        : note.title,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                // Connection indicator for each note
                                                Icon(
                                                  _isOnline
                                                      ? Icons.cloud_done
                                                      : Icons.cloud_off,
                                                  color:
                                                      _isOnline
                                                          ? Colors.green
                                                          : Colors.orange,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _formatDate(note.date),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} • '
        '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _notesService.dispose();
    super.dispose();
  }
}

class NoteItem {
  final String id;
  final String title;
  final DateTime date;
  final String content;

  NoteItem({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
  });
}
