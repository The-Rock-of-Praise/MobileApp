import 'package:shared_preferences/shared_preferences.dart';

// Service to handle font settings preferences
class FontSettingsService {
  static const String _fontSizeKey = 'lyrics_font_size';
  static const String _boldTextKey = 'lyrics_bold_text';
  static const double _defaultFontSize = 12.0;
  static const bool _defaultBoldText = false;

  // Font size options
  static const Map<String, double> fontSizeOptions = {
    'Small': 12.0,
    'Medium': 18.0,
    'Large': 20.0,
    'Extra Large': 24.0,
  };

  // Save the selected font size
  static Future<void> saveFontSize(double fontSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, fontSize);
      print('Font size saved: $fontSize');
    } catch (e) {
      print('Error saving font size: $e');
    }
  }

  // Get the saved font size
  static Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    } catch (e) {
      print('Error loading font size: $e');
      return _defaultFontSize;
    }
  }

  // Save the bold text setting
  static Future<void> saveBoldText(bool isBold) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_boldTextKey, isBold);
      print('Bold text setting saved: $isBold');
    } catch (e) {
      print('Error saving bold text setting: $e');
    }
  }

  // Get the saved bold text setting
  static Future<bool> getBoldText() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_boldTextKey) ?? _defaultBoldText;
    } catch (e) {
      print('Error loading bold text setting: $e');
      return _defaultBoldText;
    }
  }

  // Get font size label for display
  static String getFontSizeLabel(double fontSize) {
    for (var entry in fontSizeOptions.entries) {
      if (entry.value == fontSize) {
        return entry.key;
      }
    }
    return 'Custom';
  }

  // Get adjusted font size for different languages
  static double getAdjustedFontSize(double baseFontSize, String languageCode) {
    switch (languageCode) {
      case 'ta':
        return baseFontSize + 2; // Larger for Tamil script
      case 'si':
        return baseFontSize + 1; // Slightly larger for Sinhala script
      case 'en':
        return baseFontSize; // Standard for English
      default:
        return baseFontSize;
    }
  }
}
