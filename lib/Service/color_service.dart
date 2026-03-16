import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin ColorAwareMixin<T extends StatefulWidget> on State<T> {
  Color? _currentColor;

  @override
  void initState() {
    super.initState();
    _initializeColor();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkColorChange();
  }

  /// Initialize the current color
  Future<void> _initializeColor() async {
    _currentColor = await ColorService.getColor();
  }

  /// Check if color has changed and call refresh if it has
  Future<void> _checkColorChange() async {
    final newColor = await ColorService.getColor();
    if (_currentColor != newColor) {
      _currentColor = newColor;
      onColorChanged(newColor);
    }
  }

  /// Called when color changes - override this in your widget
  void onColorChanged(Color newColor) {
    // Override this method in your widget to handle color changes
    print('Color changed to: ${newColor.toString()}');
  }

  /// Call this method from your color selection screen after saving
  static Future<void> notifyColorChange() async {
    // This is a simple approach. For more sophisticated apps, consider using
    // state management solutions like Provider, Bloc, or Riverpod
  }
}

class ColorService {
  static const String _colorKey = 'selected_lyrics_color';

  // Predefined color palette
  static const List<Color> colorPalette = [
    Colors.white,
    Colors.black,
    Color(0xFFFFD700), // Gold
    Color(0xFF87CEEB), // Sky Blue
    Color(0xFF98FB98), // Pale Green
    Color(0xFFFFB6C1), // Light Pink
    Color(0xFFDDA0DD), // Plum
    Color(0xFFFFA500), // Orange
    Color(0xFF20B2AA), // Light Sea Green
    Color(0xFFFFE4E1), // Misty Rose
    Color(0xFFB0E0E6), // Powder Blue
    Color(0xFFD3D3D3), // Light Gray
    Color(0xFFFFDAB9), // Peach Puff
  ];

  static const List<String> colorNames = [
    'White',
    'Black',
    'Gold',
    'Sky Blue',
    'Pale Green',
    'Light Pink',
    'Plum',
    'Orange',
    'Light Sea Green',
    'Misty Rose',
    'Powder Blue',
    'Light Gray',
    'Peach Puff',
  ];

  static Future<void> saveColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_colorKey, color.value);
    } catch (e) {
      print('Error saving color: $e');
      // You might want to add a fallback storage mechanism here
    }
  }

  static Future<Color> getColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_colorKey);
      if (colorValue != null) {
        return Color(colorValue);
      }
      return Colors.white; // Default color
    } catch (e) {
      print('Error loading color: $e');
      return Colors.white; // Default fallback
    }
  }

  static String getColorName(Color color) {
    final index = colorPalette.indexWhere((c) => c.value == color.value);
    if (index != -1 && index < colorNames.length) {
      return colorNames[index];
    }
    return 'Custom';
  }

  static Color? getColorByName(String name) {
    final index = colorNames.indexOf(name);
    if (index != -1 && index < colorPalette.length) {
      return colorPalette[index];
    }
    return null;
  }
}
