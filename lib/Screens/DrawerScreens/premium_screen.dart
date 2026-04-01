import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyrics/Const/const.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with WidgetsBindingObserver {
  final UserService _userService = UserService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User came back from the browser, check if payment succeeded
      _checkPremiumStatusOnResume();
    }
  }

  Future<void> _checkPremiumStatusOnResume() async {
    try {
      final userId = await UserService.getUserID();
      if (userId.isEmpty) return;
      
      final result = await _userService.getFullProfile(userId);
      
      if (result['success'] == true) {
        // Add mounted check before setState
        if (mounted) {
          setState(() => _userProfile = result['profile']);
        }
        
        if (_userProfile?['isPremium'] == 1 || _userProfile?['isPremium'] == true) {
          // Sync successful, premium account is active
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Successful! Now you are a PRO member.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.pop(context, true); // Pop the premium screen
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error on resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh status: $e'), backgroundColor: Colors.orange)
        );
      }
    }
  }

  // --- API Functions ---
  Future<void> _initializeProfile() async {
    setState(() => _isLoading = true);
    try {
      await profile();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      // Add mounted check before setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> profile() async {
    try {
      final userId = await UserService.getUserID();
      if (userId.isEmpty) return;
      
      final result = await _userService.getFullProfile(userId);
      
      if (result['success'] == true) {
        // Add mounted check before setState
        if (mounted) {
          setState(() => _userProfile = result['profile']);
        }
      }
    } catch (e) {
      debugPrint('Error fetch profile: $e');
    }
  }

  Future<void> _processPremiumUpgrade() async {
    try {
      final userId = _userProfile?['id']?.toString() ?? 'unknown';
      final email = _userProfile?['email'] ?? 'user@example.com';
      final name = _userProfile?['fullname'] ?? 'User';
      final phone = _userProfile?['phonenumber'] ?? "0771234567";
      final orderId = 'PRO_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Ensure loading state if not already set by UI
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Fetch the mobile secret from the backend explicitly
      const String serverBaseUrl = 'https://therockofpraise.org/api'; 
      final response = await http.get(Uri.parse('$serverBaseUrl/payhere/mobile-secret'));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load mobile secret from server');
      }

      final resData = jsonDecode(response.body);
      final mobileSecret = resData['secret'];

      if (mobileSecret == null || mobileSecret.isEmpty) {
        throw Exception('Invalid mobile secret received');
      }

      Map paymentObject = {
        "sandbox": !Const.isProduction, 
        "merchant_id": Const.merchant_id, 
        "merchant_secret": mobileSecret, 
        "notify_url": "$serverBaseUrl/payhere/notify",
        "order_id": orderId,
        "items": "The Rock of Praise - Pro Version",
        "amount": "2.99",               // Recurring amount
        "recurrence": "1 Month",         // Recurring payment frequency
        "duration": "Forever",            // Recurring payment duration
        "currency": "USD",
        "first_name": name.split(' ').first,
        "last_name": name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : 'User',
        "email": email,
        "phone": phone,
        "address": "Not provided",
        "city": "Colombo",
        "country": "Sri Lanka",
        "delivery_address": "Not provided",
        "delivery_city": "Colombo",
        "delivery_country": "Sri Lanka",
        "custom_1": userId, // Pass userId to the backend for webhook update
        "custom_2": ""
      };

      PayHere.startPayment(
        paymentObject, 
        (paymentId) {
          debugPrint("Recurring Payment Success. Payment Id: $paymentId");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Successful! Now you are a PRO member.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            // Re-fetch profile to update UI immediately
            _initializeProfile();
            Navigator.pop(context, true);
          }
        }, 
        (error) { 
          debugPrint("Recurring Payment Failed. Error: $error");
          if (mounted) {
            _showError('Payment Failed: $error');
          }
        }, 
        () { 
          debugPrint("Recurring Payment Dismissed");
        }
      );
    } catch (e) {
      if (mounted) {
        _showError('Payment system error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBAckgound(
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Top Section (Title, Price, Button) ---
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (bounds) => const LinearGradient(
                                              colors: [Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent],
                                            ).createShader(bounds),
                                            child: const Text(
                                              'Pro Version',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          // Refresh Status Button
                                          IconButton(
                                            onPressed: _isLoading ? null : () => _initializeProfile(),
                                            icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.5)),
                                            tooltip: 'Refresh Status',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '\$2.99',
                                            style: TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Text(
                                              '\nper month',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white.withOpacity(0.5),
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 55,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : () async {
                                            // Final check if they are already premium before opening browser
                                            if (_userProfile?['isPremium'] == 1 || 
                                                _userProfile?['isPremium'] == true || 
                                                _userProfile?['isPremium'] == "1") {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('You are already a PRO member!'))
                                              );
                                              return;
                                            }
                                            await _processPremiumUpgrade();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          ),
                                          child: _isLoading 
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Get started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Divider(height: 1, color: Colors.white.withOpacity(0.05)),

                                // --- Features List Section ---
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
                                  child: Column(
                                    children: [
                                      _buildFeatureItem('Unlimited worship songs access'),
                                      _buildFeatureItem('Offline access after download'),
                                      _buildFeatureItem('Ad-free experience (no interruptions)'),
                                      _buildFeatureItem('Exclusive gospel updates'),
                                      _buildFeatureItem('Faster performance & smooth experience'),
                                      _buildFeatureItem('Support the mission — Glory to God'),
                                      const SizedBox(height: 25),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Cancel anytime • Secure & trusted payment',
                                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- මම එකතු කළ කොටස: Main Card එක ඇතුළෙම යටටම එන Support Text එක ---
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(12), // Card එකේ බිත්ති වලින් පොඩ්ඩක් ඇතුළට වෙන්න
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03), // Card එක ඇතුළේ වෙනසක් පේන්න පොඩි shade එකක්
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Your support help us share more worship songs, keep the app running smoothly, and continue our work Glory to God',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.5),
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10), // අවසානයට පොඩි ඉඩක්
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.blueAccent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
