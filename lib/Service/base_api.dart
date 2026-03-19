import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BaseApiService {

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://api.therockofpraise.org/api';
    } else if (Platform.isIOS) {
      return 'https://api.therockofpraise.org/api';
    } else {
      return 'https://api.therockofpraise.org/api';
    }
  }

  final http.Client client;
  final Duration timeout;

  BaseApiService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : client = client ?? http.Client();

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('GET Request: $url');

      final response = await client
          .get(url, headers: _getHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('POST Request: $url');
      print('POST Data: ${json.encode(data)}');

      final response = await client
          .post(url, headers: _getHeaders(), body: json.encode(data))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('PUT Request: $url');

      final response = await client
          .put(url, headers: _getHeaders(), body: json.encode(data))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('DELETE Request: $url');

      final response = await client
          .delete(url, headers: _getHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Get headers
  Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    try {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['error'] ??
              responseData['message'] ??
              'Request failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Invalid response format',
        'error': e.toString(),
      };
    }
  }

  // Handle errors
  Map<String, dynamic> _handleError(dynamic error) {
    print('API Error: $error');

    if (error.toString().contains('Connection refused')) {
      return {
        'success': false,
        'message':
            'Cannot connect to server. Please ensure your backend is running.',
        'error': error.toString(),
      };
    } else if (error.toString().contains('timeout')) {
      return {
        'success': false,
        'message': 'Connection timeout. Please check your internet connection.',
        'error': error.toString(),
      };
    } else {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${error.toString()}',
        'error': error.toString(),
      };
    }
  }

  // Health check
  Future<bool> checkServerHealth() async {
    try {
      final result = await get('/health');
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Get current base URL for debugging
  String getCurrentBaseUrl() => baseUrl;

  // Dispose client
  void dispose() {
    client.close();
  }
}