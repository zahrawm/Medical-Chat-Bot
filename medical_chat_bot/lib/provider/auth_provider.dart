import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:medical_chat_bot/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false; // Track if initial auth check is complete
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
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

      // Check if login failed
      if (response == "Incorrect Username") {
        _setError("Invalid email or password");
        return false;
      }

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);

      await _getUserProfile();

      return true;
    } catch (e) {
      _setError("Login failed. Please check your credentials.");
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
      if (e.toString().contains('already exists') ||
          e.toString().contains('duplicate')) {
        _setError("Username or email already exists");
      } else if (e.toString().contains('password')) {
        _setError("Password requirements not met");
      } else {
        _setError("Registration failed. Please try again.");
      }
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
      // If profile fetch fails, clear the token as it might be invalid
      await _clearInvalidToken();
    }
  }

  Future<void> _clearInvalidToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _user = null;
    _apiService.setAccessToken('');
  }

  Future<bool> updateProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String dob,
  }) async {
    try {
      _setLoading(true);

      // Since User properties are final, we need to create a new User object
      if (_user != null) {
        _user = User(
          username: username,
          firstName: firstName,
          lastName: lastName,
          email: _user!.email, // Keep existing email
          dob: dob,
        );
        notifyListeners(); // This will trigger UI updates
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSavedToken() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null && token.isNotEmpty) {
        _apiService.setAccessToken(token);
        await _getUserProfile();
      }
    } catch (e) {
      print('Error loading saved token: $e');
      // Clear any invalid token
      await _clearInvalidToken();
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      _user = null;
      _apiService.setAccessToken('');
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Method to refresh user data
  Future<void> refreshUser() async {
    if (_user != null) {
      await _getUserProfile();
    }
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }
}
