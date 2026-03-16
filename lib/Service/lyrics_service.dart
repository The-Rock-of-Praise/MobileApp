import 'package:lyrics/Service/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service to handle "How to Read Lyrics" preferences
class HowToReadLyricsService {
  static const String _lyricsFormatKey = 'lyrics_reading_format';
  static const String _defaultFormat = 'tamil_only'; // Global fallback

  // Save the selected lyrics reading format
  static Future<void> saveLyricsFormat(String format) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lyricsFormatKey, format);
      print('Lyrics format saved: $format');
    } catch (e) {
      print('Error saving lyrics format: $e');
    }
  }

  // Get the saved lyrics reading format with language-based default
  static Future<String> getLyricsFormat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFormat = prefs.getString(_lyricsFormatKey);

      // If no format is saved, determine default based on selected language
      if (savedFormat == null) {
        final defaultFormat = await _getLanguageBasedDefault();
        // Save the determined default for future use
        await saveLyricsFormat(defaultFormat);
        return defaultFormat;
      }

      return savedFormat;
    } catch (e) {
      print('Error loading lyrics format: $e');
      return _defaultFormat;
    }
  }

  // Determine default lyrics format based on selected language
  static Future<String> _getLanguageBasedDefault() async {
    try {
      final selectedLanguage = await LanguageService.getLanguage();

      switch (selectedLanguage.toLowerCase()) {
        case 'tamil':
          return 'tamil_only';
        case 'sinhala':
          return 'sinhala_only';
        case 'english':
          return 'english_only';
        default:
          return 'tamil_only'; // Default fallback
      }
    } catch (e) {
      print('Error determining language-based default: $e');
      return _defaultFormat;
    }
  }

  // Get default format for a specific language (useful for language switching)
  static String getDefaultFormatForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'tamil':
        return 'tamil_only';
      case 'sinhala':
        return 'sinhala_only';
      case 'english':
        return 'english_only';
      default:
        return 'tamil_only';
    }
  }

  // Update lyrics format when language changes (call this from language change handler)
  static Future<void> updateFormatOnLanguageChange(String newLanguage) async {
    try {
      // Get current format
      final prefs = await SharedPreferences.getInstance();
      final currentFormat = prefs.getString(_lyricsFormatKey);

      // Only update if no custom format has been set
      // (You can modify this logic based on your app's requirements)
      if (currentFormat == null || _isDefaultFormat(currentFormat)) {
        final newDefaultFormat = getDefaultFormatForLanguage(newLanguage);
        await saveLyricsFormat(newDefaultFormat);
        print(
          'Lyrics format updated to $newDefaultFormat for language: $newLanguage',
        );
      }
    } catch (e) {
      print('Error updating format on language change: $e');
    }
  }

  // Check if the current format is a default format (not custom selected)
  static bool _isDefaultFormat(String format) {
    return ['tamil_only', 'sinhala_only', 'english_only'].contains(format);
  }

  // Reset to language-based default (useful for settings reset)
  static Future<void> resetToLanguageDefault() async {
    try {
      final defaultFormat = await _getLanguageBasedDefault();
      await saveLyricsFormat(defaultFormat);
      print('Lyrics format reset to language-based default: $defaultFormat');
    } catch (e) {
      print('Error resetting to language default: $e');
    }
  }

  // Get required language codes based on selected format
  static List<String> getRequiredLanguages(String format) {
    switch (format) {
      case 'tamil_only':
        return ['ta'];
      case 'tamil_english':
        return ['ta', 'en'];
      case 'tamil_sinhala':
        return ['ta', 'si'];
      case 'all_three':
        return ['ta', 'si', 'en'];
      case 'english_only':
        return ['en'];
      case 'sinhala_only':
        return ['si'];
      default:
        return ['ta']; // Default to Tamil
    }
  }

  // Get display order for languages (for multi-language formats)
  static List<String> getLanguageDisplayOrder(String format) {
    switch (format) {
      case 'tamil_english':
        return ['ta', 'en'];
      case 'tamil_sinhala':
        return ['ta', 'si']; // Tamil first, then Sinhala as requested
      case 'all_three':
        return ['ta', 'si', 'en']; // Tamil, Sinhala, then English
      case 'tamil_only':
        return ['ta'];
      case 'english_only':
        return ['en'];
      case 'sinhala_only':
        return ['si'];
      default:
        return ['ta'];
    }
  }

  // Get language display name
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'Tamil';
      case 'si':
        return 'Sinhala';
      case 'en':
        return 'English Transliteration';
      default:
        return languageCode.toUpperCase();
    }
  }

  // Check if format requires multiple languages
  static bool isMultiLanguageFormat(String format) {
    return ['tamil_english', 'tamil_sinhala', 'all_three'].contains(format);
  }

  // Get format title for display
  static String getFormatTitle(String format) {
    switch (format) {
      case 'tamil_only':
        return 'Tamil Only';
      case 'tamil_english':
        return 'Tamil + English Transliteration';
      case 'tamil_sinhala':
        return 'Tamil + Sinhala Transliteration';
      case 'all_three':
        return 'All Three Formats';
      case 'english_only':
        return 'English Transliteration Only';
      case 'sinhala_only':
        return 'Sinhala Transliteration Only';
      default:
        return 'Tamil Only';
    }
  }
}
