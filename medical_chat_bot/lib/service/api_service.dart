import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static String? _accessToken;
  
  static void setAccessToken(String token) {
    _accessToken = token;
  }
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
  
  static Future<Map<String, dynamic>> startConversation(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: headers,
      body: jsonEncode({'query': query}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start conversation: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> continueConversation(String threadId, String query) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/chat'),
      headers: headers,
      body: jsonEncode({
        'thread_id': threadId,
        'query': query,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to continue conversation: ${response.statusCode}');
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: {
        'email': email,
        'password': password,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setAccessToken(data['access_token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }
}