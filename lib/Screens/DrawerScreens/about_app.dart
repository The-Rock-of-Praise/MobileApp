import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:url_launcher/url_launcher.dart';

// Assuming you have this import for your background
// import 'package:lyrics/Const/const.dart';
// import 'package:lyrics/widgets/main_background.dart';

class AboutApp extends StatefulWidget {
  const AboutApp({super.key});

  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external browser/app
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // You could show a snackbar or dialog here to inform the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About This App',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF173857),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MainBAckgound(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Main heading
              const Text(
                'About This App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // English content
              _buildSection([
                'Greetings in our Lord Jesus Christ!',
                '',
                'Welcome to The Rock of Praise! We are delighted that you have chosen to explore this worship lyrics app. Our prayer is that it enriches your worship, inspires your heart, and blesses your spiritual journey.',
                '',
                'This app features 5,000+ Christian songs in English, Sinhala, and Tamil, thoughtfully designed for simplicity, beauty, and ease of use. It is available on the Google Play Store, Apple App Store, and Huawei AppGallery, accessible across smartphones, tablets, and iPads.',
                '',
                'With the Pro Version, you can access songs offline and enjoy enhanced features, allowing you to worship anytime, anywhere, whether at home, in church, or in remote locations. The app serves churches, choirs, youth teams, and individual believers worldwide, helping you lead worship, encourage others, and deepen your personal praise.',
                '',
                '"Oh come, let us sing to the Lord; let us make a joyful noise to the rock of our salvation!" – Psalm 95:1',
                '',
                'Praising and worshipping God is one of the most sacred and joyous acts we can perform. As you use this app, remember that we are all children of God and heirs of His Kingdom, united in worship across the world.',
                '',
                'All songs remain the property of their rightful owners and songwriters. We are grateful for their contributions and extend thanks to our dedicated team who helped make this app a reality.',
              ]),

              const SizedBox(height: 30),
              const Divider(color: Colors.white54),
              const SizedBox(height: 20),

              // Sinhala content
              _buildSection([
                'මෙම යෙදුම ගැන,',
                '',
                'අපගේ ස්වාමීන් වන ජේසුස් ක්‍රිස්තුස් වහන්සේ තුළ සුභ පැතුම්!',
                '',
                'නමස්කාරයේ අග්‍රස්ථානය යෙදවුම වෙත සාදරයෙන් පිළිගනිමු! මෙම නමස්කාර පද රචනා යෙදුම ගවේෂණය කිරීමට ඔබ තෝරා ගැනීම ගැන අපි සතුටු වෙමු. එය ඔබගේ නමස්කාරය පොහොසත් කිරීමට, ඔබේ හදවතට ආශිර්වාදය ලබා දීමට සහ ඔබේ අධ්‍යාත්මික ගමනට ආශීර්වාද කිරීමට අපගේ යාච්ඤාවයි.',
                '',
                'මෙම යෙදුම ඉංග්‍රීසි, සිංහල සහ දෙමළ භාෂාවෙන් ක්‍රිස්තියානි ගීතිකා 5,000+ ක් අඩංගු වන අතර සරල බව, අලංකාරය සහ භාවිතයේ පහසුව සඳහා කල්පනාකාරීව නිර්මාණය කර ඇත. එය Google Play Store, Apple App Store සහ Huawei AppGallery හි ඇත, ස්මාර්ට්ෆෝන්, ටැබ්ලට් සහ iPad හරහා ප්‍රවේශ විය හැකිය.',
                '',
                'Pro අනුවාදය සමඟ, ඔබට නොබැඳිව ගීතිකා වෙත ප්‍රවේශ විය හැකි අතර වැඩිදියුණු කළ විශේෂාංග භුක්ති විඳිය හැකි අතර, ඔබට ඕනෑම වේලාවක, ඕනෑම තැනක, නිවසේදී, දේවස්ථානයේදී හෝ දුරස්ථ ස්ථානවල නමස්කාර කිරීමට ඉඩ සලසයි. යෙදුම ලොව පුරා දේවස්ථාන, ගායන කණ්ඩායම්, තරුණ කණ්ඩායම් සහ තනි ඇදහිලිවන්තයන්ට නමස්කාර කිරිමට, නමස්කාරය මෙහෙයවීමට, අන් අයව දිරිමත් කිරීමට සහ ඔබේ පුද්ගලික ප්‍රශංසාව ගැඹුරු කිරීමට ඔබට උපකාරී වේ.',
                '',
                '"ස්වාමීන්ට ගායනා කරමු.  අපේ ගැළවීමේ පර්වතයට ප්‍රීති ඝෝෂා පවත්වමු." - ගීතාවලිය 95:1',
                '',
                'දෙවියන් වහන්සේට ප්‍රශංසා කිරීම සහ නමස්කාර කිරීම අපට කළ හැකි වඩාත්ම පරිශුද්ධ හා ප්‍රීතිමත් ක්‍රියාවකි. ඔබ මෙම යෙදුම භාවිතා කරන විට, අපි සියල්ලෝම දෙවියන් වහන්සේගේ දරුවන් සහ ඔහුගේ රාජ්‍යයේ උරුමක්කාරයන් බවත්, ලොව පුරා නමස්කාරයෙන් එක්සත් වී සිටින බවත් මතක තබා ගන්න.',
                '',
                'සියලුම ගීත ඒවායේ නියම හිමිකරුවන්ගේ සහ ගීත රචකයන්ගේ දේපළ ලෙස පවතී. ඔවුන්ගේ දායකත්වයට අපි කෘතඥ වන අතර මෙම යෙදුම යථාර්ථයක් කිරීමට උපකාර කළ අපගේ කැපවූ කණ්ඩායමට ස්තූතිවන්ත වෙමු.',
              ]),

              const SizedBox(height: 30),
              const Divider(color: Colors.white54),
              const SizedBox(height: 20),

              // Tamil content
              _buildSection([
                'இந்த செயலி பற்றி',
                '',
                'நம்முடைய கர்த்தராகிய இயேசு கிறிஸ்துவிற்கு வாழ்த்துக்கள்!',
                '',
                'துதியின் சிகரம் என்ற இந்த வழிபாட்டு  பாடல் செயலியை நீங்கள் தேர்ந்தெடுத்து பயன்படுத்தத் தொடங்கியுள்ளதற்கு நாங்கள் மிகுந்த மகிழ்ச்சி அடைகிறோம். இது உங்கள் ஆராதனையை செழிக்கச் செய்யும், உங்கள் இருதயத்தை ஊக்கப்படுத்தும், மற்றும் உங்களுடைய ஆத்மாவிற்குரிய பயணத்திற்கு ஆசீர்வாதமாக இருக்கும் என நாம் பிரார்த்திக்கிறோம்.',
                '',
                'இந்த செயலியில் ஆங்கிலம், சிங்களம் மற்றும் தமிழில் 5,000+ கிறிஸ்தவ பாடல்கள் உள்ளடக்கப்பட்டுள்ளன. இது எளிமை, அழகு மற்றும் எளிதான பயன்பாட்டிற்காக வடிவமைக்கப்பட்டுள்ளது. Google Play Store, Apple App Store, மற்றும் Huawei AppGallery இல் கிடைக்கிறது மற்றும் smartphones, tablets, iPads போன்ற சாதனங்களில் பயன்படுத்தலாம்.',
                '',
                '(சார்பு) Pro Version-ஐ தேர்ந்தெடுத்தால், நீங்கள் பாடல்களை offline-ஆக அணுகலாம் மற்றும் விரிவான அம்சங்களை அனுபவிக்கலாம். இது வீட்டில், தேவாலயத்தில், அல்லது தொலைதூர இடங்களிலும் உங்கள் ஆராதனையைத் தொடர உதவும். இந்த செயலி தேவாலயங்கள், இசைக்குழுக்கள், இளைஞர் குழுக்கள் மற்றும் தனிநபர்களுக்காக உலகளாவியரீதியாக பயன்படுகிறது.',
                '',
                '"வாருங்கள், கர்த்தரை பாடுவோம்; நம்முடைய இரட்சிப்பின் பாறைக்கு மகிழ்ச்சியுடன் பாடுவோம்!" – சங்கீதம் 95:1',
                '',
                'ஆராதனை செய்வதும், இறைவனை மகிழ்ச்சியுடன் போற்றுவதும் நாம் செய்யக்கூடிய மிகப் பரிசுத்தமான மற்றும் மகிழ்ச்சியான செயல்களில் ஒன்றாகும். இந்த செயலியைப் பயன்படுத்தும் போது, நாம் அனைவரும் தேவனுடைய பிள்ளைகளாகவும், அவருடைய ராஜ்யத்தின் வாரிசுகளாகவும், உலகம் முழுவதும் ஒன்றிணைந்த ஆராதனையாளர்களாகவும் இருக்கிறோம் என்பதை நினைவில் வையுங்கள்.',
                '',
                'இந்த செயலியில் உள்ள அனைத்து பாடல்களும் அவற்றின் உரிமையாளர்கள் மற்றும் பாடலாசிரியர்களுக்கு சொந்தமானவை. அவர்களது பங்களிப்புக்கு நாங்கள் உளமார்ந்த நன்றியை தெரிவிக்கிறோம். இந்த செயலியை உருவாக்க உதவிய ஒவ்வொருவருக்கும் நன்றியுடன் இருக்கிறோம்.',
              ]),

              const SizedBox(height: 30),
              const Divider(color: Colors.white54),
              const SizedBox(height: 20),

              // Credits section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      textAlign: TextAlign.center,
                      'A Vision by: Johnson Shan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      textAlign: TextAlign.center,
                      'Designed & Developed by: JS Christian Productions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clickable website link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Icon(Icons.language, color: Colors.lightBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          textAlign: TextAlign.center,
                          ' www.therockofpraise.org ',
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),

                    // Social Media Icons Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // WhatsApp
                          GestureDetector(
                            onTap:
                                () => _launchURL(
                                  'https://whatsapp.com/channel/0029Vb6iFkCCMY0Lkvm0Ju0Z',
                                ),

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // YouTube
                          GestureDetector(
                            onTap:
                                () => _launchURL(
                                  'https://youtube.com/@therockofpraise?si=YJT-6zRquDCFPkGH',
                                ),

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.youtube,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // Instagram
                          GestureDetector(
                            onTap:
                                () => _launchURL(
                                  'https://www.instagram.com/rockofpraise?igsh=MWZzNzF4NHdoazEwYg%3D%3D&utm_source=qr',
                                ),

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF833AB4),
                                    Color(0xFFE1306C),
                                    Color(0xFFFD1D1D),
                                    Color(0xFFFFDC80),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.instagram,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // Facebook
                          GestureDetector(
                            onTap:
                                () => _launchURL(
                                  'https://www.facebook.com/share/1F8qumg3oz/?mibextid=wwXIfr',
                                ),

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1877F2),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.facebookF,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // X (Twitter)
                          GestureDetector(
                            onTap:
                                () => _launchURL(
                                  'https://x.com/praise_the37536?s=21&t=qF7E-l9AG55RTMPLuhoT_A',
                                ),

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.xTwitter,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      textAlign: TextAlign.center,
                      '© 2025 The Rock of Praise. All rights reserved.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<String> paragraphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          paragraphs.map((paragraph) {
            if (paragraph.isEmpty) {
              return const SizedBox(height: 12);
            }

            // Check if it's a Bible verse (contains quotes and dash)
            bool isBibleVerse =
                paragraph.contains('"') && paragraph.contains('–');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                paragraph,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isBibleVerse ? 16 : 15,
                  fontStyle: isBibleVerse ? FontStyle.italic : FontStyle.normal,
                  fontWeight:
                      isBibleVerse ? FontWeight.w500 : FontWeight.normal,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
            );
          }).toList(),
    );
  }
}
