import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lyrics/Controllers/profile_controller.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:lyrics/Screens/AuthScreens/login_page.dart';
import 'package:lyrics/Screens/Profile/edit_profile.dart';
import 'package:lyrics/Screens/Profile/delete_account_screen.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // BackdropFilter use karanna meka ona

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileController profileController = Get.find<ProfileController>();
  final OfflineUserService _userService = OfflineUserService();
  Map<String, dynamic>? _profileDetails;
  bool _isLoading = true;
  String _preferredLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    await _loadProfileData();
    await _loadPreferredLanguage();
    await profileController.refreshStatus();
    setState(() => _isLoading = false);
  }

  Future<void> _loadPreferredLanguage() async {
    final language = await LanguageService.getLanguage();
    setState(() => _preferredLanguage = language);
  }

  // Removed loadPremiumStatus as it's now handled by profileController.refreshStatus()

  Future<void> _loadProfileData() async {
    try {
      final userId = await UserService.getUserID();
      if (userId.isNotEmpty) {
        print('Profile: Fetching data for userId: $userId');
        final profileResult = await _userService.getFullProfile(userId);
        print('Profile: Result success=${profileResult['success']} source=${profileResult['source']}');
        if (profileResult['success']) {
          setState(() {
            _profileDetails = profileResult['profile'] as Map<String, dynamic>?;
          });
          print('Profile: Data loaded: ${json.encode(_profileDetails)}');
        }
      }
    } catch (e) {
      print('Profile: Error loading data: $e');
    }
  }

  String _getProfileValue(String key, String defaultValue) {
    if (_profileDetails == null) return defaultValue;
    
    // First try the nested profile object
    if (_profileDetails!['profile'] != null && _profileDetails!['profile'] is Map) {
      final profile = _profileDetails!['profile'] as Map;
      if (profile[key] != null) return profile[key].toString();
    }
    
    // Fallback to top level
    return _profileDetails![key]?.toString() ?? defaultValue;
  }

  String _formatDate(String dateStr) {
    if (dateStr == 'Not provided' || dateStr == 'N/A' || dateStr.isEmpty) return dateStr;
    try {
      // Backend format is usually YYYY-MM-DD
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Glass effect eka penna background eka dark wenna ona
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MainBAckgound(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                child: Column(
                  children: [
                    Builder(builder: (context) {
                      print('DEBUG: Building Profile with data: $_profileDetails');
                      return const SizedBox.shrink();
                    }),
                    _buildGlassCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Cover Image Area with Profile Pic
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/coverImage.jpeg'), // Me wage smoke image ekak danna
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Obx(() => Positioned(
                    bottom: -40,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: profileController.isPremium.value 
                          ? const LinearGradient(
                              colors: [Colors.orangeAccent, Colors.purpleAccent, Colors.blueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                        color: profileController.isPremium.value ? null : Colors.blueAccent, 
                        shape: BoxShape.circle,
                        boxShadow: profileController.isPremium.value ? [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _getProfileValue('profile_image', '').isNotEmpty && _getProfileValue('profile_image', '').startsWith('http')
                            ? NetworkImage(_getProfileValue('profile_image', '')) 
                            : null,
                        child: _getProfileValue('profile_image', '').isEmpty 
                            ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 50),

              // Name & Email (API data)
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _profileDetails?['fullname'] ?? 'No name',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (profileController.isPremium.value) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.redAccent]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'PRO', 
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                      ),
                    ),
                  ],
                ],
              )),
              Text(
                _profileDetails?['email'] ?? 'No email',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 25),

              // Account Type & Language Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Obx(() => _buildTopInfoBox(profileController.isPremium.value ? "Pro" : "Free", "Account")),
                    const SizedBox(width: 15),
                    _buildTopInfoBox(_preferredLanguage, "Language"),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Info List (API Details)
              _buildInfoTile(Icons.phone_iphone, "Phone", _profileDetails?['phonenumber'] ?? 'Not provided'),
              _buildInfoTile(Icons.fingerprint, "User ID", _profileDetails?['id']?.toString() ?? 'N/A'),
              _buildInfoTile(Icons.public, "Country", _getProfileValue('country', 'Not Provided')),
              _buildInfoTile(Icons.cake, "Birthday", _formatDate(_getProfileValue('date_of_birth', 'Not provided'))),
              _buildInfoTile(Icons.face, "Gender", _getProfileValue('gender', 'Not specified')),

              const SizedBox(height: 20),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfile()));
                          if (result == true) {
                            _refreshProfile();
                          }
                        },
                        child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildSquareButton(Icons.logout, Colors.redAccent.withOpacity(0.2), Colors.redAccent, () async {
                       final prefs = await SharedPreferences.getInstance();
                       await prefs.clear();
                       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              _buildDeleteButton(context), // Me thiyenne oya dila thibba delete function eka
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (_profileDetails != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeleteAccountScreen(userDetails: _profileDetails!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile details not loaded yet')),
          );
        }
      },
      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
      label: const Text(
        "Delete Account",
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w400),
      ),
    );
  }

  Widget _buildTopInfoBox(String title, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSquareButton(IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}