import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://liveapi.tybhealth.com';
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: formHeaders,
            body: {'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        return data;
      } else {
        throw Exception(
          'Login failed: ${response.statusCode} - ${response.body}',
        );
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Registration failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> startConversation(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: headers,
            body: json.encode({'query': query}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to start conversation: ${response.statusCode} - ${response.body}',
        );
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
      final response = await http
          .patch(
            Uri.parse('$baseUrl/chat'),
            headers: headers,
            body: json.encode({'thread_id': threadId, 'query': query}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to continue conversation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Continue conversation error: $e');
    }
  }

  // Get all conversation history from backend - UPDATED
  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      print(
        'Fetching conversation history from: $baseUrl/get-all-user-conversations',
      );
      print('Using headers: $headers');

      final response = await http
          .get(
            Uri.parse('$baseUrl/get-all-user-conversations'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Conversation history response status: ${response.statusCode}');
      print('Conversation history response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats from your backend
        List<Map<String, dynamic>> conversations = [];

        if (data is List) {
          conversations = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          // Try different possible keys that your backend might use
          if (data.containsKey('conversations')) {
            conversations = List<Map<String, dynamic>>.from(
              data['conversations'],
            );
          } else if (data.containsKey('data')) {
            var dataValue = data['data'];
            if (dataValue is List) {
              conversations = List<Map<String, dynamic>>.from(dataValue);
            } else if (dataValue is Map) {
              conversations = [Map<String, dynamic>.from(dataValue)];
            }
          } else if (data.containsKey('history')) {
            conversations = List<Map<String, dynamic>>.from(data['history']);
          } else if (data.containsKey('chats')) {
            conversations = List<Map<String, dynamic>>.from(data['chats']);
          } else {
            // If no recognized key, assume the whole response is the conversation data
            conversations = [Map<String, dynamic>.from(data)];
          }
        }

        print('Parsed ${conversations.length} conversations from backend');
        return conversations;
      } else if (response.statusCode == 401) {
        // Handle unauthorized - token might be expired
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        // No conversations found - return empty list
        print('No conversations found (404)');
        return [];
      } else {
        throw Exception(
          'Failed to get conversation history: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Get conversation history error: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      }
      throw Exception('Failed to load conversation history: $e');
    }
  }

  // Get specific conversation messages from backend - UPDATED
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String threadId,
  ) async {
    try {
      print('Fetching messages for thread: $threadId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/get-user-conversation?thread_id=$threadId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Conversation messages response status: ${response.statusCode}');
      print('Conversation messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> messages = [];

        if (data is List) {
          messages = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data.containsKey('messages')) {
            messages = List<Map<String, dynamic>>.from(data['messages']);
          } else if (data.containsKey('data')) {
            var dataValue = data['data'];
            if (dataValue is List) {
              messages = List<Map<String, dynamic>>.from(dataValue);
            }
          } else if (data.containsKey('history')) {
            messages = List<Map<String, dynamic>>.from(data['history']);
          } else if (data.containsKey('conversation')) {
            messages = List<Map<String, dynamic>>.from(data['conversation']);
          }
        }

        print('Parsed ${messages.length} messages from backend');
        return messages;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        print('No messages found for thread (404)');
        return [];
      } else {
        throw Exception(
          'Failed to get conversation messages: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Get conversation messages error: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      }
      throw Exception('Failed to load conversation messages: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users/profile'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to get user profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Get profile error: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      print('Connection test - Status: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
