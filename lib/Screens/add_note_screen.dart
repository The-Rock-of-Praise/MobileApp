// Updated AddNoteScreen.dart with offline support
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddNoteScreen extends StatefulWidget {
  final String? existingNoteId;
  final String? existingNoteContent;
  final OfflineWorshipNotesService notesService;
  final bool isOnline;

  const AddNoteScreen({
    super.key,
    this.existingNoteId,
    this.existingNoteContent,
    required this.notesService,
    required this.isOnline,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  bool _isKeyboardVisible = false;
  bool _isSaving = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnline;

    // Initialize with existing note content if editing
    if (widget.existingNoteContent != null) {
      _noteController.text = widget.existingNoteContent!;
    }

    // Auto focus the text field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Listen to keyboard visibility
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
      });
    });

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
      await widget.notesService.syncPendingChanges();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Notes synchronized'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.existingNoteId != null) {
        // Update existing note
        final result = await widget.notesService.updateWorshipNote(
          noteId: widget.existingNoteId!,
          note: _noteController.text.trim(),
        );

        if (result['success']) {
          final isPending = result['pending_sync'] ?? false;
          Navigator.of(
            context,
          ).pop({'success': true, 'isUpdate': true, 'pending_sync': isPending});
        } else {
          _showErrorSnackBar(result['message']);
        }
      } else {
        // Create new note
        final result = await widget.notesService.createWorshipNote(
          _noteController.text.trim(),
        );

        if (result['success']) {
          final isPending = result['pending_sync'] ?? false;
          Navigator.of(context).pop({
            'success': true,
            'isUpdate': false,
            'pending_sync': isPending,
          });
        } else {
          _showErrorSnackBar(result['message']);
        }
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.existingNoteId == null) {
      Navigator.of(context).pop();
      return;
    }

    // Show confirmation dialog with offline warning
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF1E3A5F),
            title: Row(
              children: [
                Text('Delete Note', style: TextStyle(color: Colors.white)),
                const Spacer(),
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
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Are you sure you want to delete this note? This action cannot be undone.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await widget.notesService.deleteWorshipNote(
        widget.existingNoteId!,
      );

      if (result['success']) {
        final isPending = result['pending_sync'] ?? false;
        Navigator.of(
          context,
        ).pop({'success': true, 'deleted': true, 'pending_sync': isPending});
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              widget.existingNoteId != null ? 'Edit Note' : 'New Note',
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
          ],
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isOnline) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                  ],
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 24),
            onPressed: () {
              _showMoreOptions();
            },
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
        child: Column(
          children: [
            // Offline warning banner
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline mode: Changes will sync when online',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Main text area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _noteController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        _isOnline
                            ? 'Start typing your worship notes...'
                            : 'Start typing your worship notes... (offline)',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: Colors.white,
                ),
              ),
            ),

            // Bottom toolbar when keyboard is visible
            if (_isKeyboardVisible)
              Container(
                height: 50,
                color: Color(0xFF2A4A6B),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Text formatting options
                    IconButton(
                      icon: Icon(
                        Icons.format_bold,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _insertFormatting('**', '**');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.format_italic,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _insertFormatting('*', '*');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.format_list_bulleted,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _insertText('• ');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.format_quote,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _insertText('"');
                      },
                    ),
                    Spacer(),
                    Row(
                      children: [
                        if (!_isOnline) ...[
                          Icon(Icons.cloud_off, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${_noteController.text.split(' ').where((word) => word.isNotEmpty).length} words',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _insertFormatting(String startTag, String endTag) {
    final text = _noteController.text;
    final selection = _noteController.selection;

    if (selection.isValid) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$startTag${text.substring(selection.start, selection.end)}$endTag',
      );

      _noteController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              selection.start +
              startTag.length +
              (selection.end - selection.start) +
              endTag.length,
        ),
      );
    }
  }

  void _insertText(String textToInsert) {
    final text = _noteController.text;
    final selection = _noteController.selection;

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      textToInsert,
    );

    _noteController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + textToInsert.length,
      ),
    );
  }

  void _showMoreOptions() {
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
            children: [
              // Connection status header
              Row(
                children: [
                  Text(
                    'Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: _isOnline ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: Icon(Icons.share, color: Colors.white),
                title: Text(
                  'Share Note',
                  style: TextStyle(color: Colors.white),
                ),
                trailing:
                    !_isOnline
                        ? Icon(Icons.cloud_off, color: Colors.orange, size: 16)
                        : null,
                onTap: () {
                  Navigator.pop(context);
                  // Handle share - works offline too
                  _shareNote();
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.white),
                title: Text(
                  'Copy to Clipboard',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: _noteController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note copied to clipboard')),
                  );
                },
              ),
              if (widget.existingNoteId != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete Note',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing:
                      !_isOnline
                          ? Icon(
                            Icons.cloud_off,
                            color: Colors.orange,
                            size: 16,
                          )
                          : null,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteNote();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _shareNote() {
    // Basic share functionality - works offline
    final text = _noteController.text;
    if (text.trim().isNotEmpty) {
      // You can use share_plus package or platform-specific sharing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share functionality would be implemented here'),
        ),
      );
    }
  }
}
