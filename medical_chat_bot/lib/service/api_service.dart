 import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://chat.tybhealth.com';
  String? _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Map<String, String> get formHeaders => {
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: formHeaders,
        body: {'email': email, 'password': password},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String email,
    required String dob,
  }) async {
    try {
      final requestBody = {
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'email': email,
        'dob': dob,
      };

      print('Registration request URL: $baseUrl/auth/register');
      print('Registration request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> startConversation(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: json.encode({'query': query}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to start conversation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Start conversation error: $e');
    }
  }

  Future<Map<String, dynamic>> continueConversation(
    String threadId,
    String query,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: json.encode({'thread_id': threadId, 'query': query}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to continue conversation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Continue conversation error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Get profile error: $e');
    }
  }

 
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');
      final response = await http.get(
        Uri.parse(baseUrl),
      ).timeout(const Duration(seconds: 10));
      
      print('Connection test - Status: ${response.statusCode}');
      return response.statusCode < 500; 
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}