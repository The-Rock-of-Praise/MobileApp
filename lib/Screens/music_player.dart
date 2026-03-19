import 'package:flutter/material.dart';
import 'package:lyrics/OfflineService/offline_groupe_service.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/OfflineService/offline_worship_team_service.dart';
import 'package:lyrics/Screens/DrawerScreens/setting_screen.dart';
import 'package:lyrics/Service/color_service.dart';
import 'package:lyrics/Service/lyrics_service.dart';
import 'package:lyrics/Service/setlist_service.dart';
import 'package:lyrics/Service/setting_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';

// Import offline services
import 'package:lyrics/OfflineService/offline_song_service.dart';
import 'package:lyrics/OfflineService/offline_favorites_service.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MusicPlayer extends StatefulWidget {
  final String? backgroundImage;
  final int id;
  final String song;
  final String? artist;
  final String? lyrics;
  final String? language;
  final List<dynamic>? artists;
  final bool isWorshipTeam;

  const MusicPlayer({
    super.key,
    required this.backgroundImage,
    required this.song,
    required this.id,
    this.artist,
    this.artists,
    this.lyrics,
    this.language,
    this.isWorshipTeam = false,
  });

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  bool isPlaying = false;
  bool isFavorite = false;
  bool showLyrics = true;
  String selectedLyricsFormat = 'tamil_only';
  Map<String, String> multiLanguageLyrics = {};

  // Replace with offline services
  final OfflineSongService _songService = OfflineSongService();
  final OfflineSetlistService _setlistService = OfflineSetlistService();
  final OfflineGroupSongService _groupSongService = OfflineGroupSongService();
  final OfflineWorshipTeamService _worshipTeamService =
      OfflineWorshipTeamService();
  final OfflineFavoritesService _favoritesService = OfflineFavoritesService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  bool isLoadingLyrics = false;
  bool _isOnline = false;
  String? _dataSource;

  List<String> _currentDisplayOrder = [];

  int? currentSongId;
  String? currentUserId;
  bool isCheckingFavorite = false;

  // Font settings
  double baseFontSize = 18.0;
  bool isBoldText = false;
  Color selectedLyricsColor = Colors.white;

  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _initializePlayer();
    loadPremiumStatus();
    _reloadFontSettings();
    _reloadColorSettings();
    initializeFavoriteStatus();
  }

  // Helper method to get artist names as a formatted string
  String _getArtistNames() {
    // If we have an artists array, use that
    if (widget.artists != null && widget.artists!.isNotEmpty) {
      // Extract names from the GroupSongArtist objects
      final artistNames =
          widget.artists!.map((artist) {
            if (artist is GroupSongArtist) {
              return artist.name;
            } else if (artist is Map<String, dynamic>) {
              return artist['name']?.toString() ?? 'Unknown Artist';
            }
            return artist.toString();
          }).toList();

      print('artists names: $artistNames');
      return artistNames.join('\n');
    }

    // Fall back to the single artist field
    return widget.artist ?? 'Unknown Artist';
  }

  List<String> _getArtistNamesList() {
    // If we have an artists array, use that
    if (widget.artists != null && widget.artists!.isNotEmpty) {
      // Extract names from the GroupSongArtist objects
      return widget.artists!.map((artist) {
        if (artist is GroupSongArtist) {
          return artist.name;
        } else if (artist is Map<String, dynamic>) {
          return artist['name']?.toString() ?? 'Unknown Artist';
        }
        return artist.toString();
      }).toList();
    }

    // Fall back to the single artist field
    return widget.artist != null ? [widget.artist!] : ['Unknown Artist'];
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
      // Sync favorites
      await _favoritesService.syncPendingChanges();
      // Sync setlists
      await _setlistService.syncPendingChanges();

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

  Future<void> _reloadColorSettings() async {
    try {
      final color = await ColorService.getColor();
      if (mounted) {
        setState(() {
          selectedLyricsColor = color;
        });
      }
      print('Color settings reloaded: $color');
    } catch (e) {
      print('Error reloading color settings: $e');
    }
  }

  void onColorChanged(Color newColor) {
    setState(() {
      selectedLyricsColor = newColor;
    });
  }

  Future<void> initializeFavoriteStatus() async {
    try {
      currentUserId = await UserService.getUserID();
      setState(() {
        currentSongId = widget.id;
      });

      if (currentUserId != null && currentSongId != null) {
        await _checkFavoriteStatus();
      }
    } catch (e) {
      print('Error initializing favorite status: $e');
    }
  }

  // Add this method to reload all settings and data
  Future<void> _reloadAllSettings() async {
    try {
      // Show loading indicator
      setState(() {
        isLoadingLyrics = true;
      });

      // Reload all settings and data
      await Future.wait([
        _reloadFontSettings(),
        _reloadColorSettings(),
        loadPremiumStatus(),
      ]);

      // Check if lyrics format changed
      final newLyricsFormat = await HowToReadLyricsService.getLyricsFormat();

      // Always reload lyrics to ensure latest settings are applied
      setState(() {
        selectedLyricsFormat = newLyricsFormat;
      });

      // Reload lyrics with current/new format
      await _loadLyricsForCurrentFormat();

      // Force UI rebuild
      if (mounted) {
        setState(() {
          isLoadingLyrics = false;
        });
      }

      print('Settings reloaded successfully');
    } catch (e) {
      print('Error reloading settings: $e');
      _showErrorSnackBar('Error updating settings: $e');

      if (mounted) {
        setState(() {
          isLoadingLyrics = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (currentUserId == null || currentSongId == null) return;

    setState(() {
      isCheckingFavorite = true;
    });

    try {
      final result = await _favoritesService.checkFavoriteStatus(
        currentUserId!,
        currentSongId!,
      );

      if (result['success'] == true) {
        setState(() {
          isFavorite = result['isFavorite'] ?? false;
          _dataSource = result['source'];
        });

        // _showDataSourceIndicator(_dataSource ?? 'unknown');
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    } finally {
      setState(() {
        isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    currentUserId = await UserService.getUserID();
    currentSongId = widget.id;

    if (currentUserId == null) {
      _showErrorSnackBar('Please log in to add favorites');
      return;
    }

    if (currentSongId == null) {
      _showErrorSnackBar('Song information not available');
      return;
    }

    setState(() {
      isCheckingFavorite = true;
    });

    try {
      if (isFavorite) {
        // Remove from favorites
        final result = await _favoritesService.removeFromFavorites(
          userId: currentUserId!,
          songId: currentSongId!,
        );

        if (result['success'] == true) {
          setState(() {
            isFavorite = false;
          });

          final isPending = result['pending_sync'] ?? false;
          if (isPending) {
            _showSuccessSnackBar(
              'Removed from favorites (will sync when online)',
            );
          } else {
            _showSuccessSnackBar('Removed from favorites');
          }
        } else {
          _showErrorSnackBar(
            result['message'] ?? 'Failed to remove from favorites',
          );
        }
      } else {
        // Add to favorites
        final result = await _favoritesService.addToFavorites(
          userId: currentUserId!,
          songId: currentSongId!,
          songName: widget.song,
          artistName: _getArtistNames(),
          songImage: widget.backgroundImage!,
        );

        if (result['success'] == true) {
          setState(() {
            isFavorite = true;
          });

          final isPending = result['pending_sync'] ?? false;
          if (isPending) {
            _showSuccessSnackBar('Added to favorites (will sync when online)');
          } else {
            _showSuccessSnackBar('Added to favorites');
          }
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to add to favorites');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error updating favorites: $e');
    } finally {
      setState(() {
        isCheckingFavorite = false;
      });
    }
  }

  // void _showDataSourceIndicator(String source) {
  //   if (!mounted) return;

  //   String message;
  //   Color color;

  //   switch (source) {
  //     case 'online':
  //       message = '🌐 Live data';
  //       color = Colors.green;
  //       break;
  //     case 'cache':
  //       message = '📱 Cached data';
  //       color = Colors.orange;
  //       break;
  //     case 'local':
  //       message = '💾 Local data';
  //       color = Colors.blue;
  //       break;
  //     default:
  //       return;
  //   }

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       duration: Duration(seconds: 1),
  //       backgroundColor: color,
  //     ),
  //   );
  // }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _showSetListSelectionBottomSheet({
    required String userId,
    required int songId,
    required String songName,
    required String artistName,
    required String songImage,
    required String lyricsFormat,
    required Map<String, String> lyrics,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return OfflineSetListSelectionBottomSheet(
          userId: userId,
          songId: songId,
          songName: songName,
          artistName: artistName,
          songImage: songImage,
          lyricsFormat: lyricsFormat,
          lyrics: lyrics,
          setlistService: _setlistService,
          isOnline: _isOnline,
        );
      },
    );
  }

  Future<void> _addToSetList() async {
    try {
      final songId = widget.id;
      final currentUserId = await UserService.getUserID();

      if (currentUserId.isEmpty) {
        _showErrorSnackBar('Please log in to add to setlist');
        return;
      }

      // Prepare lyrics data - combine all current lyrics
      final lyricsData = <String, String>{};
      multiLanguageLyrics.forEach((key, value) {
        if (value.isNotEmpty && !key.contains('error')) {
          lyricsData[key] = value;
        }
      });

      await _showSetListSelectionBottomSheet(
        userId: currentUserId,
        songId: songId,
        songName: widget.song,
        artistName: _getArtistNames(),
        songImage: widget.backgroundImage!,
        lyricsFormat: selectedLyricsFormat,
        lyrics: lyricsData,
      );
    } catch (e) {
      _showErrorSnackBar('Error adding to setlist: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> loadPremiumStatus() async {
    final ispremiun = await UserService.getIsPremium();
    setState(() {
      isPremium = ispremiun == '1';
    });
  }

  Future<void> _initializePlayer() async {
    // Get saved lyrics format preference
    final lyricsFormat = await HowToReadLyricsService.getLyricsFormat();
    final fontSize = await FontSettingsService.getFontSize();
    final boldText = await FontSettingsService.getBoldText();
    final color = await ColorService.getColor();

    setState(() {
      selectedLyricsFormat = lyricsFormat;
      baseFontSize = fontSize;
      isBoldText = boldText;
      selectedLyricsColor = color;
      isLoadingLyrics = true;
    });

    await _loadLyricsForCurrentFormat();

    setState(() {
      isLoadingLyrics = false;
    });
  }

  Future<void> _loadLyricsForCurrentFormat() async {
    try {
      print('Loading lyrics for format: $selectedLyricsFormat');

      setState(() {
        isLoadingLyrics = true;
      });

      Map<String, dynamic> result;

      if (widget.isWorshipTeam) {
        // Worship team song
        result = await _worshipTeamService.getWorshipTeamLyricsByFormat(
          title: widget.song,
          format: selectedLyricsFormat,
        );
      } else if (widget.artist != null && widget.artists == null) {
        // Regular song
        result = await _songService.getSongLyricsByFormat(
          widget.song,
          selectedLyricsFormat,
        );
      } else {
        // Group song
        result = await _groupSongService.getGroupSongLyricsByFormat(
          title: widget.song,
          format: selectedLyricsFormat,
        );
      }

      print('Lyrics result: $result');

      if (result['success'] == true) {
        // Handle both response structures
        dynamic lyricsData;
        dynamic displayOrderData;

        if (result.containsKey('data')) {
          // Group song response structure
          final data = result['data'] as Map<String, dynamic>;
          lyricsData = data['lyrics'];
          displayOrderData = data['displayOrder'];
        } else {
          // Regular song response structure
          lyricsData = result['lyrics'];
          displayOrderData = result['displayOrder'];
        }

        setState(() {
          _dataSource = result['source'];
        });

        //_showDataSourceIndicator(_dataSource ?? 'unknown');

        if (lyricsData == null) {
          print('Lyrics data is null');
          setState(() {
            multiLanguageLyrics.clear();
            multiLanguageLyrics['error'] = 'No lyrics data received';
          });
          return;
        }

        final lyricsMap =
            lyricsData is Map<String, dynamic>
                ? lyricsData
                : <String, dynamic>{};

        final displayOrder =
            displayOrderData is List
                ? displayOrderData.cast<String>()
                : <String>[];

        print('Received lyrics for languages: ${lyricsMap.keys.toList()}');
        print('Display order: $displayOrder');

        // Clear existing lyrics
        multiLanguageLyrics.clear();

        // Populate lyrics from API response in the correct order
        for (String languageCode in displayOrder) {
          if (lyricsMap.containsKey(languageCode) &&
              lyricsMap[languageCode] != null &&
              lyricsMap[languageCode].toString().trim().isNotEmpty) {
            multiLanguageLyrics[languageCode] =
                lyricsMap[languageCode].toString();
            print('Added lyrics for language: $languageCode');
          }
        }

        // If no lyrics were added from display order, try all available lyrics
        if (multiLanguageLyrics.isEmpty) {
          lyricsMap.forEach((key, value) {
            if (value != null && value.toString().trim().isNotEmpty) {
              multiLanguageLyrics[key] = value.toString();
              if (!displayOrder.contains(key)) {
                displayOrder.add(key);
              }
            }
          });
        }

        // Store display order for UI
        _currentDisplayOrder = displayOrder;

        setState(() {});

        print('Final lyrics map: ${multiLanguageLyrics.keys.toList()}');

        if (multiLanguageLyrics.isEmpty) {
          setState(() {
            multiLanguageLyrics['error'] =
                'No lyrics available for this format';
          });
        }
      } else {
        print('API returned failure: ${result['message']}');
        setState(() {
          multiLanguageLyrics.clear();
          String errorMessage =
              result['message'] ?? 'Lyrics not available for this format';

          // Show offline-specific messages
          if (!_isOnline && result['source'] == 'cache') {
            errorMessage += ' (Offline mode)';
          }

          multiLanguageLyrics['error'] = errorMessage;
        });
      }
    } catch (e, stackTrace) {
      print('Exception in _loadLyricsForCurrentFormat: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        multiLanguageLyrics.clear();
        String errorMessage = 'Failed to load lyrics: ${e.toString()}';

        if (!_isOnline) {
          errorMessage += ' (Offline mode)';
        }

        multiLanguageLyrics['error'] = errorMessage;
      });
    } finally {
      setState(() {
        isLoadingLyrics = false;
      });
    }
  }

  Widget _buildLyricsContent() {
    print('=== CURRENT SETTINGS DEBUG ===');
    print('Base Font Size: $baseFontSize');
    print('Is Bold Text: $isBoldText');
    print('Selected Lyrics Color: $selectedLyricsColor');
    print('Selected Lyrics Format: $selectedLyricsFormat');
    print('Is Loading Lyrics: $isLoadingLyrics');
    print('Multi Language Lyrics Keys: ${multiLanguageLyrics.keys.toList()}');
    print('==============================');
    // Check if there's an error
    if (multiLanguageLyrics.containsKey('error')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              _isOnline ? Icons.error_outline : Icons.cloud_off,
              color: _isOnline ? Colors.red : Colors.orange,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              multiLanguageLyrics['error']!,
              style: TextStyle(
                color: _isOnline ? Colors.red : Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  _isOnline
                      ? () async {
                        setState(() {
                          isLoadingLyrics = true;
                        });
                        await _loadLyricsForCurrentFormat();
                        setState(() {
                          isLoadingLyrics = false;
                        });
                      }
                      : null,
              icon: Icon(_isOnline ? Icons.refresh : Icons.cloud_off),
              label: Text(_isOnline ? 'Retry' : 'Offline'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isOnline
                        ? Colors.red.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                foregroundColor: _isOnline ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Use the display order from API response, fallback to service order
    final displayOrder =
        _currentDisplayOrder.isNotEmpty
            ? _currentDisplayOrder
            : HowToReadLyricsService.getLanguageDisplayOrder(
              selectedLyricsFormat,
            );

    if (HowToReadLyricsService.isMultiLanguageFormat(selectedLyricsFormat)) {
      // Multi-language format - show only languages that have lyrics
      final availableLyrics =
          displayOrder
              .where(
                (languageCode) =>
                    multiLanguageLyrics.containsKey(languageCode) &&
                    multiLanguageLyrics[languageCode] != null &&
                    multiLanguageLyrics[languageCode]!.isNotEmpty,
              )
              .toList();

      if (availableLyrics.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
              const SizedBox(height: 12),
              Text(
                'No lyrics available for ${HowToReadLyricsService.getFormatTitle(selectedLyricsFormat)} format${!_isOnline ? ' (Offline mode)' : ''}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            availableLyrics.map((languageCode) {
              final lyrics = multiLanguageLyrics[languageCode]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25),
                  // Lyrics content with improved styling using current settings
                  Text(
                    lyrics,
                    style: TextStyle(
                      color: selectedLyricsColor.withOpacity(
                        0.95,
                      ), // Use current color
                      fontSize: FontSettingsService.getAdjustedFontSize(
                        baseFontSize, // Use current font size
                        languageCode,
                      ),
                      height: _getLineHeightForLanguage(languageCode),
                      fontWeight:
                          isBoldText
                              ? FontWeight.bold
                              : FontWeight.w400, // Use current bold setting
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              );
            }).toList(),
      );
    } else {
      // Single language format
      final languageCode = displayOrder.first;
      final lyrics = multiLanguageLyrics[languageCode];

      if (lyrics == null || lyrics.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
              const SizedBox(height: 12),
              Text(
                'Lyrics not available in ${HowToReadLyricsService.getLanguageDisplayName(languageCode)}${!_isOnline ? ' (Offline mode)' : ''}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Text(
        lyrics,
        style: TextStyle(
          color: selectedLyricsColor.withOpacity(0.95), // Use current color
          fontSize: FontSettingsService.getAdjustedFontSize(
            baseFontSize, // Use current font size
            languageCode,
          ),
          height: _getLineHeightForLanguage(languageCode),
          fontWeight:
              isBoldText
                  ? FontWeight.bold
                  : FontWeight.w400, // Use current bold setting
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.justify,
      );
    }
  }

  Future<void> _reloadFontSettings() async {
    try {
      final fontSize = await FontSettingsService.getFontSize();
      final boldText = await FontSettingsService.getBoldText();

      if (mounted) {
        setState(() {
          baseFontSize = fontSize;
          isBoldText = boldText;
        });
      }
      print('Font settings reloaded: size=$fontSize, bold=$boldText');
    } catch (e) {
      print('Error reloading font settings: $e');
    }
  }


  double _getLineHeightForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 2.2; // More spacing for Tamil script readability
      case 'si':
        return 2.1; // Slightly more for Sinhala script
      case 'en':
        return 2.0; // Standard for English
      default:
        return 2.0;
    }
  }

  Widget _buildImage() {
    final imageUrl = widget.backgroundImage;

    return CachedImageWidget(
      imageUrl: imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      placeholder: Container(
        width: 50,
        height: 50,
        color: Colors.grey,
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
        width: 50,
        height: 50,
        color: Colors.grey,
        child: const Icon(Icons.music_note, color: Colors.white, size: 25),
      ),
    );
  }

  Future<void> _changeLyricsFormat() async {
    final newFormat = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'How would you like to read lyrics?',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [
                    'tamil_only',
                    'tamil_english',
                    'tamil_sinhala',
                    'all_three',
                    'english_only',
                    'sinhala_only',
                  ].map((format) {
                    return ListTile(
                      title: Text(
                        HowToReadLyricsService.getFormatTitle(format),
                        style: const TextStyle(color: Colors.white),
                      ),
                      leading: Radio<String>(
                        value: format,
                        groupValue: selectedLyricsFormat,
                        onChanged: (value) => Navigator.pop(context, value),
                        activeColor: Colors.white,
                      ),
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );

    if (newFormat != null && newFormat != selectedLyricsFormat) {
      // Save preference
      await HowToReadLyricsService.saveLyricsFormat(newFormat);

      setState(() {
        selectedLyricsFormat = newFormat;
        isLoadingLyrics = true;
      });

      await _loadLyricsForCurrentFormat();

      setState(() {
        isLoadingLyrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272727),
      bottomNavigationBar: Container(
        height: 80,
        color: const Color(0xFF272727),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Song info and favorite
            Expanded(
              child: Row(
                children: [
                  // Album cover
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Song info
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.song,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Display multiple artists line by line
                          ..._getArtistNamesList().map(
                            (artistName) => Text(
                              artistName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Online/Offline indicator
                      Icon(
                        _isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: _isOnline ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),

                      // Favorite button
                      IconButton(
                        icon:
                            isCheckingFavorite
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                  size: 24,
                                ),
                        onPressed: isCheckingFavorite ? null : _toggleFavorite,
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(Icons.settings),
                                    title: Text('Settings'),
                                    onTap: () async {
                                      Navigator.pop(
                                        context,
                                      ); // Close the bottom sheet first

                                      // Show loading indicator immediately
                                      // ScaffoldMessenger.of(
                                      //   context,
                                      // ).showSnackBar(
                                      //   SnackBar(
                                      //     content: Row(
                                      //       children: [
                                      //         SizedBox(
                                      //           width: 16,
                                      //           height: 16,
                                      //           child: CircularProgressIndicator(
                                      //             strokeWidth: 2,
                                      //             valueColor:
                                      //                 AlwaysStoppedAnimation<
                                      //                   Color
                                      //                 >(Colors.white),
                                      //           ),
                                      //         ),
                                      //         SizedBox(width: 12),
                                      //         Text('Opening settings...'),
                                      //       ],
                                      //     ),
                                      //     duration: Duration(seconds: 1),
                                      //     backgroundColor: Colors.blue,
                                      //   ),
                                      // );

                                      // try {
                                      // Navigate to settings and wait for result
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const SettingsScreen(),
                                        ),
                                      );

                                      // Check if settings were changed
                                      if (result != null && result == true) {
                                        // Show updating indicator
                                        // ScaffoldMessenger.of(
                                        //   context,
                                        // ).showSnackBar(
                                        //   SnackBar(
                                        //     content: Row(
                                        //       children: [
                                        //         SizedBox(
                                        //           width: 16,
                                        //           height: 16,
                                        //           child: CircularProgressIndicator(
                                        //             strokeWidth: 2,
                                        //             valueColor:
                                        //                 AlwaysStoppedAnimation<
                                        //                   Color
                                        //                 >(Colors.white),
                                        //           ),
                                        //         ),
                                        //         SizedBox(width: 12),
                                        //         Text('Applying changes...'),
                                        //       ],
                                        //     ),
                                        //     duration: Duration(seconds: 3),
                                        //     backgroundColor: Colors.orange,
                                        //   ),
                                        // );

                                        // Reload all settings and refresh UI
                                        await _reloadAllSettings();

                                        //     // Show success message
                                        //     if (mounted) {
                                        //       ScaffoldMessenger.of(
                                        //         context,
                                        //       ).showSnackBar(
                                        //         SnackBar(
                                        //           content: Row(
                                        //             children: [
                                        //               Icon(
                                        //                 Icons.check_circle,
                                        //                 color: Colors.white,
                                        //                 size: 16,
                                        //               ),
                                        //               SizedBox(width: 8),
                                        //               Text(
                                        //                 'Settings updated successfully!',
                                        //               ),
                                        //             ],
                                        //           ),
                                        //           duration: Duration(seconds: 2),
                                        //           backgroundColor: Colors.green,
                                        //         ),
                                        //       );
                                        //     }
                                        //   }
                                        // } catch (e) {
                                        //   print(
                                        //     'Error handling settings return: $e',
                                        //   );
                                        //   if (mounted) {
                                        //     ScaffoldMessenger.of(
                                        //       context,
                                        //     ).showSnackBar(
                                        //       SnackBar(
                                        //         content: Text(
                                        //           'Error updating settings: $e',
                                        //         ),
                                        //         backgroundColor: Colors.red,
                                        //         duration: Duration(seconds: 3),
                                        //       ),
                                        //     );
                                        //   }
                                        //   }
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.share),
                                    title: Text('Share'),
                                    trailing:
                                        isPremium == false
                                            ? Icon(
                                              Icons.lock,
                                              color: Colors.grey,
                                              size: 20,
                                            )
                                            : null,
                                    onTap:
                                        isPremium
                                            ? () {
                                              Navigator.pop(context);
                                              // Add your share functionality here
                                            }
                                            : null,
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.playlist_add),
                                    title: Text('My Set List'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!_isOnline)
                                          Icon(
                                            Icons.cloud_off,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                        if (!_isOnline)
                                          const SizedBox(width: 4),
                                        if (isPremium == false)
                                          Icon(
                                            Icons.lock,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                    onTap:
                                        isPremium == false
                                            ? null
                                            : () {
                                              Navigator.pop(context);
                                              _addToSetList();
                                            },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.lyrics),
                                    trailing:
                                        isPremium == false
                                            ? Icon(
                                              Icons.lock,
                                              color: Colors.grey,
                                              size: 20,
                                            )
                                            : null,
                                    title: Text('How to Read Lyrics'),
                                    onTap:
                                        isPremium == false
                                            ? null
                                            : _changeLyricsFormat,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child:
                  widget.backgroundImage != null
                      ? widget.backgroundImage!.startsWith('http') ||
                              widget.backgroundImage!.startsWith('https')
                          ? CachedImageWidget(
                            imageUrl: widget.backgroundImage ?? '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.fitHeight,
                            placeholder: Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                                size: 80,
                              ),
                            ),
                          )
                          : Image.asset(
                            widget.backgroundImage ?? '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.fitHeight,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                  size: 80,
                                ),
                              );
                            },
                          )
                      : Image.asset(''),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF173857).withOpacity(0.9),
                      const Color(0xFF000000).withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Column(
              children: [
                // Header with controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      // Song title with connectivity indicator
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Text(
                              widget.song,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_dataSource != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSourceColor(
                                    _dataSource!,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
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
                      ),
                      const Spacer(),
                      // Toggle lyrics/info button
                      IconButton(
                        icon: Icon(
                          showLyrics ? Icons.info : Icons.lyrics,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            showLyrics = !showLyrics;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Main content area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child:
                        showLyrics ? _buildLyricsView() : _buildSongInfoView(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildLyricsView() {
    if (isLoadingLyrics) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading lyrics...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lyrics content based on selected format
          _buildLyricsContent(),
        ],
      ),
    );
  }

  Widget _buildSongInfoView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song info header
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Song Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Connection status
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Song details
          _buildInfoCard('Title', widget.song),
          const SizedBox(height: 16),
          _buildInfoCard('Artist(s)', _getArtistNames()),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Reading Format',
            HowToReadLyricsService.getFormatTitle(selectedLyricsFormat),
          ),

          if (multiLanguageLyrics.isNotEmpty &&
              !multiLanguageLyrics.containsKey('error')) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              'Available Languages',
              multiLanguageLyrics.keys
                  .map(
                    (code) =>
                        HowToReadLyricsService.getLanguageDisplayName(code),
                  )
                  .join(', '),
            ),
          ],

          if (_dataSource != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Data Source', _dataSource!.toUpperCase()),
          ],

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showLyrics = true;
                    });
                  },
                  icon: const Icon(Icons.lyrics),
                  label: const Text('View Lyrics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPremium ? _changeLyricsFormat : null,
                  icon: Icon(
                    isPremium ? Icons.format_list_bulleted : Icons.lock,
                  ),
                  label: Text(isPremium ? 'Change Format' : 'Premium Only'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: isPremium ? Colors.white : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color:
                            isPremium
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (!_isOnline) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Offline mode: Some features may be limited',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _songService.dispose();
    super.dispose();
  }
}

// Offline SetList Selection Bottom Sheet
class OfflineSetListSelectionBottomSheet extends StatefulWidget {
  final String userId;
  final int songId;
  final String songName;
  final String artistName;
  final String songImage;
  final String lyricsFormat;
  final Map<String, String> lyrics;
  final OfflineSetlistService setlistService;
  final bool isOnline;

  const OfflineSetListSelectionBottomSheet({
    super.key,
    required this.userId,
    required this.songId,
    required this.songName,
    required this.artistName,
    required this.songImage,
    required this.lyricsFormat,
    required this.lyrics,
    required this.setlistService,
    required this.isOnline,
  });

  @override
  State<OfflineSetListSelectionBottomSheet> createState() =>
      _OfflineSetListSelectionBottomSheetState();
}

class _OfflineSetListSelectionBottomSheetState
    extends State<OfflineSetListSelectionBottomSheet> {
  List<SetListFolder> folders = [];
  bool isLoading = true;
  final TextEditingController _newFolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await widget.setlistService.getFolders(widget.userId);
      if (result['success'] == true) {
        final foldersData = result['data'] as List<dynamic>? ?? [];
        setState(() {
          folders =
              foldersData
                  .map((folderJson) => SetListFolder.fromJson(folderJson))
                  .toList();
        });

        // Show data source
        _showDataSourceIndicator(result['source'] ?? 'unknown');
      }
    } catch (e) {
      print('Error loading folders: $e');
      _showErrorMessage('Error loading folders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDataSourceIndicator(String source) {
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

  Future<void> _createNewFolder(String folderName) async {
    try {
      final result = await widget.setlistService.createFolder(
        widget.userId,
        folderName,
      );

      if (result['success'] == true) {
        await _loadFolders();

        final isPending = result['pending_sync'] ?? false;
        if (isPending) {
          _showSuccessMessage('Folder created locally, will sync when online');
        } else {
          _showSuccessMessage('Folder created successfully');
        }
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to create folder');
      }
    } catch (e) {
      _showErrorMessage('Error creating folder: $e');
    }
  }

  Future<void> _addSongToFolder(SetListFolder folder) async {
    try {
      String savedLyrics = '';
      widget.lyrics.forEach((key, value) {
        if (value.isNotEmpty) {
          savedLyrics += '$key: $value\n\n';
        }
      });

      final result = await widget.setlistService.addSongToFolder(
        folderId: folder.id,
        songId: widget.songId,
        songName: widget.songName,
        artistName: widget.artistName,
        songImage: widget.songImage,
        lyricsFormat: widget.lyricsFormat,
        savedLyrics: savedLyrics,
      );

      if (result['success'] == true) {
        Navigator.pop(context);

        final isPending = result['pending_sync'] ?? false;
        if (isPending) {
          _showSuccessMessage('Song added locally, will sync when online');
        } else {
          _showSuccessMessage('Song added to ${folder.folderName}');
        }
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to add song');
      }
    } catch (e) {
      _showErrorMessage('Error adding song: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Add to Set List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Connection indicator
              Icon(
                widget.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: widget.isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl:
                          widget.songImage.startsWith('http')
                              ? widget.songImage
                              : null,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: Container(
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
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.songName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.artistName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _newFolderController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Create new set list...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _createNewFolder(value.trim());
                        _newFolderController.clear();
                      }
                    },
                  ),
                ),
                if (!widget.isOnline)
                  Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                if (!widget.isOnline) const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_newFolderController.text.trim().isNotEmpty) {
                      _createNewFolder(_newFolderController.text.trim());
                      _newFolderController.clear();
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Existing Set Lists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : folders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isOnline
                                ? Icons.folder_open
                                : Icons.cloud_off,
                            color: Colors.white60,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isOnline
                                ? 'No set lists yet.\nCreate your first one above!'
                                : 'No set lists available offline.\nConnect to internet to see more.',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.orange,
                          ),
                          title: Text(
                            folder.folderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${folder.songCount} songs',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.isOnline)
                                Icon(
                                  Icons.cloud_off,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                              if (!widget.isOnline) const SizedBox(width: 8),
                              const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          onTap: () => _addSongToFolder(folder),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }
}
