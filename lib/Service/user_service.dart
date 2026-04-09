import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lyrics/Models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _baseUrl = 'https://therockofpraise.org/api/auth';
  static const String _baseUrl1 = 'https://therockofpraise.org/api';
  static const String _userIDKey = 'userId';
  static const String _isPremium = 'isPremium';
  final http.Client client;

  UserService({http.Client? client}) : client = client ?? http.Client();

  static Future<void> saveuserID(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIDKey, userId);
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  static Future<String> getUserID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIDKey);
      return userId != null ? userId.toString() : '';
    } catch (e) {
      print('Error loading user ID: $e');
      return '';
    }
  }

  static Future<void> saveIsPremium(int isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_isPremium, isPremium);
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  static Future<String> getIsPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_isPremium);
      return userId != null ? userId.toString() : '';
    } catch (e) {
      print('Error loading user ID: $e');
      return '';
    }
  }

  // New method to get user profile by ID
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': UserModel.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to fetch user profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get current user profile (using stored user ID)
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final userId = await getUserID();
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'No user ID found. Please login again.',
        };
      }

      return await getUserProfile(userId);
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> signUp(UserModel user) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullname': user.fullname,
          'phonenumber': user.phonenumber,
          'email': user.email,
          'password': user.password,
          'confirmpassword': user.password,
        }),
      );
      print('response ${response.body}');
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        await saveuserID(responseData['userId']);
        print('User signed up successfully: ${responseData['userId']}');
        return {
          'success': true,
          'message': responseData['message'],
          'userId': responseData['userId'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'emailOrPhone': emailOrPhone, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save user ID after successful login
        await saveuserID(responseData['user']['id']);
        await saveIsPremium(responseData['user']['isPremium']);
        print(
          'user login data ${responseData['user']}  ${responseData['user']['isPremium']}',
        );
        return {
          'success': true,
          'message': responseData['message'],
          'user': UserModel.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullname,
    String? phonenumber,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (fullname != null) 'fullname': fullname,
          if (phonenumber != null) 'phonenumber': phonenumber,
          if (email != null) 'email': email,
          if (currentPassword != null) 'currentPassword': currentPassword,
          if (newPassword != null) 'newPassword': newPassword,
        }),
      );

      final responseData = json.decode(response.body);
      print('Response from updateUserProfile: $responseData');
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'user': UserModel.fromJson(responseData['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Profile update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateCurrentUserProfile({
    String? fullname,
    String? phonenumber,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final userId = await getUserID();
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'No user ID found. Please login again.',
        };
      }

      return await updateUserProfile(
        userId: userId,
        fullname: fullname,
        phonenumber: phonenumber,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getFullProfile(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl1/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      print('results $responseData');
      if (response.statusCode == 200) {
        saveIsPremium(responseData['user']['isPremium']);
        return {'success': true, 'profile': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateFullProfile({
    required String userId,
    String? country,
    String? dateOfBirth,
    String? gender,
    String? preferredLanguage,
    String? bio,
    String? accountType,
    List<String>? interests,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl1/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'country': country,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'preferredLanguage': preferredLanguage,
          'bio': bio,
          'accountType': accountType,
          'interests': interests,
        }),
      );

      final responseData = json.decode(response.body);
      print('Response from updateFullProfile: $responseData');
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Profile update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
    int userId,
    File imageFile,
  ) async {
    try {
      print('🚀 Starting image upload for user $userId. File: ${imageFile.path}');
      
      if (!await imageFile.exists()) {
        return {'success': false, 'message': 'Image file does not exist locally.'};
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl1/cloudinary/$userId/image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Send the request with a timeout (60 seconds for large images)
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timed out. Please check your connection.');
        },
      );

      var responseData = await streamedResponse.stream.bytesToString();
      print('📡 Server Response ($userId): $responseData');

      if (responseData.trim().isEmpty) {
        return {'success': false, 'message': 'Server returned an empty response.'};
      }

      // Safeguard against non-JSON responses (like HTML error pages)
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseData);
      } catch (e) {
        print('❌ JSON Decode Error: $e. Response was: $responseData');
        return {
          'success': false, 
          'message': 'Server returned an invalid format. Please try again later.'
        };
      }

      if (streamedResponse.statusCode == 200) {
        return {'success': true, 'imageUrl': jsonResponse['imageUrl']};
      } else {
        return {
          'success': false,
          'message': jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to upload image (${streamedResponse.statusCode})',
        };
      }
    } catch (e) {
      print('💥 uploadProfileImage Exception: $e');
      return {'success': false, 'message': 'Error uploading image: ${e.toString()}'};
    }
  }

  // Add this method to your UserService class

  Future<Map<String, dynamic>> updatePremiumStatusByEmail({
    required String email,
    required bool isPremium,
    String? paymentId,
  }) async {
    try {
      print('🌐 Calling backend to update premium status...');
      print('📧 Email: $email');
      print('💎 isPremium: $isPremium');
      print('💳 Payment ID: $paymentId');

      final response = await client.put(
        Uri.parse(
          '$_baseUrl/update-premium-status',
        ), // Using _baseUrl which is the auth endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'isPremium': isPremium,
          if (paymentId != null)
            'paymentId': paymentId, // Optional field for tracking
        }),
      );

      print('📡 Response status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Premium status updated successfully on backend');
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        print('❌ Backend returned error: ${responseData['error']}');
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to update premium status',
        };
      }
    } catch (e) {
      print('💥 Exception in updatePremiumStatusByEmail: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // ---- Forgot Password Flow ----

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['error'] ?? 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  // Request account deletion (Sends email to admin)
  Future<Map<String, dynamic>> requestAccountDeletion({
    required String userId,
    required String fullname,
    required String email,
    required String phonenumber,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/request-deletion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'fullname': fullname,
          'email': email,
          'phonenumber': phonenumber,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Deletion request sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to send deletion request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

