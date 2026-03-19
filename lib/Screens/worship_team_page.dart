import 'package:flutter/material.dart';
import 'package:lyrics/Models/worship_team_model.dart';
import 'package:lyrics/OfflineService/connectivity_manager.dart';
import 'package:lyrics/OfflineService/offline_worship_team_service.dart';
import 'package:lyrics/Screens/DrawerScreens/premium_screen.dart';
import 'package:lyrics/Service/language_service.dart';
import 'worship_team_details.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/cached_image_widget.dart';
import 'package:lyrics/widgets/main_background.dart';
// Needed for conversion if required

class WorshipTeamPage extends StatefulWidget {
  const WorshipTeamPage({super.key});

  @override
  State<WorshipTeamPage> createState() => _WorshipTeamPageState();
}

class _WorshipTeamPageState extends State<WorshipTeamPage> {
  final OfflineWorshipTeamService _worshipTeamService =
      OfflineWorshipTeamService();
  final TextEditingController _searchController = TextEditingController();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  List<WorshipTeamModel> allWorshipTeams = [];
  List<WorshipTeamModel> filteredWorshipTeams = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentLanguage;
  String? languageDisplayName;

  @override
  void initState() {
    super.initState();
    _loadAllWorshipTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _worshipTeamService.dispose();
    super.dispose();
  }

  Future<void> _loadAllWorshipTeams() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get the current language
      final lang = await LanguageService.getLanguage();
      final langCode = LanguageService.getLanguageCode(lang);

      // Load ALL worship teams from the generic endpoint (which user confirmed works)
      // We will filter by language client-side
      final result = await _worshipTeamService.getWorshipTeamsByLanguage(
        langCode,
      );

      if (result['success']) {
        final List<WorshipTeamModel> loadedTeams = [];
        final teamsData = result['worshipTeams'] as List<dynamic>? ?? [];

        for (var data in teamsData) {
          WorshipTeamModel? team;
          if (data is WorshipTeamModel) {
            team = data;
          } else if (data is Map<String, dynamic>) {
            team = WorshipTeamModel.fromJson(data);
          }

          if (team != null) {
            // Filter by language
            // Include if artist_languages is empty (assume universal) OR contains langCode
            // OR if user wants "all" regardless? The instruction said "considering the language".
            // So we strictly filter unless info is missing.

            // "artist_languages" in JSON from user: ["en"].
            // If user's app lang is 'si', it shouldn't show.
            // But if user wants to see *something* and the language endpoint is broken, maybe we should be lenient.
            // For now, implement filtering logic.

            bool matchesLanguage = false;
            if (team.artistLanguages.isEmpty) {
              matchesLanguage =
                  true; // No language specified, show to everyone? Or maybe strict?
              // Usually if empty, it might be safer to show.
            } else {
              // Check if any of the team's languages match current langCode
              // Also consider if langCode is 'en' and team has 'en'.
              matchesLanguage = team.artistLanguages.any(
                (l) => l.toLowerCase() == langCode.toLowerCase(),
              );
            }

            if (matchesLanguage) {
              loadedTeams.add(team);
            }
          }
        }

        setState(() {
          allWorshipTeams = loadedTeams;
          filteredWorshipTeams = List.from(allWorshipTeams);
          currentLanguage = langCode;
          languageDisplayName = lang;
          isLoading = false;
        });

        if (loadedTeams.isEmpty && teamsData.isNotEmpty) {
          // If filtering removed everything, valid question if we should show all or empty.
          // Following "considering the language" strictly means empty is correct.
          // But maybe we log or set a specific empty message?
        }
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load worship teams';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading worship teams: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _filterWorshipTeams(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredWorshipTeams = List.from(allWorshipTeams);
      } else {
        filteredWorshipTeams =
            allWorshipTeams
                .where(
                  (team) =>
                      team.songname.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (team.artistName?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
      }
    });
  }

  void _navigateToWorshipTeam(WorshipTeamModel team) async {
    final isConnected = await _connectivityManager.isConnected();
    final isPremiumStr = await UserService.getIsPremium();
    final isPremium = isPremiumStr == '1';

    // Check for offline + non-premium (replicating logic)
    if (!isConnected && !isPremium) {
      _showPremiumDialog(isOffline: true);
      return;
    }

    // Navigate to worship team details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorshipTeamDetails(
          worshipTeamId: team.id,
          worshipTeamName: team.artistName ?? 'Unknown Team',
          worshipTeamImage: team.image,
          selectedTeam: team,
        ),
      ),
    );
  }

  void _showPremiumDialog({bool isOffline = false}) {
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
          title: Text(
            isOffline ? 'Offline Access Restricted' : 'Premium Required',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isOffline
                ? 'To access this content while offline, you need a Premium subscription.'
                : 'Access requires a Premium subscription.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Get Premium'),
            ),
          ],
        );
      },
    );
  }

  // Reusing the exact card layout from worship_team.dart for consistency
  Widget _buildWorshipTeamCard(WorshipTeamModel team) {
    return GestureDetector(
      onTap: () => _navigateToWorshipTeam(team),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                child: CachedImageWidget(
                  imageUrl: team.image ?? '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  placeholder: Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  ),
                  errorWidget: Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      team.songname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team.artistName ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBAckgound(
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                      'Worship Teams',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (languageDisplayName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          languageDisplayName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF363636),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search worship songs...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: _filterWorshipTeams,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Count
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        '${filteredWorshipTeams.length} Songs',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 15),

              // Content
              Expanded(
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : errorMessage != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAllWorshipTeams,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : filteredWorshipTeams.isEmpty
                        ? const Center(
                          child: Text(
                            'No songs found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: filteredWorshipTeams.length,
                          itemBuilder: (context, index) {
                            return _buildWorshipTeamCard(
                              filteredWorshipTeams[index],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
