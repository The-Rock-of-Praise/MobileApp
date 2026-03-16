import 'package:flutter/material.dart';
import 'package:lyrics/Service/lyrics_service.dart';
import 'package:lyrics/widgets/main_background.dart';

class LyricsFormat {
  final String title;
  final String value;

  LyricsFormat({required this.title, required this.value});
}

class HowToReadLyrics extends StatefulWidget {
  const HowToReadLyrics({super.key});

  @override
  State<HowToReadLyrics> createState() => _HowToReadLyricsState();
}

class _HowToReadLyricsState extends State<HowToReadLyrics> {
  String? selectedFormat;
  bool isLoading = true;

  final List<LyricsFormat> lyricsFormats = [
    LyricsFormat(title: "Tamil Only", value: "tamil_only"),
    LyricsFormat(
      title: "Tamil + English Transliteration",
      value: "tamil_english",
    ),
    LyricsFormat(
      title: "Tamil + Sinhala Transliteration",
      value: "tamil_sinhala",
    ),
    LyricsFormat(title: "All Three Formats", value: "all_three"),
    LyricsFormat(title: "English Transliteration Only", value: "english_only"),
    LyricsFormat(title: "Sinhala Transliteration Only", value: "sinhala_only"),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentFormat();
  }

  Future<void> _loadCurrentFormat() async {
    try {
      final currentFormat = await HowToReadLyricsService.getLyricsFormat();
      setState(() {
        selectedFormat = currentFormat;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading current format: $e');
      setState(() {
        selectedFormat = 'tamil_only';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'How to Read Lyrics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F), // Dark blue color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MainBAckgound(
        child: SafeArea(
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Description text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Choose how you would like to read song lyrics. Your preference will be saved and applied to all songs.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Options list
                        Expanded(
                          child: ListView.builder(
                            itemCount: lyricsFormats.length,
                            itemBuilder: (context, index) {
                              final format = lyricsFormats[index];
                              final isSelected = selectedFormat == format.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: GestureDetector(
                                  onTap: () => _selectFormat(format.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.white.withOpacity(0.15)
                                              : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.white.withOpacity(0.4)
                                                : Colors.white.withOpacity(0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Radio button indicator
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child:
                                              isSelected
                                                  ? Center(
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration:
                                                          const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  )
                                                  : null,
                                        ),

                                        const SizedBox(width: 16),

                                        // Format title
                                        Expanded(
                                          child: Text(
                                            format.title,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.8),
                                              fontSize: 16,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w500
                                                      : FontWeight.w400,
                                            ),
                                          ),
                                        ),

                                        // Preview indicator for multi-language formats
                                        if (_isMultiLanguageFormat(
                                          format.value,
                                        ))
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getLanguageCount(format.value),
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),

                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Current selection info
                        if (selectedFormat != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.lightBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Current Selection:',
                                      style: TextStyle(
                                        color: Colors.lightBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  HowToReadLyricsService.getFormatTitle(
                                    selectedFormat!,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getFormatDescription(selectedFormat!),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                selectedFormat != null
                                    ? _saveSelectedFormat
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.withOpacity(
                                0.1,
                              ),
                              disabledForegroundColor: Colors.grey.withOpacity(
                                0.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      selectedFormat != null
                                          ? Colors.white.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Preference',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  void _selectFormat(String formatValue) {
    setState(() {
      selectedFormat = formatValue;
    });
  }

  bool _isMultiLanguageFormat(String format) {
    return HowToReadLyricsService.isMultiLanguageFormat(format);
  }

  String _getLanguageCount(String format) {
    final languages = HowToReadLyricsService.getRequiredLanguages(format);
    return '${languages.length} Lang';
  }

  String _getFormatDescription(String format) {
    switch (format) {
      case 'tamil_only':
        return 'You will see lyrics only in Tamil script.';
      case 'tamil_english':
        return 'You will see Tamil lyrics first, followed by English transliteration.';
      case 'tamil_sinhala':
        return 'You will see Tamil lyrics first, followed by Sinhala transliteration.';
      case 'all_three':
        return 'You will see lyrics in Tamil, then Sinhala, then English transliteration.';
      case 'english_only':
        return 'You will see lyrics only in English transliteration.';
      case 'sinhala_only':
        return 'You will see lyrics only in Sinhala transliteration.';
      default:
        return '';
    }
  }

  Future<void> _saveSelectedFormat() async {
    if (selectedFormat == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
      );

      // Save the preference
      await HowToReadLyricsService.saveLyricsFormat(selectedFormat!);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Preference saved: ${HowToReadLyricsService.getFormatTitle(selectedFormat!)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(selectedFormat);
        }
      });
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Failed to save preference. Please try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
