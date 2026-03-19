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
      final userResult = await _userService.getCurrentUserProfile();
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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Name and Email are required');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      if (_selectedImage != null) {
        final userId = await UserService.getUserID();
        final uploadResult = await _userService.uploadProfileImage(int.parse(userId.toString()), _selectedImage!);
        if (uploadResult['success']) _profileImageUrl = uploadResult['imageUrl'];
      }

      await _userService.updateCurrentUserProfile(
        fullname: _nameController.text,
        email: _emailController.text,
        phonenumber: _phoneController.text,
      );

      final userId = await UserService.getUserID();
      final profileResult = await _userService.updateFullProfile(
        userId: userId,
        country: _countryController.text,
        dateOfBirth: _apiDateOfBirth,
        gender: _genderController.text,
        preferredLanguage: _languageController.text,
        bio: _bioController.text,
        profileImage: _profileImageUrl,
        interests: selectedInterests,
      );

      if (profileResult['success']) {
        _showSnackBar('Profile updated successfully!');
        Navigator.of(context).pop(true); // Auto back on success
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isUpdating = false);
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