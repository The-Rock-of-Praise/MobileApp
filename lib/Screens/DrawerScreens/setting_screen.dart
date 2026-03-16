import 'package:flutter/material.dart';
import 'package:lyrics/Service/setting_service.dart' show FontSettingsService;
import 'package:lyrics/Service/color_service.dart';
import 'package:lyrics/Service/theme_service.dart'; // Add this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'Dark'; // Light, Dark, or Automatic
  bool isAutomaticTheme = false;
  bool isBoldText = false;
  bool notificationsEnabled = true;
  double lyricsFontSize = 18.0;
  Color selectedLyricsColor = Colors.white; // Add this for color selection

  bool _hasChanges = false;

  void _markAsChanged() {
    _hasChanges = true;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load font settings
      final fontSize = await FontSettingsService.getFontSize();
      final boldText = await FontSettingsService.getBoldText();
      final lyricsColor = await ColorService.getColor(); // Load color

      final theme = await ThemeService.getTheme();
      final automaticTheme = await ThemeService.getAutomaticTheme();

      setState(() {
        lyricsFontSize = fontSize;
        isBoldText = boldText;
        selectedLyricsColor = lyricsColor; // Set color
        selectedTheme = theme;
        isAutomaticTheme = automaticTheme;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveTheme(String theme) async {
    _markAsChanged();
    await ThemeService.saveTheme(theme);

    // Auto-save appropriate lyrics color based on theme
    if (theme == 'Light') {
      await _saveLyricsColor(Colors.black);
    } else if (theme == 'Dark') {
      await _saveLyricsColor(Colors.white);
    }

    setState(() {
      selectedTheme = theme;
    });
  }

  Future<void> _saveAutomaticTheme(bool isAutomatic) async {
    _markAsChanged();
    await ThemeService.saveAutomaticTheme(isAutomatic);

    // Auto-save lyrics color based on system theme if automatic is enabled
    if (isAutomatic) {
      final systemBrightness =
          WidgetsBinding.instance.window.platformBrightness;
      final Color autoColor =
          systemBrightness == Brightness.dark ? Colors.white : Colors.black;
      await _saveLyricsColor(autoColor);
    }

    setState(() {
      isAutomaticTheme = isAutomatic;
    });
  }

  Future<void> _saveFontSize(double fontSize) async {
    await FontSettingsService.saveFontSize(fontSize);
    _markAsChanged();
    setState(() {
      lyricsFontSize = fontSize;
    });
  }

  Future<void> _saveBoldText(bool isBold) async {
    _markAsChanged();
    await FontSettingsService.saveBoldText(isBold);
    setState(() {
      isBoldText = isBold;
    });
  }

  Future<void> _saveLyricsColor(Color color) async {
    _markAsChanged();
    await ColorService.saveColor(color);
    setState(() {
      selectedLyricsColor = color;
    });
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          title: Text(
            'Select Font Size',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                FontSettingsService.fontSizeOptions.entries.map((entry) {
                  return ListTile(
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        color: selectedLyricsColor, // Use selected color
                        fontSize: entry.value,
                        fontWeight:
                            isBoldText ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    leading: Radio<double>(
                      value: entry.value,
                      groupValue: lyricsFontSize,
                      onChanged: (value) {
                        Navigator.pop(context);
                        if (value != null) {
                          _saveFontSize(value);
                        }
                      },
                      activeColor: Colors.blue,
                    ),
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  void _showColorPaletteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          title: Text(
            'Select Lyrics Color',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: ColorService.colorPalette.length,
              itemBuilder: (context, index) {
                final color = ColorService.colorPalette[index];
                final colorName = ColorService.colorNames[index];
                final isSelected = selectedLyricsColor.value == color.value;

                return GestureDetector(
                  onTap: () {
                    _saveLyricsColor(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color:
                                  color == Colors.white
                                      ? Colors.black
                                      : Colors.white,
                              size: 24,
                            )
                            : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E3A5F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF0F1B2E)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16),
          children: [
            // Theme Selection Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Phone mockups
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Light theme phone
                      _buildPhoneMockup(
                        isLight: true,
                        isSelected: selectedTheme == 'Light',
                      ),
                      // Dark theme phone
                      _buildPhoneMockup(
                        isLight: false,
                        isSelected: selectedTheme == 'Dark',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Theme options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Light option
                      Column(
                        children: [
                          Text(
                            'Light',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Radio<String>(
                            value: 'Light',
                            groupValue: isAutomaticTheme ? null : selectedTheme,
                            onChanged:
                                isAutomaticTheme
                                    ? null
                                    : (value) {
                                      if (value != null) {
                                        _saveTheme(value);
                                      }
                                    },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      // Dark option
                      Column(
                        children: [
                          Text(
                            'Dark',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Radio<String>(
                            value: 'Dark',
                            groupValue: isAutomaticTheme ? null : selectedTheme,
                            onChanged:
                                isAutomaticTheme
                                    ? null
                                    : (value) {
                                      if (value != null) {
                                        _saveTheme(value);
                                      }
                                    },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Automatic toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Automatic',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: isAutomaticTheme,
                        onChanged: (value) {
                          _saveAutomaticTheme(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Lyrics Section Header
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Lyrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Font Size Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Font Size Selection
                  InkWell(
                    onTap: _showFontSizeDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Font Size',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              FontSettingsService.getFontSizeLabel(
                                lyricsFontSize,
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Preview text
                            Text(
                              'Aa',
                              style: TextStyle(
                                color:
                                    selectedLyricsColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : selectedLyricsColor,
                                fontSize: lyricsFontSize,
                                fontWeight:
                                    isBoldText
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey.shade400,
                    thickness: 1,
                    height: 24,
                  ),
                  // Bold Text Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bold Text',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: isBoldText,
                        onChanged: (value) {
                          _saveBoldText(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Color Selection Card (Replaced Brightness)
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lyrics Color',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            ColorService.getColorName(selectedLyricsColor),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Color preview circle
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: selectedLyricsColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Tap to change button
                          GestureDetector(
                            onTap: _showColorPaletteDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Color palette preview (first 8 colors)
                  Row(
                    children:
                        ColorService.colorPalette
                            .take(8)
                            .map(
                              (color) => Container(
                                margin: EdgeInsets.only(right: 8),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        selectedLyricsColor.value == color.value
                                            ? Colors.blue
                                            : Colors.grey.shade400,
                                    width:
                                        selectedLyricsColor.value == color.value
                                            ? 2
                                            : 1,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),

            // Notifications Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get updates about new songs and features',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blue,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneMockup({required bool isLight, required bool isSelected}) {
    return Container(
      width: 60,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Status bar
            Container(
              height: 8,
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content area
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
