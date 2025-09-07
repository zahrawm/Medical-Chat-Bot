import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:medical_chat_bot/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  ApiService get apiService => _apiService;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final response = await _apiService.login(email, password);
      
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);

      await _getUserProfile();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String email,
    required String dob,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _apiService.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
        email: email,
        dob: dob,
      );
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getUserProfile() async {
    try {
      final profile = await _apiService.getUserProfile();
      _user = User.fromJson(profile);
      notifyListeners();
    } catch (e) {
      print('Failed to get user profile: $e');
    }
  }
  // In your AuthProvider class
Future<bool> updateProfile({
  required String username,
  required String firstName,
  required String lastName,
  required String dob,
}) async {
  try {
    // Make API call to update profile
    // Update local user data
    // Return success status
    return true;
  } catch (e) {
    // Handle error
    return false;
  }
}

  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      _apiService.setAccessToken(token);
      await _getUserProfile();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _user = null;
    _apiService.setAccessToken('');
    notifyListeners();
    return Future.value();
  }
}

