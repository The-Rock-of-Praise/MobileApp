import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lyrics/Models/user_model.dart';
import 'package:lyrics/Service/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class FireBaseAuthServices {
  final UserService _userService = UserService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: '422917812627-6bsp7eu8rs2dk7vg2eurufav0u88if7p.apps.googleusercontent.com',
);
  static const String imageUrl = 'imageUrl';

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();
  static Future<void> saveIsPremium(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(imageUrl, imageUrl);
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  static Future<String> getemailProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(imageUrl);
      return userId != null ? userId.toString() : '';
    } catch (e) {
      print('Error loading getemailProfileImage $e');
      return '';
    }
  }

  Future<bool> signUpWithGoogle() async {
    return await _handleGoogleAuth();
  }

  Future<bool> signInWithGoogle() async {
    return await _handleGoogleAuth();
  }

  Future<bool> _handleGoogleAuth() async {
    try {
      print('🌐 Starting Unified Google Auth Process...');
      
      // Sign out first to clear any previous sessions
      await _googleSignIn.signOut();

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('🚫 Google Sign-In cancelled by user');
        return false;
      }

      print('✅ Google User obtained: ${googleUser.email}');

      print('✅ Google User obtained: ${googleUser.email}');

      final response = await _userService.client.post(
        Uri.parse('http://192.168.8.101:3100/api/auth/social-auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullname': googleUser.displayName ?? 'Google User',
          'email': googleUser.email,
          'providerId': googleUser.id,
          'provider': 'google',
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✨ Social auth successful');
        await UserService.saveuserID(responseData['user']['id']);
        await UserService.saveIsPremium(responseData['user']['isPremium']);
        
        if (googleUser.photoUrl != null) {
          await saveIsPremium(googleUser.photoUrl!);
        }
        return true;
      }

      print('❌ Unified Google Auth failed: ${responseData['error']}');
      throw Exception(responseData['error'] ?? 'Authentication failed');

    } catch (e) {
      print('💥 Error in _handleGoogleAuth: $e');
      rethrow; // Rethrow to let the UI catch and display the error
    }
  }

  Future<bool> signUpWithApple() async {
    return await _handleAppleAuth();
  }

  Future<bool> signInWithApple() async {
    return await _handleAppleAuth();
  }

    Future<bool> _handleAppleAuth() async {
    try {
      print('🌐 Starting Unified Apple Auth Process...');
      
      // Apple Provider එක සූදානම් කිරීම
      final appleProvider = AppleAuthProvider();
      
      // Apple Login pop-up එක පෙන්වීම සහ User දත්ත ලබා ගැනීම
      final UserCredential userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
      final User? appleUser = userCredential.user;

      if (appleUser == null) {
        print('🚫 Apple Sign-In cancelled by user');
        return false;
      }

      print('✅ Apple User obtained: ${appleUser.email}');

      String email = appleUser.email ?? '';
      String displayName = appleUser.displayName ?? '';

      // Fallback for missing displayName
      if (displayName.trim().isEmpty) {
        if (email.isNotEmpty && email.contains('@')) {
          displayName = email.split('@').first;
        } else {
          displayName = 'Apple User';
        }
      }

      // Fallback for missing email (to satisfy backend validation)
      if (email.trim().isEmpty) {
        email = '${appleUser.uid}@apple.dummy';
      }

      final response = await _userService.client.post(
        Uri.parse('http://192.168.8.101:3100/api/auth/social-auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullname': displayName,
          'email': email,
          'providerId': appleUser.uid,
          'provider': 'apple',
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✨ Social auth successful');
        await UserService.saveuserID(responseData['user']['id']);
        await UserService.saveIsPremium(responseData['user']['isPremium']);
        
        if (appleUser.photoURL != null) {
          await saveIsPremium(appleUser.photoURL!);
        }
        return true;
      }

      print('❌ Unified Apple Auth failed: ${responseData['error']}');
      throw Exception(responseData['error'] ?? 'Authentication failed');

    } catch (e) {
      print('💥 Error in _handleAppleAuth: $e');
      rethrow; // Rethrow to let the UI catch and display the error
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

///use this in signup//
// Future<void> googleSignUp() async {
//     print('Google sign up initiated');
//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       print('Calling signInWithGoogle');
//       final result = await FireBaseAuthServices().signInWithGoogle();
//       print('Google sign in result: $result');

//       if (result != null) {
//         print('User signed in successfully: ${result.uid}');
//         if (mounted) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => HomePage()),
//             (route) => false, // This removes all previous routes
//           );
//         }
//       } else {
//         print('Google sign in returned null user');
//         if (mounted) {
//           setState(() {
//             errorMessage = 'Sign in was cancelled or failed';
//           });
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       print('Google sign in error: ${e.message}');
//       if (mounted) {
//         setState(() {
//           errorMessage = e.message ?? 'An unknown error occurred';
//         });
//       }
//     } catch (e) {
//       print('Unexpected error during Google sign in: $e');
//       if (mounted) {
//         setState(() {
//           errorMessage = 'An unexpected error occurred';
//         });
//       }
//     } finally {
//       print('Google sign in process completed');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> signUpWithEmailAndPassword() async {
//     if (!_isAgreed) {
//       setState(() {
//         errorMessage = 'Please agree to Privacy and Policy';
//       });
//       return;
//     }

//     if (_passwordController.text != _confirmPasswordController.text) {
//       setState(() {
//         errorMessage = 'Passwords do not match';
//       });
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       await FireBaseAuthServices().signUpWithEmailAndPassword(
//         _emailController.text,
//         _passwordController.text,
//       );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomePage()),
//       );
//     } on FirebaseAuthException catch (e) {
//       setState(() {
//         errorMessage = e.message ?? 'An unknown error occurred';
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
