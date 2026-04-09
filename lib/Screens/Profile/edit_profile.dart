import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/OfflineService/offline_user_service.dart';
import 'package:intl/intl.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final OfflineUserService _userService = OfflineUserService();

  String? _apiDateOfBirth;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  List<String> selectedInterests = [];
  List<String> availableInterests = [
    'Worship', 'Gospel', 'Hymns', 'Contemporary', 'Instrumental', 'Choir',
    'Praise & Worship', 'Kids Songs', 'Devotional', 'Tamil Songs', 'English Songs',
    'Sinhala Songs', 'Classical', 'Rock', 'Jazz', 'Blues', 'Country', 'Pop',
    'Folk', 'Spiritual', 'Meditation', 'Christian Rock', 'Acoustic', 'Orchestra',
  ];

  bool _isLoading = true;
  bool _isUpdating = false;
  UserModel? _currentUser;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Attempt to load user profile. For brand-new Google/Apple accounts, the
      // first fetch may fail if data hasn't fully propagated yet — retry once.
      Map<String, dynamic> userResult = await _userService.getCurrentUserProfile();
      if (!userResult['success']) {
        print('DEBUG: First profile fetch failed, retrying once after delay...');
        await Future.delayed(const Duration(milliseconds: 600));
        userResult = await _userService.getCurrentUserProfile();
      }

      if (userResult['success'] && userResult['user'] != null) {
        _currentUser = userResult['user'] as UserModel;
        _nameController.text = _currentUser!.fullname;
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phonenumber ?? '';
      }

      final userId = await UserService.getUserID();
      final profileResult = await _userService.getFullProfile(userId.toString());

      if (profileResult['success'] && profileResult['profile'] != null) {
        final profile = profileResult['profile'];
        print('DEBUG: Full Profile loaded in EditProfile: $profile');
        final innerProfile = profile['profile'];
        
        if (innerProfile != null) {
          _countryController.text = innerProfile['country'] ?? '';

          if (innerProfile['date_of_birth'] != null) {
            try {
              DateTime dob = DateTime.parse(innerProfile['date_of_birth']);
              _dobController.text = DateFormat('dd MMM yyyy').format(dob);
              _apiDateOfBirth = DateFormat('yyyy-MM-dd').format(dob);
            } catch (e) {
              print('Date parse error: $e');
            }
          }

          _genderController.text = innerProfile['gender'] ?? 'Male';
          _languageController.text = innerProfile['preferred_language'] ?? 'English';
          _bioController.text = innerProfile['bio'] ?? '';
          _profileImageUrl = innerProfile['profile_image'];
        }
        selectedInterests = List<String>.from(profile['interests'] ?? []);
      }
    } catch (e) {
      print('DEBUG: EditProfile load error: $e');
      _showSnackBar('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    // Guard against double-submit
    if (_isUpdating) return;

    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showSnackBar('Name and Email are required');
      return;
    }

    setState(() => _isUpdating = true);
    
    // Show a persistent loading snackbar if it's a slow operation
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 20),
            Text('Updating profile... Please wait'),
          ],
        ),
        duration: Duration(seconds: 30), // Will be dismissed manually
      ),
    );

    try {
      // Step 1: Upload profile image if a new one was selected
      if (_selectedImage != null) {
        final userId = await UserService.getUserID();
        if (userId.isEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showSnackBar('Session expired. Please log in again.');
          return;
        }

        try {
          print('DEBUG: Attempting to upload image for userId: $userId');
          final uploadResult = await _userService.uploadProfileImage(
            int.parse(userId),
            _selectedImage!,
          );
          
          if (uploadResult['success']) {
            _profileImageUrl = uploadResult['imageUrl'];
            print('DEBUG: Image upload success: $_profileImageUrl');
          } else {
            print('DEBUG: Image upload failed: ${uploadResult['message']}');
            _showSnackBar('Image upload failed: ${uploadResult['message'] ?? 'Unknown error'}. Saving other details...');
          }
        } catch (e) {
          print('DEBUG: Image upload exception: $e');
          _showSnackBar('Connection error while uploading image. Saving other details...');
        }
      }

      // Step 2: Update basic user info (name, email, phone)
      try {
        final basicUpdate = await _userService.updateCurrentUserProfile(
          fullname: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phonenumber: _phoneController.text.trim(),
        );
        if (!basicUpdate['success']) {
           print('DEBUG: basicUpdate failed: ${basicUpdate['message']}');
        }
      } catch (e) {
        print('DEBUG: updateCurrentUserProfile error: $e');
      }

      // Step 3: Update extended profile details
      final userId = await UserService.getUserID();
      final profileResult = await _userService.updateFullProfile(
        userId: userId,
        country: _countryController.text.trim(),
        dateOfBirth: _apiDateOfBirth,
        gender: _genderController.text,
        preferredLanguage: _languageController.text,
        bio: _bioController.text.trim(),
        profileImage: _profileImageUrl,
        interests: selectedInterests,
      );

      ScaffoldMessenger.of(context).clearSnackBars();

      if (profileResult['success']) {
        _showSnackBar('Profile updated successfully!');
        if (mounted) {
          // Give users a moment to see the success message
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      } else {
        _showSnackBar('Could not save profile details: ${profileResult['message'] ?? 'Please try again.'}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnackBar('A system error occurred: ${e.toString()}');
      print('DEBUG: _saveProfile unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: message.contains('successfully') ? Colors.green : Colors.red),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    // Only upload in _saveProfile to avoid duplicate calls and potential errors
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.blue, onSurface: Colors.white),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd MMM yyyy').format(pickedDate);
        _apiDateOfBirth = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isUpdating
              ? const Padding(padding: EdgeInsets.all(15.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.done_all, color: Colors.blueAccent, size: 28), onPressed: _saveProfile),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E272E), Color(0xFF0F1418)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                child: Column(
                  children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                              child: (_selectedImage == null && _profileImageUrl == null) ? const Icon(Icons.person, size: 60, color: Colors.white24) : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    // Glassmorphism Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _buildModernField(Icons.person_outline, "Name", _nameController),
                          _buildDivider(),
                          _buildModernField(Icons.email_outlined, "Email", _emailController),
                          _buildDivider(),
                          _buildModernField(Icons.phone_outlined, "Phone", _phoneController),
                          _buildDivider(),
                          _buildModernField(Icons.public, "Country", _countryController),
                          _buildDivider(),
                          _buildModernClickableField(Icons.cake_outlined, "Date of Birth", _dobController, _selectDate, readOnly: true),
                          _buildDivider(),
                          _buildGenderDropdown(),
                          _buildDivider(),
                          _buildModernField(Icons.language, "Language", _languageController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Interests Section
                    _buildGlassSection("Interests", Icons.interests_outlined, _buildInterestsChips()),
                    const SizedBox(height: 20),

                    // Bio Section
                    _buildGlassSection("Bio", Icons.notes, Text(_bioController.text.isEmpty ? "No bio provided" : _bioController.text, style: const TextStyle(color: Colors.white70))),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.transgender, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Gender", style: TextStyle(color: Colors.white54, fontSize: 12)),
                DropdownButtonFormField<String>(
                  value: ['Male', 'Female', 'Other'].contains(_genderController.text) ? _genderController.text : 'Male',
                  dropdownColor: const Color(0xFF1E272E),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 5)),
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _genderController.text = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(IconData icon, String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernClickableField(IconData icon, String label, TextEditingController controller, VoidCallback onTap, {bool readOnly = false}) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        ignoring: readOnly, // Still want the InkWell tap but not underlying TextField tap
        child: _buildModernField(icon, label, controller, readOnly: readOnly),
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.1), thickness: 1, height: 20);

  Widget _buildGlassSection(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, color: Colors.blueAccent, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const Icon(Icons.edit, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 15),
          content,
        ],
      ),
    );
  }

  Widget _buildInterestsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selectedInterests.map((interest) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
        child: Text(interest, style: const TextStyle(color: Colors.white, fontSize: 12)),
      )).toList(),
    );
  }
}