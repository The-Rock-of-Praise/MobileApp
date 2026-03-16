import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static const String _automaticThemeKey = 'automatic_theme';

  // Save theme selection
  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // Get saved theme
  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'Dark';
  }

  // Save automatic theme setting
  static Future<void> saveAutomaticTheme(bool isAutomatic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_automaticThemeKey, isAutomatic);
  }

  // Get automatic theme setting
  static Future<bool> getAutomaticTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_automaticThemeKey) ?? false;
  }

  // Get drawer background color based on theme
  static Color getDrawerBackgroundColor(String theme, bool isAutomatic) {
    if (isAutomatic) {
      // Use system theme
      return WidgetsBinding.instance.window.platformBrightness ==
              Brightness.dark
          ? Colors
              .black // Dark theme drawer
          : Colors.white; // Light theme drawer
    }

    switch (theme) {
      case 'Light':
        return Colors.white; // Light gray for light theme
      case 'Dark':
      default:
        return Colors.black; // Current dark gray
    }
  }

  // Get profile header color based on theme
  static Color getProfileHeaderColor(String theme, bool isAutomatic) {
    if (isAutomatic) {
      return WidgetsBinding.instance.window.platformBrightness ==
              Brightness.dark
          ? Color(0xFF555555)
          : Color(0xFFBBBBBB);
    }

    switch (theme) {
      case 'Light':
        return Color(0xFFBBBBBB);
      case 'Dark':
      default:
        return Color(0xFF555555);
    }
  }
}
