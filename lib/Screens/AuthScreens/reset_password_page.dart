import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyrics/Screens/AuthScreens/login_page.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/auth_button.dart';
import 'package:lyrics/widgets/auth_textfeild_container.dart';
import 'package:lyrics/widgets/main_background.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _userService = UserService();
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> savePassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _userService.resetPassword(widget.email, widget.otp, _newPasswordController.text);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Password Reset Successfully!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
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
                      "Reset Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Enter your new password below.',
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
                                controller: _newPasswordController,
                                hintText: 'New Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),
                              AuthTextfeildContainer(
                                controller: _confirmPasswordController,
                                hintText: 'Confirm Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
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
                              AuthButton(text: 'Save Password', onTap: savePassword),
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
