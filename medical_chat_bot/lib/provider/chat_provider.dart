// chat_provider.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:medical_chat_bot/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _currentThreadId;
  String? _currentConversationId;
  List<Message> _messages = [];
  List<ConversationHistory> _conversationHistory = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  bool _disposed = false;
  bool _isLoadingConversation = false;
  bool _isLoadingHistory = false;
  bool _isSyncingWithBackend = false;

  // Cache for messages to prevent blank screen
  Map<String, List<Message>> _messageCache = {};

  ChatProvider(this._apiService) {
    _loadConversationHistory();
  }

  // Getters
  List<Message> get messages => _messages;
  List<ConversationHistory> get conversationHistory => _conversationHistory;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get error => _error;
  String? get currentConversationId => _currentConversationId;
  bool get isLoadingConversation => _isLoadingConversation;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSyncingWithBackend => _isSyncingWithBackend;
  String? get accessToken => _apiService.accessToken;

  // Private state setters
  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingConversation(bool loading) {
    if (_disposed) return;
    _isLoadingConversation = loading;
    notifyListeners();
  }

  void _setLoadingHistory(bool loading) {
    if (_disposed) return;
    _isLoadingHistory = loading;
    notifyListeners();
  }

  void _setSyncingWithBackend(bool syncing) {
    if (_disposed) return;
    _isSyncingWithBackend = syncing;
    notifyListeners();
  }

  void _setTyping(bool typing) {
    if (_disposed) return;
    _isTyping = typing;
    notifyListeners();
  }

  void _setError(String? error) {
    if (_disposed) return;
    _error = error;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadConversation(String conversationId) async {
    if (_disposed) return;

    if (conversationId.isEmpty) {
      _setError('Invalid conversation ID');
      return;
    }

    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      return;
    }

    try {
      _setLoadingConversation(true);
      _setError(null);

      if (_currentConversationId != null &&
          _currentConversationId != conversationId &&
          _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      final conversation = getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found in history');
      }

      if (conversation.id.isEmpty) {
        throw Exception('Invalid conversation: missing ID');
      }

      final previousConversationId = _currentConversationId;
      final previousMessages = List<Message>.from(_messages);

      _currentConversationId = conversationId;

      // Use threadId from the conversation for backend API calls
      if (conversation.threadId != null) {
        _currentThreadId = conversation.threadId;
      }

      List<Message> loadedMessages = [];
      bool loadSuccess = false;

      // Try to load from backend first (using threadId)
      if (conversation.threadId != null) {
        try {
          loadedMessages = await loadConversationFromBackend(
            conversation.threadId!, // Use threadId for backend API
          );
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
          }
        } catch (e) {
          print('Failed to load from backend: $e');
          // Continue to try other sources
        }
      }

      if (!loadSuccess) {
        try {
          loadedMessages = await _loadConversationFromLocal(conversationId);
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
          }
        } catch (e) {
          print('Failed to load from local: $e');
          // Continue to try cache
        }
      }

      if (!loadSuccess && _messageCache.containsKey(conversationId)) {
        loadedMessages = List.from(_messageCache[conversationId]!);
        if (loadedMessages.isNotEmpty) {
          loadSuccess = true;
        }
      }

      if (loadSuccess || loadedMessages.isEmpty) {
        _messages = loadedMessages;
        if (loadedMessages.isNotEmpty) {
          _messageCache[conversationId] = List.from(loadedMessages);
        }
      } else {
        _currentConversationId = previousConversationId;
        _messages = previousMessages;
        throw Exception('Failed to load conversation messages');
      }

      _setLoadingConversation(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversation: ${e.toString()}');
      _setLoadingConversation(false);
      notifyListeners();
    }
  }

  Future<List<Message>> loadConversationFromBackend(
    String conversationId,
  ) async {
    try {
      final backendMessages = await _apiService.getConversationMessages(
        conversationId,
      );

      if (backendMessages.isNotEmpty) {
        List<Message> convertedMessages = [];

        for (var item in backendMessages) {
          log('Processing backend message: $item', name: 'message_conversion');
          if (item.containsKey('input') && item.containsKey('output')) {
            String userInput = item['input']?.toString().trim() ?? '';
            if (userInput.isNotEmpty) {
              DateTime userTimestamp = _parseTimestamp(item['date']);

              convertedMessages.add(
                Message(
                  content: userInput,
                  isUser: true,
                  timestamp: userTimestamp,
                ),
              );
            }

            String botOutput = item['output']?.toString().trim() ?? '';
            if (botOutput.isNotEmpty) {
              DateTime botTimestamp = _parseTimestamp(item['date']);

              botTimestamp = botTimestamp.add(Duration(seconds: 1));

              convertedMessages.add(
                Message(
                  content: botOutput,
                  isUser: false,
                  timestamp: botTimestamp,
                ),
              );
            }
          } else {
            final message = _convertBackendToMessage(item);
            if (message != null) {
              convertedMessages.add(message);
            }
          }
        }

        if (convertedMessages.isNotEmpty) {
          convertedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          try {
            await _saveMessagesToLocal(conversationId, convertedMessages);
          } catch (e) {
            // Continue without saving
          }

          // UPDATE: Set the messages and notify listeners
          if (!_disposed) {
            _messages = convertedMessages;
            _messageCache[conversationId] = List.from(convertedMessages);
            notifyListeners();
          }

          return convertedMessages;
        }
      }

      // UPDATE: Clear messages if none found and notify listeners
      if (!_disposed) {
        _messages = [];
        notifyListeners();
      }
      return [];
    } catch (e) {
      // UPDATE: Clear messages on error and notify listeners
      if (!_disposed) {
        _messages = [];
        notifyListeners();
      }
      throw e;
    }
  }

  Future<List<Message>> _loadConversationFromLocal(
    String conversationId,
  ) async {
    try {
      if (conversationId.isEmpty) {
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          prefs.getStringList('messages_$conversationId') ?? [];

      if (messagesJson.isNotEmpty) {
        final loadedMessages = <Message>[];
        for (String json in messagesJson) {
          try {
            final messageData = jsonDecode(json);
            final message = Message.fromJson(messageData);
            loadedMessages.add(message);
          } catch (e) {
            // Skip corrupted messages
          }
        }

        if (loadedMessages.isNotEmpty) {
          return loadedMessages;
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Message? _convertBackendToMessage(Map<String, dynamic> item) {
    try {
      String content = '';

      if (item.containsKey('query') &&
          item['query'] != null &&
          item['query'].toString().trim().isNotEmpty) {
        content = item['query'].toString().trim();
      } else if (item.containsKey('answer') &&
          item['answer'] != null &&
          item['answer'].toString().trim().isNotEmpty) {
        content = item['answer'].toString().trim();
      } else if (item.containsKey('message') &&
          item['message'] != null &&
          item['message'].toString().trim().isNotEmpty) {
        content = item['message'].toString().trim();
      } else if (item.containsKey('content') &&
          item['content'] != null &&
          item['content'].toString().trim().isNotEmpty) {
        content = item['content'].toString().trim();
      } else if (item.containsKey('text') &&
          item['text'] != null &&
          item['text'].toString().trim().isNotEmpty) {
        content = item['text'].toString().trim();
      } else if (item.containsKey('body') &&
          item['body'] != null &&
          item['body'].toString().trim().isNotEmpty) {
        content = item['body'].toString().trim();
      }

      if (content.isEmpty) {
        return null;
      }

      bool isUser = false;

      if (item.containsKey('is_user')) {
        isUser =
            item['is_user'] == true ||
            item['is_user'] == 1 ||
            item['is_user'] == '1' ||
            item['is_user'] == 'true';
      } else if (item.containsKey('from_user')) {
        isUser =
            item['from_user'] == true ||
            item['from_user'] == 1 ||
            item['from_user'] == '1' ||
            item['from_user'] == 'true';
      } else if (item.containsKey('role')) {
        String role = item['role']?.toString().toLowerCase() ?? '';
        isUser = role == 'user' || role == 'human';
      } else if (item.containsKey('sender')) {
        String sender = item['sender']?.toString().toLowerCase() ?? '';
        isUser = sender == 'user' || sender == 'human';
      } else if (item.containsKey('type')) {
        String type = item['type']?.toString().toLowerCase() ?? '';
        isUser = type == 'user' || type == 'query' || type == 'human';
      } else if (item.containsKey('message_type')) {
        String msgType = item['message_type']?.toString().toLowerCase() ?? '';
        isUser = msgType == 'user' || msgType == 'query' || msgType == 'human';
      } else {
        if (item.containsKey('query') && !item.containsKey('answer')) {
          isUser = true;
        } else if (item.containsKey('answer') && !item.containsKey('query')) {
          isUser = false;
        } else if (item.containsKey('query') && item.containsKey('answer')) {
          if (content == item['query']?.toString().trim()) {
            isUser = true;
          } else if (content == item['answer']?.toString().trim()) {
            isUser = false;
          } else {
            isUser = false;
          }
        }
      }

      DateTime timestamp = _parseTimestamp(
        item['timestamp'] ??
            item['created_at'] ??
            item['sent_at'] ??
            item['date'] ??
            item['time'] ??
            item['created'] ??
            DateTime.now().millisecondsSinceEpoch,
      );

      return Message(content: content, isUser: isUser, timestamp: timestamp);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadConversationHistory() async {
    try {
      _setLoadingHistory(true);

      // Wait for the access token to be loaded from SharedPreferences
      await Future.delayed(Duration(milliseconds: 100));

      // Try to get the token from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        _apiService.setAccessToken(token);
        await _syncConversationHistoryFromBackend();
      } else {
        _conversationHistory.clear();
        notifyListeners();
      }

      _setLoadingHistory(false);
    } catch (e) {
      _setLoadingHistory(false);
      _setError('Failed to load conversation history');
    }
  }

  Future<void> _syncConversationHistoryFromBackend() async {
    if (_apiService.accessToken == null) return;

    try {
      _setSyncingWithBackend(true);

      List<Map<String, dynamic>> backendHistory = [];
      try {
        backendHistory = await _apiService.getConversationHistory();
      } catch (e) {
        _setSyncingWithBackend(false);
        if (e.toString().contains('Authentication failed')) {
          _setError('Authentication failed. Please log in again.');
        } else {
          _setError('Failed to load conversation history from server');
        }
        return;
      }

      List<ConversationHistory> backendConversations = [];

      for (var item in backendHistory) {
        try {
          final conversation = _convertBackendToConversationHistory(item);
          if (conversation != null) {
            if (conversation.id.isNotEmpty && conversation.title.isNotEmpty) {
              backendConversations.add(conversation);
            }
          }
        } catch (e) {
          // Skip invalid items
        }
      }

      _conversationHistory = backendConversations;
      _conversationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _setSyncingWithBackend(false);
      notifyListeners();
    } catch (e) {
      _setSyncingWithBackend(false);
      _setError('Failed to load conversation history from server');
    }
  }

  ConversationHistory? _convertBackendToConversationHistory(
    Map<String, dynamic> item,
  ) {
    try {
      String? id =
          item['id']?.toString() ??
          item['conversation_id']?.toString() ??
          item['chat_id']?.toString();

      if (id == null || id.isEmpty) {
        return null;
      }

      String title =
          item['title']?.toString() ??
          item['name']?.toString() ??
          item['subject']?.toString() ??
          item['conversation_title']?.toString() ??
          'Untitled Conversation';

      title = title.trim();
      if (title.isEmpty) {
        title = 'Conversation ${id.substring(0, 8)}';
      }

      String lastMessage =
          item['last_message']?.toString() ??
          item['lastMessage']?.toString() ??
          item['preview']?.toString() ??
          title;

      if (lastMessage.length > 50) {
        lastMessage = lastMessage.substring(0, 50) + '...';
      }

      DateTime timestamp = _parseTimestamp(
        item['updated_at'] ??
            item['created_at'] ??
            item['last_activity'] ??
            item['timestamp'],
      );

      int messageCount = _parseMessageCount(
        item['message_count'] ??
            item['messageCount'] ??
            item['total_messages'] ??
            item['count'],
      );

      if (messageCount == 0) {
        messageCount = _estimateMessageCountFromTokens(
          item['total_tokens'],
          item['total_prompt_tokens'],
          item['total_completion_tokens'],
        );
      }

      String? threadId =
          item['thread_id']?.toString() ??
          item['threadId']?.toString() ??
          item['session_id']?.toString();

      return ConversationHistory(
        id: id,
        title: title,
        lastMessage: lastMessage,
        timestamp: timestamp,
        messageCount: messageCount,
        threadId: threadId,
      );
    } catch (e) {
      return null;
    }
  }

  int _estimateMessageCountFromTokens(
    dynamic totalTokens,
    dynamic promptTokens,
    dynamic completionTokens,
  ) {
    try {
      int total = _parseMessageCount(totalTokens ?? 0);
      int prompt = _parseMessageCount(promptTokens ?? 0);
      int completion = _parseMessageCount(completionTokens ?? 0);

      if (total == 0) return 0;

      int estimatedUserMessages = (prompt / 150).ceil();
      int estimatedBotMessages = (completion / 200).ceil();

      int estimatedTotal = estimatedUserMessages + estimatedBotMessages;

      return estimatedTotal > 0 ? estimatedTotal : (total > 0 ? 2 : 0);
    } catch (e) {
      return 0;
    }
  }

  int _parseMessageCount(dynamic count) {
    if (count == null) return 0;
    if (count is int) return count;
    if (count is String) {
      return int.tryParse(count) ?? 0;
    }
    return 0;
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    try {
      if (timestamp is int) {
        if (timestamp > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          final intTimestamp = int.tryParse(timestamp);
          if (intTimestamp != null) {
            if (intTimestamp > 1000000000000) {
              return DateTime.fromMillisecondsSinceEpoch(intTimestamp);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(intTimestamp * 1000);
            }
          }
        }
      }
    } catch (e) {
      // Fall through to return current time
    }

    return DateTime.now();
  }

  Future<void> _saveMessagesToLocal(
    String conversationId,
    List<Message> messages,
  ) async {
    try {
      if (conversationId.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();

      await prefs.setStringList('messages_$conversationId', messagesJson);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> clearCurrentConversation() async {
    if (_disposed) return;

    try {
      if (_currentConversationId != null && _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      _messages.clear();
      _currentThreadId = null;
      _currentConversationId = null;
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;

      notifyListeners();
    } catch (e) {
      _messages.clear();
      _currentThreadId = null;
      _currentConversationId = null;
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentConversation() async {
    if (_currentConversationId == null || _messages.isEmpty) return;

    try {
      await _saveMessagesToLocal(_currentConversationId!, _messages);
      _messageCache[_currentConversationId!] = List.from(_messages);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> sendMessage(String message) async {
    if (_disposed) return;

    try {
      _setLoading(true);
      _setError(null);

      final userMessage = Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _messages.add(userMessage);
      notifyListeners();

      Map<String, dynamic> response;

      if (_currentThreadId == null) {
        response = await _apiService.startConversation(message);
        _currentThreadId = response['thread_id'];

        final newConversationId = DateTime.now().millisecondsSinceEpoch
            .toString();
        _currentConversationId = newConversationId;

        await _createNewConversation(message);
      } else {
        response = await _apiService.continueConversation(
          _currentThreadId!,
          message,
        );

        await _updateExistingConversation(message);
      }

      _setLoading(false);
      _setTyping(true);

      final botResponse = response['answer'] ?? 'No response';
      final botMessage = Message(
        content: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(botMessage);
      notifyListeners();

      await _saveCurrentConversation();

      final typingDuration = Duration(
        milliseconds: botResponse.length * 30 + 500,
      );
      Future.delayed(typingDuration, () {
        if (!_disposed) {
          _setTyping(false);
        }
      });
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      _setTyping(false);

      if (!_disposed) {
        _messages.add(
          Message(
            content: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    }
  }

  Future<void> _createNewConversation(String firstMessage) async {
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentConversationId = conversationId;

    final newConversation = ConversationHistory(
      id: conversationId,
      title: _generateTitle(firstMessage),
      lastMessage: firstMessage,
      timestamp: DateTime.now(),
      messageCount: 1,
      threadId: _currentThreadId,
    );

    _conversationHistory.insert(0, newConversation);
    notifyListeners();
  }

  Future<void> _updateExistingConversation(String newMessage) async {
    if (_currentConversationId == null) return;

    final index = _conversationHistory.indexWhere(
      (conv) => conv.id == _currentConversationId,
    );

    if (index != -1) {
      final current = _conversationHistory[index];
      _conversationHistory[index] = ConversationHistory(
        id: current.id,
        title: current.title,
        lastMessage: newMessage,
        timestamp: DateTime.now(),
        messageCount: _messages.length,
        threadId: current.threadId,
      );

      notifyListeners();
    }
  }

  String _generateTitle(String message) {
    if (message.length <= 30) return message;
    return message.substring(0, 30) + '...';
  }

  Future<void> clearChat() async {
    if (_disposed) return;
    await clearCurrentConversation();
  }

  Future<void> startNewConversation() async {
    if (_disposed) return;

    try {
      if (_currentConversationId != null && _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      _messages.clear();
      _currentThreadId = null;
      _currentConversationId = null;
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;

      notifyListeners();
    } catch (e) {
      _messages.clear();
      _currentThreadId = null;
      _currentConversationId = null;
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;
      notifyListeners();
    }
  }

  Future<void> loadConversationSilently(String conversationId) async {
    if (_disposed) return;

    if (conversationId.isEmpty) {
      _setError('Invalid conversation ID');
      return;
    }

    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      return;
    }

    try {
      _setLoadingConversation(true);
      _setError(null);

      if (_currentConversationId != null &&
          _currentConversationId != conversationId &&
          _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      final conversation = getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found in history');
      }

      if (conversation.id.isEmpty) {
        throw Exception('Invalid conversation: missing ID');
      }

      final previousConversationId = _currentConversationId;
      final previousMessages = List<Message>.from(_messages);

      _currentConversationId = conversationId;
      if (conversation.threadId != null) {
        _currentThreadId = conversation.threadId;
      }

      List<Message> loadedMessages = [];
      bool loadSuccess = false;

      if (_apiService.accessToken != null && _currentThreadId != null) {
        try {
          loadedMessages = await loadConversationFromBackend(_currentThreadId!);
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
          }
        } catch (e) {
          // Continue to try other sources
        }
      }

      if (!loadSuccess) {
        try {
          loadedMessages = await _loadConversationFromLocal(conversationId);
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
          }
        } catch (e) {
          // Continue to try cache
        }
      }

      if (!loadSuccess && _messageCache.containsKey(conversationId)) {
        loadedMessages = List.from(_messageCache[conversationId]!);
        if (loadedMessages.isNotEmpty) {
          loadSuccess = true;
        }
      }

      if (loadSuccess || loadedMessages.isEmpty) {
        _messages = loadedMessages;
        if (loadedMessages.isNotEmpty) {
          _messageCache[conversationId] = List.from(loadedMessages);
        }
      } else {
        _currentConversationId = previousConversationId;
        _messages = previousMessages;
        throw Exception('Failed to load conversation messages');
      }

      _isLoading = false;
      _isTyping = false;
      _setLoadingConversation(false);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversation: ${e.toString()}');
      _setLoadingConversation(false);

      _isLoading = false;
      _isTyping = false;

      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      _conversationHistory.removeWhere((conv) => conv.id == conversationId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$conversationId');

      _messageCache.remove(conversationId);

      if (_currentConversationId == conversationId) {
        _messages.clear();
        _currentThreadId = null;
        _currentConversationId = null;
        _error = null;
        _isLoading = false;
        _isTyping = false;
        _isLoadingConversation = false;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to delete conversation');
    }
  }

  Future<void> refreshConversationHistory() async {
    if (_apiService.accessToken == null) {
      _conversationHistory.clear();
      notifyListeners();
      return;
    }

    _setLoadingHistory(true);
    await _syncConversationHistoryFromBackend();
    _setLoadingHistory(false);
  }

  bool isValidConversation(String conversationId) {
    if (conversationId.isEmpty) return false;

    final conversation = _conversationHistory.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => ConversationHistory(
        id: '',
        title: '',
        lastMessage: '',
        timestamp: DateTime.now(),
        messageCount: 0,
      ),
    );

    return conversation.id.isNotEmpty;
  }

  ConversationHistory? getConversationById(String conversationId) {
    try {
      if (conversationId.isEmpty) return null;

      return _conversationHistory.firstWhere(
        (conv) => conv.id == conversationId,
      );
    } catch (e) {
      return null;
    }
  }

  String getConversationPreview(ConversationHistory conversation) {
    return '${conversation.messageCount} messages • ${_formatTime(conversation.timestamp)}';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> retryLastMessage() async {
    if (_messages.isEmpty || _disposed) return;

    Message? lastUserMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUserMessage = _messages[i];
        break;
      }
    }

    if (lastUserMessage != null) {
      _messages.removeWhere(
        (msg) =>
            !msg.isUser && msg.timestamp.isAfter(lastUserMessage!.timestamp),
      );
      await sendMessage(lastUserMessage.content);
    }
  }

  int getUserMessageCount() {
    return _messages.where((msg) => msg.isUser).length;
  }

  int getBotMessageCount() {
    return _messages.where((msg) => !msg.isUser).length;
  }

  Message? get lastMessage {
    return _messages.isNotEmpty ? _messages.last : null;
  }

  bool get lastMessageWasFromBot {
    final lastMsg = lastMessage;
    return lastMsg != null && !lastMsg.isUser;
  }

  void setCurrentConversationId(String conversationId) {
    _currentConversationId = conversationId;
    notifyListeners();
  }

  Future<void> reset() async {
    _messages.clear();
    _conversationHistory.clear();
    _messageCache.clear();
    _currentThreadId = null;
    _currentConversationId = null;
    _error = null;
    _isLoading = false;
    _isTyping = false;
    _isLoadingConversation = false;
    _isLoadingHistory = false;
    _isSyncingWithBackend = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('messages_') || key == 'conversation_history',
          )
          .toList();
      for (String key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Silently fail
    }

    notifyListeners();
  }

  Map<String, List<ConversationHistory>> groupConversationsByTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final sevenDaysAgo = today.subtract(Duration(days: 7));
    final thirtyDaysAgo = today.subtract(Duration(days: 30));

    final grouped = <String, List<ConversationHistory>>{
      'Today': [],
      'Yesterday': [],
      'Previous 7 days': [],
      'Previous 30 days': [],
      'Older': [],
    };

    for (final conversation in _conversationHistory) {
      final conversationDate = conversation.timestamp;
      final conversationDay = DateTime(
        conversationDate.year,
        conversationDate.month,
        conversationDate.day,
      );

      if (conversationDay == today) {
        grouped['Today']!.add(conversation);
      } else if (conversationDay == yesterday) {
        grouped['Yesterday']!.add(conversation);
      } else if (conversationDay.isAfter(sevenDaysAgo)) {
        grouped['Previous 7 days']!.add(conversation);
      } else if (conversationDay.isAfter(thirtyDaysAgo)) {
        grouped['Previous 30 days']!.add(conversation);
      } else {
        grouped['Older']!.add(conversation);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  int getGroupedConversationCount(
    Map<String, List<ConversationHistory>> groupedConversations,
  ) {
    int count = 0;
    groupedConversations.forEach((section, conversations) {
      count += conversations.length + 1;
    });
    return count;
  }

  (String, int) getItemPosition(
    int index,
    Map<String, List<ConversationHistory>> groupedConversations,
  ) {
    int currentIndex = 0;
    final sections = groupedConversations.keys.toList();

    for (final section in sections) {
      final conversations = groupedConversations[section]!;

      if (index == currentIndex) {
        return (section, -1);
      }
      currentIndex++;

      for (int i = 0; i < conversations.length; i++) {
        if (index == currentIndex) {
          return (section, i);
        }
        currentIndex++;
      }
    }

    return ('', -1);
  }

  @override
  void dispose() {
    _disposed = true;
    _messageCache.clear();
    super.dispose();
  }
}

class ConversationHistory {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final int messageCount;
  final String? threadId;

  ConversationHistory({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.messageCount,
    this.threadId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'messageCount': messageCount,
      'threadId': threadId,
    };
  }

  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    return ConversationHistory(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      lastMessage: json['lastMessage'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      messageCount: json['messageCount'] ?? 0,
      threadId: json['threadId'],
    );
  }
}
