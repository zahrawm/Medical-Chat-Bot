import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _currentUser = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get currentUser => _currentUser;

  // Mock user database
  final Map<String, String> _users = {'test@example.com': 'password123'};

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(Duration(seconds: 1));

    if (_users.containsKey(email) && _users[email] == password) {
      _isAuthenticated = true;
      _currentUser = email;
      _errorMessage = '';
    } else {
      _errorMessage = 'Invalid email or password';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(
    String email,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(Duration(seconds: 1));

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
    } else if (_users.containsKey(email)) {
      _errorMessage = 'User already exists';
    } else if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
    } else {
      _users[email] = password;
      _isAuthenticated = true;
      _currentUser = email;
      _errorMessage = '';
    }

    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = '';
    notifyListeners();
  }
}
