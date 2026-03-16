import 'package:flutter/material.dart';
import 'package:lyrics/Service/language_service.dart';
import 'package:lyrics/widgets/main_background.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'English'; // Default fallback
  bool isLoading = true;

  final List<String> languages = ['Sinhala', 'English', 'Tamil'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedLanguage();
    });
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final savedLanguage = await LanguageService.getLanguage();
      print('Saved Language: $savedLanguage');
      if (mounted) {
        setState(() {
          selectedLanguage = savedLanguage;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading language: ${e.toString()}')),
      );
    }
  }

  Future<void> _changeLanguage(String language) async {
    if (language == selectedLanguage) return;

    setState(() => selectedLanguage = language);
    try {
      await LanguageService.saveLanguage(language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to $language'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('error $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save language: ${e.toString()}')),
      );
      // Revert if save fails
      LanguageService.getLanguage().then((lang) {
        if (mounted) {
          setState(() => selectedLanguage = lang);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Language',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(selectedLanguage),
        ),
      ),
      body: MainBAckgound(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      const SizedBox(height: 20),
                      ...languages.map(
                        (language) => _buildLanguageTile(language),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String language) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _changeLanguage(language),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color:
                selectedLanguage == language
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                selectedLanguage == language
                    ? Border.all(color: Colors.white.withOpacity(0.2))
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      selectedLanguage == language
                          ? FontWeight.w600
                          : FontWeight.w400,
                ),
              ),
              if (selectedLanguage == language)
                const Icon(Icons.check, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
