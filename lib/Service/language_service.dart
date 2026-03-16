import 'package:flutter/material.dart';
import 'package:lyrics/Service/lyrics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin LanguageAwareMixin<T extends StatefulWidget> on State<T> {
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkLanguageChange();
  }

  /// Initialize the current language
  Future<void> _initializeLanguage() async {
    _currentLanguage = await LanguageService.getLanguage();
  }

  /// Check if language has changed and call refresh if it has
  Future<void> _checkLanguageChange() async {
    final newLanguage = await LanguageService.getLanguage();
    if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;

      // Update lyrics format when language changes
      await HowToReadLyricsService.updateFormatOnLanguageChange(newLanguage);

      onLanguageChanged(newLanguage);
    }
  }

  /// Called when language changes - override this in your widget
  void onLanguageChanged(String newLanguage) {
    // Override this method in your widget to handle language changes
    print('Language changed to: $newLanguage');
  }

  /// Call this method from your language selection screen after saving
  static Future<void> notifyLanguageChange(String newLanguage) async {
    // Update lyrics format when language is explicitly changed
    await HowToReadLyricsService.updateFormatOnLanguageChange(newLanguage);
    // This is a simple approach. For more sophisticated apps, consider using
    // state management solutions like Provider, Bloc, or Riverpod
  }
}

class LanguageService {
  static const String _languageKey = 'selected_language';

  static Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);

      // Update lyrics format when language is saved
      await HowToReadLyricsService.updateFormatOnLanguageChange(language);
    } catch (e) {
      print('Error saving language: $e');
      // You might want to add a fallback storage mechanism here
    }
  }

  static Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'English';
    } catch (e) {
      print('Error loading language: $e');
      return 'English'; // Default fallback
    }
  }

  static String getLanguageCode(String language) {
    switch (language) {
      case 'Sinhala':
        return 'si';
      case 'Tamil':
        return 'ta';
      case 'English':
      default:
        return 'en';
    }
  }
}
