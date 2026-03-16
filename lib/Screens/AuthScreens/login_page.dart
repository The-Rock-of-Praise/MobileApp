import 'dart:ui'; // Glass effect eka smoothing walata
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lyrics/FireBase/auth_service.dart';
import 'package:lyrics/Screens/AuthScreens/signup_page.dart';
import 'package:lyrics/Screens/AuthScreens/forgot_password_page.dart';
import 'package:lyrics/Screens/HomeScreen/home_screen.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/auth_button.dart';
import 'package:lyrics/widgets/auth_textfeild_container.dart';
import 'package:lyrics/widgets/auth_via_buttons.dart';
import 'package:lyrics/widgets/main_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userService = UserService();
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Oyaage API functions (Kisim wenasak kale ne) ---
  Future<void> googleSignIn() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final result = await FireBaseAuthServices().signInWithGoogle();
      if (result == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePage()), (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { errorMessage = e.message ?? 'An unknown error occurred'; });
    } catch (e) {
      if (mounted) setState(() { errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> appleSignIn() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final result = await FireBaseAuthServices().signInWithApple();
      if (result == true) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePage()), (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { errorMessage = e.message ?? 'An unknown error occurred'; });
    } catch (e) {
      if (mounted) setState(() { errorMessage = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() { errorMessage = 'Please fill in all fields'; });
      return;
    }
    if (!_emailController.text.contains('@')) {
      setState(() { errorMessage = 'Please enter a valid email'; });
      return;
    }
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final result = await userService.login(emailOrPhone: _emailController.text, password: _passwordController.text);
      if (result['success'] == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        setState(() { errorMessage = result['message'] ?? 'Login failed'; });
      }
    } catch (e) {
      setState(() { errorMessage = 'An error occurred: ${e.toString()}'; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBAckgound( // Oyaage existing background widget eka
        child: Stack(
          children: [
            // Loader eka screen eka meda thiyanna
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    
                    // Title Section
                    const Text(
                     "Let's continue praising together",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Let’s continue praising together.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // --- Glass Morphic Card ---
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
                                hintText: 'Email or Phone',
                                icon: Icons.mail_outline,
                              ),
                              const SizedBox(height: 20),
                              AuthTextfeildContainer(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              
                              // Error Message Display
                              if (errorMessage != null && errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              AuthButton(text: 'Login', onTap: signIn),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // Divider section
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text("Social Login", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Social Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: googleSignIn,
                            child: AuthViaButtons(name: 'Google', path: 'assets/Google.png'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: appleSignIn,
                            child: AuthViaButtons(name: 'Apple', path: 'assets/AppleInc.png'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New here? ",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignupPage()));
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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