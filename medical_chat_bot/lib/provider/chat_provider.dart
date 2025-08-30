import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:medical_chat_bot/service/api_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _currentThreadId;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._apiService);

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    try {
      _setLoading(true);
      _setError(null);

      
      _messages.add(Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();

      Map<String, dynamic> response;

      if (_currentThreadId == null) {
        response = await _apiService.startConversation(message);
        _currentThreadId = response['thread_id'];
      } else {
        response = await _apiService.continueConversation(_currentThreadId!, message);
      }

      _messages.add(Message(
        content: response['response'] ?? response['message'] ?? 'No response',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _setError(e.toString());
      _messages.add(Message(
        content: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _setLoading(false);
    }
  }

  void clearChat() {
    _messages.clear();
    _currentThreadId = null;
    _error = null;
    notifyListeners();
  }
}
