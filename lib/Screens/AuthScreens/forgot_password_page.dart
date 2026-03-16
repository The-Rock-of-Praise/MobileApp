import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyrics/Screens/AuthScreens/verify_otp_page.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/auth_button.dart';
import 'package:lyrics/widgets/auth_textfeild_container.dart';
import 'package:lyrics/widgets/main_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _userService = UserService();
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _emailController = TextEditingController();

  Future<void> sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() {
        errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _userService.forgotPassword(_emailController.text);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'OTP Sent!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpPage(email: _emailController.text),
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
                      "Forgot Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Enter your email to receive an OTP.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
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
                                controller: _emailController,
                                hintText: 'Email Address',
                                icon: Icons.email_outlined,
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
                              AuthButton(text: 'Send OTP', onTap: sendOtp),
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
