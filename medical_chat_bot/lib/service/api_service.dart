// api_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://liveapi.tybhealth.com';
  String? _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> get headers async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> get formHeaders async {
    final token = await _getAccessToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future login(String email, String password) async {
    final url = '$baseUrl/auth/login';
    final body = {'email': email, 'password': password};

    try {
      log('🚀 Starting login process', name: 'login');
      log('📤 URL: $url', name: 'login');
      log('📤 Request body: $body', name: 'login');

      final response = await http
          .post(Uri.parse(url), headers: await formHeaders, body: body)
          .timeout(const Duration(seconds: 30));

      log('📥 Response status: ${response.statusCode}', name: 'login');
      log('📥 Response body: ${response.body}', name: 'login');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Login successful', name: 'login');
        return data;
      } else {
        log('❌ Login failed: ${response.statusCode}', name: 'login');
        return "Incorrect Username";
      }
    } catch (e) {
      log('💥 Login error: $e', name: 'login');
      return "Incorrect Username";
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
    final url = '$baseUrl/auth/register';
    final requestBody = {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'email': email,
      'dob': dob,
    };

    try {
      log('🚀 Starting registration process', name: 'register');
      log('📤 URL: $url', name: 'register');
      log('📤 Request body: $requestBody', name: 'register');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      log('📥 Response status: ${response.statusCode}', name: 'register');
      log('📥 Response body: ${response.body}', name: 'register');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        log('✅ Registration successful', name: 'register');
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        log('❌ Registration failed: ${response.statusCode}', name: 'register');
        return {
          'success': false,
          'error': error['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      log('💥 Registration error: $e', name: 'register');
      return {'success': false, 'error': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>> startConversation(String message) async {
    final url = '$baseUrl/chat';
    final requestBody = {'query': message};

    try {
      log('🚀 Starting new conversation', name: 'start_conversation');
      log('📤 URL: $url', name: 'start_conversation');
      log('📤 Request body: $requestBody', name: 'start_conversation');

      final response = await http
          .post(
            Uri.parse(url),
            headers: await headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      log(
        '📥 Response status: ${response.statusCode}',
        name: 'start_conversation',
      );
      log('📥 Response body: ${response.body}', name: 'start_conversation');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Conversation started successfully', name: 'start_conversation');
        return data;
      } else {
        log(
          '❌ Failed to start conversation: ${response.statusCode}',
          name: 'start_conversation',
        );
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      log('💥 Conversation start error: $e', name: 'start_conversation');
      throw Exception('Failed to start conversation: $e');
    }
  }

  Future<Map<String, dynamic>> continueConversation(
    String threadId,
    String message,
  ) async {
    final url = '$baseUrl/chat';
    final requestBody = {'thread_id': threadId, 'query': message};

    try {
      log(
        '🔄 Continuing conversation: $threadId',
        name: 'continue_conversation',
      );
      log('📤 URL: $url', name: 'continue_conversation');
      log('📤 Request body: $requestBody', name: 'continue_conversation');

      final response = await http
          .post(
            Uri.parse(url),
            headers: await headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      log(
        '📥 Response status: ${response.statusCode}',
        name: 'continue_conversation',
      );
      log('📥 Response body: ${response.body}', name: 'continue_conversation');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log(
          '✅ Conversation continued successfully',
          name: 'continue_conversation',
        );
        return data;
      } else {
        log(
          '❌ Failed to continue conversation: ${response.statusCode}',
          name: 'continue_conversation',
        );
        throw Exception(
          'Failed to continue conversation: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Conversation continue error: $e', name: 'continue_conversation');
      throw Exception('Failed to continue conversation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    final url = '$baseUrl/get-all-user-conversations';

    try {
      log('📋 Fetching conversation history', name: 'get_history');
      log('📤 URL: $url', name: 'get_history');

      final response = await http
          .get(Uri.parse(url), headers: await headers)
          .timeout(const Duration(seconds: 30));

      log('📥 Response status: ${response.statusCode}', name: 'get_history');
      log('📥 Response body: ${response.body}', name: 'get_history');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ History fetched successfully', name: 'get_history');
        return List<Map<String, dynamic>>.from(data);
      } else {
        log(
          '❌ Failed to fetch history: ${response.statusCode}',
          name: 'get_history',
        );
        throw Exception('Failed to fetch conversation history');
      }
    } catch (e) {
      log('💥 History fetch error: $e', name: 'get_history');
      throw Exception('Failed to fetch conversation history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(
    String threadId,
  ) async {
    final url = '$baseUrl/get-user-conversation?thread_id=$threadId';

    try {
      log('💬 Fetching messages for thread: $threadId', name: 'get_messages');
      log('📤 URL: $url', name: 'get_messages');

      final response = await http
          .get(Uri.parse(url), headers: await headers)
          .timeout(const Duration(seconds: 30));

      log('📥 Response status: ${response.statusCode}', name: 'get_messages');
      log('📥 Response body: ${response.body}', name: 'get_messages');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('messages')) {
          final messages = data['messages'];
          if (messages is List) {
            log('✅ Messages fetched successfully', name: 'get_messages');
            return List<Map<String, dynamic>>.from(messages);
          }
        }

        log('⚠️ No messages found in response', name: 'get_messages');
        return [];
      } else {
        log(
          '❌ Failed to fetch messages: ${response.statusCode}',
          name: 'get_messages',
        );
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      log('💥 Messages fetch error: $e', name: 'get_messages');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final url = '$baseUrl/users/profile';

    try {
      log('👤 Fetching user profile', name: 'get_profile');
      log('📤 URL: $url', name: 'get_profile');

      final response = await http
          .get(Uri.parse(url), headers: await headers)
          .timeout(const Duration(seconds: 30));

      log('📥 Response status: ${response.statusCode}', name: 'get_profile');
      log('📥 Response body: ${response.body}', name: 'get_profile');

      if (response.statusCode == 200) {
        log('✅ Profile fetched successfully', name: 'get_profile');
        return json.decode(response.body);
      } else {
        log(
          '❌ Failed to fetch profile: ${response.statusCode}',
          name: 'get_profile',
        );
        throw Exception(
          'Failed to get user profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      log('💥 Profile fetch error: $e', name: 'get_profile');
      throw Exception('Get profile error: $e');
    }
  }
}
