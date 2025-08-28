import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';


class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

   
    final userMessage = ChatMessage(
      text: text,
      isBot: false,
    );
    
    _messages.insert(0, userMessage);
    _isTyping = true;
    notifyListeners();

    
    Future.delayed(Duration(seconds: 2), () {
      _addBotMessage("API response will go here");
    });
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
    notifyListeners();
  }
}

