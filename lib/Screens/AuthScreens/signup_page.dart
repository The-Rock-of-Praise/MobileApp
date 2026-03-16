import 'dart:ui'; // Glass effect eka smoothing walata
import 'package:flutter/material.dart';
import 'package:lyrics/FireBase/auth_service.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/Screens/AuthScreens/login_page.dart';
import 'package:lyrics/Screens/HomeScreen/home_screen.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:lyrics/widgets/auth_button.dart';
import 'package:lyrics/widgets/auth_textfeild_container.dart';
import 'package:lyrics/widgets/auth_via_big_button.dart';
import 'package:lyrics/widgets/main_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final userService = UserService();
  bool _isAgreed = false;
  String? errorMessage = '';
  bool isLoading = false;
  String initialCountry = 'LK'; 
  PhoneNumber number = PhoneNumber(isoCode: 'LK');
  String fullPhoneNumber = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Apple Sign Up Function
  Future<void> appleSignUp() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await FireBaseAuthServices().signUpWithApple(); // logic ekata call karanawa
      if (result == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message ?? 'An unknown error occurred';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> googleSignUp() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await FireBaseAuthServices().signUpWithGoogle();
      if (result == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message ?? 'An unknown error occurred';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (fullPhoneNumber.isEmpty || fullPhoneNumber.length < 5) {
      setState(() {
        errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_isAgreed) {
      setState(() {
        errorMessage = 'Please agree to the Privacy Policy';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final newUser = UserModel(
        fullname: _nameController.text,
        email: _emailController.text,
        phonenumber: fullPhoneNumber,
        password: _passwordController.text,
      );

      final result = await userService.signUp(newUser);
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Signup failed';
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
      body: MainBAckgound(
        child: Stack(
          children: [
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Join us for a premium experience',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
    // Google සහ Apple බටන් දෙක එකම Row එකක
    Row(
      children: [
        Expanded(
          child: AuthViaBigButton(
            name: 'Google',
            path: 'assets/Google.png',
            ontap: googleSignUp,
            isLoading: false,
          ),
        ),
        const SizedBox(width: 15), // බටන් දෙක මැද පරතරය සඳහා
        Expanded(
          child: AuthViaBigButton(
            name: 'Apple',
            path: 'assets/AppleInc.png',
            ontap: appleSignUp,
            isLoading: false,
          ),
        ),
      ],
    ),
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      "or",
                                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                ],
                              ),
                              const SizedBox(height: 15),

                              AuthTextfeildContainer(
                                controller: _nameController,
                                hintText: 'Fullname',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 12),
                              
                              // Phone Number Input
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.6), size: 20),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: InternationalPhoneNumberInput(
                                        onInputChanged: (PhoneNumber number) {
                                          fullPhoneNumber = number.phoneNumber!;
                                        },
                                        selectorConfig: const SelectorConfig(
                                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                                          showFlags: true,
                                          setSelectorButtonAsPrefixIcon: true,
                                          leadingPadding: 10,
                                        ),
                                        selectorTextStyle: const TextStyle(color: Colors.white),
                                        initialValue: number,
                                        textFieldController: _phoneController,
                                        formatInput: true,
                                        cursorColor: Colors.white,
                                        inputDecoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                                          border: InputBorder.none,
                                          hintText: 'Phone Number',
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                                          isDense: true,
                                        ),
                                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              AuthTextfeildContainer(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.mail_outline,
                              ),
                              const SizedBox(height: 12),
                              AuthTextfeildContainer(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 12),
                              AuthTextfeildContainer(
                                controller: _confirmPasswordController,
                                hintText: 'Confirm Password',
                                icon: Icons.lock_reset_outlined,
                                isPassword: true,
                              ),

                              if (errorMessage != null && errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),

                              Row(
                                children: [
                                  Theme(
                                    data: ThemeData(unselectedWidgetColor: Colors.white54),
                                    child: Checkbox(
                                      value: _isAgreed,
                                      activeColor: Colors.white,
                                      checkColor: Colors.black,
                                      onChanged: (val) => setState(() => _isAgreed = val ?? false),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isAgreed = !_isAgreed),
                                      child: Text(
                                        'I agree with Privacy and Policy',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              AuthButton(text: 'Sign Up', onTap: signUp),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            "Login",
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
                    const SizedBox(height: 40),
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