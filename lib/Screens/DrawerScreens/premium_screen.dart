import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyrics/Const/const.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:lyrics/Controllers/payment_controller.dart';
import 'package:lyrics/Screens/HomeScreen/home_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with WidgetsBindingObserver {
  final UserService _userService = UserService();
  static const String _serverBaseUrl = 'https://therockofpraise.org/api';

  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  // ── Currency Selection State ───────────────────────────────────────────────
  String _selectedCurrency = 'USD'; // 'USD' or 'LKR'
  double? _lkrAmount;              // fetched from backend
  bool _isFetchingRate = false;
  String? _rateError;
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeProfile();
    _fetchExchangeRate(); // Fetch LKR rate on screen load
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPremiumStatusOnResume();
    }
  }

  // ── Fetch real-time LKR amount from backend ───────────────────────────────
  Future<void> _fetchExchangeRate() async {
    if (mounted) setState(() => _isFetchingRate = true);
    try {
      final response = await http.get(
        Uri.parse('$_serverBaseUrl/payhere/exchange-rate'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _lkrAmount = (data['lkr_amount'] as num).toDouble();
            _rateError = null;
          });
        }
      } else {
        if (mounted) setState(() => _rateError = 'Rate unavailable');
      }
    } catch (e) {
      debugPrint('Exchange rate fetch error: $e');
      if (mounted) setState(() => _rateError = 'Rate unavailable');
    } finally {
      if (mounted) setState(() => _isFetchingRate = false);
    }
  }
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _checkPremiumStatusOnResume() async {
    try {
      final userId = await UserService.getUserID();
      if (userId.isEmpty) return;
      final result = await _userService.getFullProfile(userId);
      if (result['success'] == true && mounted) {
        setState(() => _userProfile = result['profile']);
        if (_userProfile?['isPremium'] == 1 || _userProfile?['isPremium'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Successful! Now you are a PRO member.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            Get.offAll(() => const HomePage());
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error on resume: $e');
    }
  }

  Future<void> _initializeProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await _loadProfile();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await UserService.getUserID();
      if (userId.isEmpty) return;
      final result = await _userService.getFullProfile(userId);
      if (result['success'] == true && mounted) {
        setState(() => _userProfile = result['profile']);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  // ── Payment Processing (dynamic LKR / USD) ────────────────────────────────
  Future<void> _processPremiumUpgrade() async {
    try {
      final userId = _userProfile?['id']?.toString() ?? 'unknown';
      final email = _userProfile?['email'] ?? 'user@example.com';
      final name = _userProfile?['fullname'] ?? 'User';
      final phone = _userProfile?['phonenumber'] ?? '0771234567';
      final orderId = 'PRO_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) setState(() => _isLoading = true);

      // Determine amount & currency based on user selection
      final bool useLkr = _selectedCurrency == 'LKR' && _lkrAmount != null;
      final String payAmount = useLkr
          ? _lkrAmount!.toStringAsFixed(2)
          : '2.99';
      final String payCurrency = useLkr ? 'LKR' : 'USD';

      // Fetch mobile secret
      final secretResponse = await http.get(
        Uri.parse('$_serverBaseUrl/payhere/mobile-secret'),
      );
      if (secretResponse.statusCode != 200) {
        throw Exception('Failed to load mobile secret from server');
      }
      final mobileSecret = jsonDecode(secretResponse.body)['secret'];
      if (mobileSecret == null || (mobileSecret as String).isEmpty) {
        throw Exception('Invalid mobile secret received');
      }

      debugPrint('[Payment] Currency: $payCurrency | Amount: $payAmount');

      Map paymentObject = {
        "sandbox": !Const.isProduction,
        "merchant_id": Const.merchant_id,
        "merchant_secret": mobileSecret,
        "notify_url": "$_serverBaseUrl/payhere/notify",
        "order_id": orderId,
        "items": "The Rock of Praise - Pro Version",
        "amount": payAmount,
        "recurrence": "1 Month",
        "duration": "Forever",
        "currency": payCurrency,
        "first_name": name.split(' ').first,
        "last_name": name.split(' ').length > 1
            ? name.split(' ').sublist(1).join(' ')
            : 'User',
        "email": email,
        "phone": phone,
        "address": "Not provided",
        "city": "Colombo",
        "country": "Sri Lanka",
        "delivery_address": "Not provided",
        "delivery_city": "Colombo",
        "delivery_country": "Sri Lanka",
        "custom_1": userId,
        "custom_2": "",
      };

      PayHere.startPayment(
        paymentObject,
        (paymentId) async {
          debugPrint("Payment Success. ID: $paymentId | $payCurrency $payAmount");
          if (mounted) {
            final PaymentController paymentController = PaymentController();
            bool success = await paymentController.handlePaymentSuccess(
              email: email,
              userId: userId,
              paymentId: paymentId,
            );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment Successful! Now you are a PRO member.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
              await _initializeProfile();
              Get.offAll(() => const HomePage());
            } else if (mounted) {
              _showError('Payment succeeded but status sync failed. We are investigating.');
            }
          }
        },
        (error) {
          debugPrint("Payment Failed. Error: $error");
          if (mounted) _showError('Payment Failed: $error');
        },
        () => debugPrint("Payment Dismissed"),
      );
    } catch (e) {
      if (mounted) _showError('Payment system error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ──────────────────────────────────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                                // ── Title & Price ─────────────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
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
                                          IconButton(
                                            onPressed: _isLoading ? null : _initializeProfile,
                                            icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.5)),
                                            tooltip: 'Refresh Status',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedCurrency == 'LKR' && _lkrAmount != null
                                                ? 'LKR ${_lkrAmount!.toStringAsFixed(2)}'
                                                : '\$2.99',
                                            style: const TextStyle(
                                              fontSize: 42,
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
                                    ],
                                  ),
                                ),

                                // ── Currency Selector ──────────────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Payment Method',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          // LKR Option
                                          Expanded(
                                            child: _CurrencyOptionCard(
                                              icon: '🏦',
                                              title: 'Local Card',
                                              subtitle: _isFetchingRate
                                                  ? 'Fetching rate...'
                                                  : _lkrAmount != null
                                                      ? 'LKR ${_lkrAmount!.toStringAsFixed(2)}'
                                                      : _rateError ?? 'Unavailable',
                                              isSelected: _selectedCurrency == 'LKR',
                                              isAvailable: _lkrAmount != null,
                                              onTap: () {
                                                if (_lkrAmount != null) {
                                                  setState(() => _selectedCurrency = 'LKR');
                                                } else {
                                                  _fetchExchangeRate();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // USD Option
                                          Expanded(
                                            child: _CurrencyOptionCard(
                                              icon: '🌍',
                                              title: 'International',
                                              subtitle: 'USD \$2.99',
                                              isSelected: _selectedCurrency == 'USD',
                                              isAvailable: true,
                                              onTap: () => setState(() => _selectedCurrency = 'USD'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_selectedCurrency == 'LKR' && _lkrAmount != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Recommended for Sri Lankan bank cards. Total: LKR ${_lkrAmount!.toStringAsFixed(2)}/month',
                                                  style: const TextStyle(color: Colors.green, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // ──────────────────────────────────────────

                                const SizedBox(height: 24),

                                // ── Get Started Button ─────────────────────
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () async {
                                        if (_userProfile?['isPremium'] == 1 ||
                                            _userProfile?['isPremium'] == true ||
                                            _userProfile?['isPremium'] == "1") {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('You are already a PRO member!')),
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
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20, height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : Text(
                                              'Get Started · ${_selectedCurrency == 'LKR' && _lkrAmount != null ? 'LKR ${_lkrAmount!.toStringAsFixed(2)}' : 'USD \$2.99'}',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                    ),
                                  ),
                                ),
                                // ──────────────────────────────────────────

                                Divider(height: 36, color: Colors.white.withOpacity(0.05)),

                                // ── Features List ──────────────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
                                  child: Column(
                                    children: [
                                      _buildFeatureItem('Unlimited worship songs access'),
                                      _buildFeatureItem('Offline access after download'),
                                      _buildFeatureItem('Ad-free experience (no interruptions)'),
                                      _buildFeatureItem('Exclusive gospel updates'),
                                      _buildFeatureItem('Faster performance & smooth experience'),
                                      _buildFeatureItem('Support the mission — Glory to God'),
                                      const SizedBox(height: 20),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Cancel anytime • Secure & trusted payment',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.3),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Support Text ───────────────────────────
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Your support helps us share more worship songs, keep the app running smoothly, and continue our work — Glory to God',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.5),
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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

// ── Reusable Currency Option Card Widget ─────────────────────────────────────
class _CurrencyOptionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  const _CurrencyOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withOpacity(0.7)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blueAccent, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isAvailable
                    ? Colors.white.withOpacity(0.55)
                    : Colors.orange.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
