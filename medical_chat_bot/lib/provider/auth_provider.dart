import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class AuthProvider with ChangeNotifier {
  static const String baseUrl = 'http://localhost:8080'; 
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _currentUser = '';
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  AuthProvider() {
    _loadTokenFromStorage();
  }

  
  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      _currentUser = prefs.getString('current_user') ?? '';
      
      if (_accessToken != null && _currentUser.isNotEmpty) {
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading tokens: $e');
    }
  }


  Future<void> _saveTokensToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      await prefs.setString('current_user', _currentUser);
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/login'),
      );
      
      request.fields['email'] = email;
      request.fields['password'] = password;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _currentUser = email;
        _errorMessage = '';
        
        await _saveTokensToStorage();
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Login failed';
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'Network error: Please check your connection';
      _isAuthenticated = false;
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(
    String email,
    String password,
    String confirmPassword, {
    String? username,
    String? firstName,
    String? lastName,
    String? dob,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username ?? email.split('@')[0], 
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'email': email,
          'password': password,
          'dob': dob ?? '1990-01-01',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        _errorMessage = '';
        _isAuthenticated = false;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Registration failed';
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'Network error: Please check your connection';
      _isAuthenticated = false;
      print('Signup error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    if (_refreshToken == null || _currentUser.isEmpty) return false;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/refresh'),
      );
      
      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.fields['email'] = _currentUser;
      request.fields['refresh_token'] = _refreshToken!;
      request.fields['grant_type'] = 'refresh_token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _saveTokensToStorage();
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return false;
  }

  void logout() async {
    _isAuthenticated = false;
    _currentUser = '';
    _accessToken = null;
    _refreshToken = null;
    

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('current_user');
    } catch (e) {
      print('Error clearing storage: $e');
    }
    
    notifyListeners();
  }
}