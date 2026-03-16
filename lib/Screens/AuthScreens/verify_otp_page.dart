import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyrics/Screens/AuthScreens/reset_password_page.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/auth_button.dart';
import 'package:lyrics/widgets/auth_textfeild_container.dart';
import 'package:lyrics/widgets/main_background.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;

  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _userService = UserService();
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _otpController = TextEditingController();

  Future<void> submitOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      setState(() {
        errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _userService.verifyOtp(widget.email, _otpController.text);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'OTP Verified!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: widget.email, otp: _otpController.text),
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MainBAckgound(
        child: Stack(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'We sent a 6-digit code to ${widget.email}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              AuthTextfeildContainer(
                                controller: _otpController,
                                hintText: '6-digit OTP',
                                icon: Icons.security,
                              ),
                              if (errorMessage != null && errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 30),
                              AuthButton(text: 'Verify', onTap: submitOtp),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
