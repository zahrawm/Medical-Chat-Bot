import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:medical_chat_bot/service/api_service.dart';



class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _currentThreadId;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  String? get currentThreadId => _currentThreadId;

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _errorMessage = null;
    
    final userMessage = ChatMessage(
      text: text,
      isBot: false,
    );

    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      Map<String, dynamic> response;
      
      if (_currentThreadId == null) {
        
        response = await ApiService.startConversation(text);
        _currentThreadId = response['thread_id'];
      } else {
       
        response = await ApiService.continueConversation(_currentThreadId!, text);
      }

    
      String botResponseText = response['response'] ?? response['message'] ?? 'No response received';
      
      _addBotMessage(botResponseText);
      
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      _addBotMessage('Sorry, I encountered an error. Please try again.');
    }
  }

  void _addBotMessage(String text) {
    final botMessage = ChatMessage(
      text: text,
      isBot: true,
    );

    _messages.insert(0, botMessage);
    _isTyping = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _isTyping = false;
    _currentThreadId = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}