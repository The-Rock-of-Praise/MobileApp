import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorshipNotesService {
  static const String _baseUrl = 'https://api.therockofpraise.org/api/worship-notes';
  final http.Client client;

  WorshipNotesService({http.Client? client}) : client = client ?? http.Client();

  // Helper method to get user ID from shared preferences
  static Future<String> _getUserID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      return userId != null ? userId.toString() : '';
    } catch (e) {
      print('Error loading user ID: $e');
      return '';
    }
  }

  // Create a new worship note
  Future<Map<String, dynamic>> createWorshipNote(String note) async {
    try {
      final userId = await _getUserID();
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'No user ID found. Please login again.',
        };
      }

      final response = await client.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': int.parse(userId), 'note': note}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Note created successfully',
          'note': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to create note',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get all worship notes for the current user
  Future<Map<String, dynamic>> getUserWorshipNotes() async {
    try {
      final userId = await _getUserID();
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'No user ID found. Please login again.',
        };
      }

      final response = await client.get(
        Uri.parse('$_baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'notes': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to fetch notes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get a single worship note by ID
  Future<Map<String, dynamic>> getWorshipNote(String noteId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/$noteId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'note': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to fetch note',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Update a worship note
  Future<Map<String, dynamic>> updateWorshipNote({
    required String noteId,
    required String note,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl/$noteId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'note': note}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Note updated successfully',
          'note': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to update note',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Delete a worship note
  Future<Map<String, dynamic>> deleteWorshipNote(String noteId) async {
    try {
      final response = await client.delete(
        Uri.parse('$_baseUrl/$noteId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Note deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to delete note',
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
