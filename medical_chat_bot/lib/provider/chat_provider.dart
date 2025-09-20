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

  // FIXED: Load conversation with proper state management - PREVENTS BLANK SCREEN
  Future<void> loadConversation(String conversationId) async {
    if (_disposed) return;

    // Validate inputs
    if (conversationId.isEmpty) {
      _setError('Invalid conversation ID');
      return;
    }

    // Prevent loading the same conversation twice
    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      print(
        'Conversation $conversationId already loaded with ${_messages.length} messages',
      );
      return;
    }

    try {
      _setLoadingConversation(true);
      _setError(null);

      print('Loading conversation: $conversationId');

      // Save current conversation before switching if it exists and has messages
      if (_currentConversationId != null &&
          _currentConversationId != conversationId &&
          _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      // Find the conversation to get thread_id
      final conversation = getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found in history');
      }

      // Validate conversation has required data
      if (conversation.id.isEmpty) {
        throw Exception('Invalid conversation: missing ID');
      }

      // CRITICAL FIX: Don't clear messages immediately - keep current messages visible
      // until we successfully load new ones

      // Set the conversation ID and threadId
      final previousConversationId = _currentConversationId;
      final previousMessages = List<Message>.from(_messages);

      _currentConversationId = conversationId;
      if (conversation.threadId != null) {
        _currentThreadId = conversation.threadId;
      }

      // Try to load messages from various sources
      List<Message> loadedMessages = [];
      bool loadSuccess = false;

      // 1. Try loading from backend if user is logged in and threadId exists
      if (_apiService.accessToken != null && _currentThreadId != null) {
        try {
          print(
            'Attempting to load from backend with threadId: $_currentThreadId',
          );
          loadedMessages = await _loadConversationFromBackend(
            _currentThreadId!,
            conversationId,
          );
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
            print(
              'Successfully loaded ${loadedMessages.length} messages from backend',
            );
          }
        } catch (e) {
          print('Backend loading failed: $e');
        }
      }

      // 2. If backend failed, try loading from local storage
      if (!loadSuccess) {
        print('Loading from local storage');
        try {
          loadedMessages = await _loadConversationFromLocal(conversationId);
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
            print(
              'Successfully loaded ${loadedMessages.length} messages from local storage',
            );
          }
        } catch (e) {
          print('Local storage loading failed: $e');
        }
      }

      // 3. Try cache as last resort
      if (!loadSuccess && _messageCache.containsKey(conversationId)) {
        loadedMessages = List.from(_messageCache[conversationId]!);
        if (loadedMessages.isNotEmpty) {
          loadSuccess = true;
          print(
            'Successfully loaded ${loadedMessages.length} messages from cache',
          );
        }
      }

      // CRITICAL FIX: Only update messages if we successfully loaded something
      // OR if this is a legitimately empty conversation
      if (loadSuccess || loadedMessages.isEmpty) {
        _messages = loadedMessages;
        if (loadedMessages.isNotEmpty) {
          _messageCache[conversationId] = List.from(loadedMessages);
        }
      } else {
        // If we failed to load, revert to previous state to prevent blank screen
        print('Failed to load conversation, reverting to previous state');
        _currentConversationId = previousConversationId;
        _messages = previousMessages;
        throw Exception('Failed to load conversation messages');
      }

      _setLoadingConversation(false);
      notifyListeners();

      if (loadSuccess && loadedMessages.isNotEmpty) {
        print(
          'Successfully loaded conversation $conversationId with ${_messages.length} messages',
        );
      } else if (loadedMessages.isEmpty) {
        print('Conversation $conversationId is empty - showing empty state');
      }
    } catch (e) {
      print('Error loading conversation: $e');
      _setError('Failed to load conversation: ${e.toString()}');
      _setLoadingConversation(false);

      // Don't clear messages on error - keep current state to prevent blank screen
      notifyListeners();
    }
  }

  // ENHANCED: Load conversation messages from backend with better error handling
  Future<List<Message>> _loadConversationFromBackend(
    String threadId,
    String conversationId,
  ) async {
    try {
      print('Loading conversation from backend for thread: $threadId');

      if (threadId.isEmpty) {
        print('Empty threadId provided');
        return [];
      }

      final backendMessages = await _apiService.getConversationMessages(
        threadId,
      );
      print('Backend returned ${backendMessages.length} message items');
      print(
        'Sample backend data: ${backendMessages.take(2).toList()}',
      ); // DEBUG

      if (backendMessages.isNotEmpty) {
        List<Message> convertedMessages = [];

        // Check if backend returns conversation pairs or individual messages
        for (var item in backendMessages) {
          // Method 1: Handle if backend returns conversation pairs with both query and answer
          if (item.containsKey('query') && item.containsKey('answer')) {
            print('Found conversation pair in item: ${item.keys.toList()}');

            // Extract user message (query)
            String userQuery = item['query']?.toString().trim() ?? '';
            if (userQuery.isNotEmpty) {
              DateTime userTimestamp = _parseTimestamp(
                item['query_timestamp'] ??
                    item['timestamp'] ??
                    item['created_at'],
              );

              convertedMessages.add(
                Message(
                  content: userQuery,
                  isUser: true,
                  timestamp: userTimestamp,
                ),
              );
              print(
                'Added user message: ${userQuery.substring(0, userQuery.length > 30 ? 30 : userQuery.length)}...',
              );
            }

            // Extract bot response (answer)
            String botAnswer = item['answer']?.toString().trim() ?? '';
            if (botAnswer.isNotEmpty) {
              DateTime botTimestamp = _parseTimestamp(
                item['answer_timestamp'] ??
                    item['timestamp'] ??
                    item['created_at'],
              );
              // Add a small delay to bot timestamp to ensure proper ordering
              botTimestamp = botTimestamp.add(Duration(seconds: 1));

              convertedMessages.add(
                Message(
                  content: botAnswer,
                  isUser: false,
                  timestamp: botTimestamp,
                ),
              );
              print(
                'Added bot message: ${botAnswer.substring(0, botAnswer.length > 30 ? 30 : botAnswer.length)}...',
              );
            }
          }
          // Method 2: Handle individual messages
          else {
            final message = _convertBackendToMessage(item);
            if (message != null) {
              convertedMessages.add(message);
              print(
                'Added individual message: ${message.isUser ? 'User' : 'Bot'} - ${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...',
              );
            }
          }
        }

        if (convertedMessages.isNotEmpty) {
          // Sort messages by timestamp to ensure proper order
          convertedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Save to local storage for offline access
          try {
            await _saveMessagesToLocal(conversationId, convertedMessages);
          } catch (e) {
            print('Failed to save to local after backend load: $e');
          }

          print(
            'Successfully converted ${convertedMessages.length} messages from backend',
          );
          return convertedMessages;
        } else {
          print('No valid messages could be converted from backend response');
        }
      } else {
        print('No messages found in backend response');
      }

      return [];
    } catch (e) {
      print('Error loading conversation from backend: $e');
      throw e; // Re-throw to let caller handle
    }
  }

  // ENHANCED: Load conversation from local storage with better validation
  Future<List<Message>> _loadConversationFromLocal(
    String conversationId,
  ) async {
    try {
      if (conversationId.isEmpty) {
        print('Empty conversationId provided for local loading');
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
            print('Error parsing message: $e');
            // Skip corrupted messages but continue processing others
          }
        }

        if (loadedMessages.isNotEmpty) {
          print(
            'Successfully loaded ${loadedMessages.length} messages from local storage',
          );
          return loadedMessages;
        }
      }

      print(
        'No messages found in local storage for conversation: $conversationId',
      );
      return [];
    } catch (e) {
      print('Error loading conversation from local storage: $e');
      return [];
    }
  }

  // ENHANCED: Convert backend message data to Message object with better field detection
  Message? _convertBackendToMessage(Map<String, dynamic> item) {
    try {
      print('Converting backend message item: ${item.keys.toList()}'); // DEBUG
      print(
        'Full item data: $item',
      ); // DEBUG - Add this line for better debugging

      // Try multiple possible field names for message content
      String content = '';

      // Check for content in various possible fields
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

      // If still no content found, skip this message
      if (content.isEmpty) {
        print('Skipping message with empty content: $item');
        return null;
      }

      // Determine if message is from user with better logic
      bool isUser = false;

      // Method 1: Check explicit user indicators
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
        // Method 2: Infer from field names if no explicit indicator
        if (item.containsKey('query') && !item.containsKey('answer')) {
          isUser = true; // Likely a user query
        } else if (item.containsKey('answer') && !item.containsKey('query')) {
          isUser = false; // Likely a bot answer
        } else if (item.containsKey('query') && item.containsKey('answer')) {
          // Both exist - need to determine which field we used for content
          if (content == item['query']?.toString().trim()) {
            isUser = true;
          } else if (content == item['answer']?.toString().trim()) {
            isUser = false;
          } else {
            // Default to alternating pattern or use other logic
            isUser = false; // Default to bot if uncertain
          }
        }
      }

      // Extract timestamp with multiple fallbacks
      DateTime timestamp = _parseTimestamp(
        item['timestamp'] ??
            item['created_at'] ??
            item['sent_at'] ??
            item['date'] ??
            item['time'] ??
            item['created'] ??
            DateTime.now().millisecondsSinceEpoch,
      );

      print(
        'Converted message: isUser=$isUser, content="${content.length > 50 ? content.substring(0, 50) + '...' : content}"',
      ); // DEBUG

      return Message(content: content, isUser: isUser, timestamp: timestamp);
    } catch (e) {
      print('Error converting backend message: $e');
      print('Message item causing error: $item');
      return null;
    }
  }

  // Load conversation history from backend only
  Future<void> _loadConversationHistory() async {
    try {
      _setLoadingHistory(true);

      // Only sync with backend if user is logged in - no local loading
      if (_apiService.accessToken != null) {
        await _syncConversationHistoryFromBackend();
      } else {
        // Clear history if no user is logged in
        _conversationHistory.clear();
        notifyListeners();
      }

      _setLoadingHistory(false);
    } catch (e) {
      print('Error loading conversation history: $e');
      _setLoadingHistory(false);
      _setError('Failed to load conversation history');
    }
  }

  // Sync conversation history from backend with improved debugging and validation
  Future<void> _syncConversationHistoryFromBackend() async {
    if (_apiService.accessToken == null) return;

    try {
      _setSyncingWithBackend(true);

      List<Map<String, dynamic>> backendHistory = [];

      try {
        backendHistory = await _apiService.getConversationHistory();

        // DEBUG: Print the raw response to see the actual structure
        print('=== DEBUG: Raw backend response ===');
        print('Number of items received: ${backendHistory.length}');
        for (int i = 0; i < backendHistory.length && i < 3; i++) {
          // Show first 3 items
          print('Item $i: ${backendHistory[i]}');
          print('Item $i keys: ${backendHistory[i].keys.toList()}');
        }
        print('=== END DEBUG ===');
      } catch (e) {
        print('Failed to fetch conversation history from backend: $e');
        _setSyncingWithBackend(false);
        if (e.toString().contains('Authentication failed')) {
          _setError('Authentication failed. Please log in again.');
        } else {
          _setError('Failed to load conversation history from server');
        }
        return;
      }

      // Convert backend data to ConversationHistory objects
      List<ConversationHistory> backendConversations = [];

      for (var item in backendHistory) {
        try {
          print('Converting item: $item'); // DEBUG
          final conversation = _convertBackendToConversationHistory(item);
          if (conversation != null) {
            // VALIDATE the conversation has required fields
            if (conversation.id.isNotEmpty && conversation.title.isNotEmpty) {
              backendConversations.add(conversation);
              print('Successfully converted: ${conversation.title}'); // DEBUG
            } else {
              print(
                'Skipping conversation with missing required fields: ${conversation.id}',
              );
            }
          } else {
            print('Failed to convert item: $item'); // DEBUG
          }
        } catch (e) {
          print('Error converting backend item: $e');
          print('Item data: $item');
        }
      }

      // Replace local history with backend data (backend is the only source)
      _conversationHistory = backendConversations;
      _conversationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print(
        'Final conversation count: ${_conversationHistory.length}',
      ); // DEBUG

      _setSyncingWithBackend(false);
      notifyListeners();
    } catch (e) {
      print('Error syncing conversation history from backend: $e');
      _setSyncingWithBackend(false);
      _setError('Failed to load conversation history from server');
    }
  }

  // Conversion method that handles your specific backend structure with better validation
  ConversationHistory? _convertBackendToConversationHistory(
    Map<String, dynamic> item,
  ) {
    try {
      print(
        'Converting backend conversation with keys: ${item.keys.toList()}',
      ); // DEBUG

      // Extract ID - try multiple possible field names
      String? id =
          item['id']?.toString() ??
          item['conversation_id']?.toString() ??
          item['chat_id']?.toString();

      if (id == null || id.isEmpty) {
        print('No ID found in conversation item: $item');
        return null;
      }

      // Extract title - try multiple possible field names
      String title =
          item['title']?.toString() ??
          item['name']?.toString() ??
          item['subject']?.toString() ??
          item['conversation_title']?.toString() ??
          'Untitled Conversation';

      // Validate and clean title
      title = title.trim();
      if (title.isEmpty) {
        title = 'Conversation ${id.substring(0, 8)}';
      }

      // For last message, try to extract from various fields
      String lastMessage =
          item['last_message']?.toString() ??
          item['lastMessage']?.toString() ??
          item['preview']?.toString() ??
          title;

      // Truncate if too long
      if (lastMessage.length > 50) {
        lastMessage = lastMessage.substring(0, 50) + '...';
      }

      // Extract timestamp
      DateTime timestamp = _parseTimestamp(
        item['updated_at'] ??
            item['created_at'] ??
            item['last_activity'] ??
            item['timestamp'],
      );

      // Calculate message count
      int messageCount = _parseMessageCount(
        item['message_count'] ??
            item['messageCount'] ??
            item['total_messages'] ??
            item['count'],
      );

      // If no message count provided, estimate from tokens
      if (messageCount == 0) {
        messageCount = _estimateMessageCountFromTokens(
          item['total_tokens'],
          item['total_prompt_tokens'],
          item['total_completion_tokens'],
        );
      }

      // Extract thread ID
      String? threadId =
          item['thread_id']?.toString() ??
          item['threadId']?.toString() ??
          item['session_id']?.toString();

      final result = ConversationHistory(
        id: id,
        title: title,
        lastMessage: lastMessage,
        timestamp: timestamp,
        messageCount: messageCount,
        threadId: threadId,
      );

      print('Successfully created ConversationHistory:');
      print('  ID: ${result.id}');
      print('  Title: ${result.title}');
      print('  ThreadID: ${result.threadId}');
      print('  MessageCount: ${result.messageCount}');

      return result;
    } catch (e) {
      print('Error converting backend conversation: $e');
      print('Item causing error: $item');
      return null;
    }
  }

  // Helper method to estimate message count from token usage
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

      // Rough estimation: assume average message is ~100-200 tokens
      // Prompt tokens are usually user messages, completion tokens are bot responses
      // So total messages = (prompt messages + completion messages)
      int estimatedUserMessages = (prompt / 150).ceil();
      int estimatedBotMessages = (completion / 200).ceil();

      // Most conversations have roughly equal user and bot messages
      int estimatedTotal = estimatedUserMessages + estimatedBotMessages;

      // Ensure minimum of 1 if there are any tokens
      return estimatedTotal > 0 ? estimatedTotal : (total > 0 ? 2 : 0);
    } catch (e) {
      print('Error estimating message count: $e');
      return 0;
    }
  }

  // Helper to parse message count safely
  int _parseMessageCount(dynamic count) {
    if (count == null) return 0;

    if (count is int) return count;
    if (count is String) {
      return int.tryParse(count) ?? 0;
    }

    return 0;
  }

  // More robust timestamp parsing
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      print('Timestamp is null, using current time');
      return DateTime.now();
    }

    try {
      if (timestamp is int) {
        // Handle both milliseconds and seconds timestamps
        if (timestamp > 1000000000000) {
          // Milliseconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          // Seconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      } else if (timestamp is String) {
        // Try to parse ISO string or other common formats
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // Try parsing as timestamp string
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
      print('Error parsing timestamp: $e, value: $timestamp');
    }

    print('Using current time as fallback for timestamp: $timestamp');
    return DateTime.now();
  }

  // Helper method to save messages to local storage
  Future<void> _saveMessagesToLocal(
    String conversationId,
    List<Message> messages,
  ) async {
    try {
      if (conversationId.isEmpty) {
        print('Cannot save: empty conversationId');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();

      await prefs.setStringList('messages_$conversationId', messagesJson);
      print('Saved ${messages.length} messages to local storage');
    } catch (e) {
      print('Error saving messages to local storage: $e');
    }
  }

  // Clear current conversation state properly
  Future<void> clearCurrentConversation() async {
    if (_disposed) return;

    try {
      // Save current conversation before clearing if it exists
      if (_currentConversationId != null && _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      // Clear all state in the right order
      _messages.clear();
      _currentThreadId = null;
      _currentConversationId = null;
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;

      // Always notify listeners when state changes
      notifyListeners();
    } catch (e) {
      print('Error clearing conversation: $e');
      // Force clear even if save fails
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

  // Save current conversation messages
  Future<void> _saveCurrentConversation() async {
    if (_currentConversationId == null || _messages.isEmpty) return;

    try {
      await _saveMessagesToLocal(_currentConversationId!, _messages);

      // Also update cache
      _messageCache[_currentConversationId!] = List.from(_messages);
    } catch (e) {
      print('Error saving current conversation: $e');
    }
  }

  // FIXED: Single sendMessage method that handles both new and existing conversations
  Future<void> sendMessage(String message) async {
    if (_disposed) return;

    try {
      _setLoading(true);
      _setError(null);

      // Add user message immediately
      final userMessage = Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _messages.add(userMessage);
      notifyListeners();

      Map<String, dynamic> response;

      if (_currentThreadId == null) {
        // Start new conversation
        print(
          'Starting new conversation with first message: ${message.substring(0, message.length > 20 ? 20 : message.length)}...',
        );

        response = await _apiService.startConversation(message);
        _currentThreadId = response['thread_id'];

        // FIXED: Generate conversation ID only AFTER successful API call
        final newConversationId = DateTime.now().millisecondsSinceEpoch
            .toString();
        _currentConversationId = newConversationId;

        // Create new conversation history entry AFTER successful response
        await _createNewConversation(message);

        print(
          'Successfully created new conversation with ID: $newConversationId and thread_id: $_currentThreadId',
        );
      } else {
        // Continue existing conversation
        response = await _apiService.continueConversation(
          _currentThreadId!,
          message,
        );

        // Update existing conversation
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

      // Save messages after adding bot response
      await _saveCurrentConversation();

      // Stop typing animation
      final typingDuration = Duration(
        milliseconds: botResponse.length * 30 + 500,
      );
      Future.delayed(typingDuration, () {
        if (!_disposed) {
          _setTyping(false);
        }
      });

      print('Message sent successfully. Total messages: ${_messages.length}');
    } catch (e) {
      print('Error sending message: $e');
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
    // FIXED: Generate a proper conversation ID when creating new conversation
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

  // Better clearChat method
  Future<void> clearChat() async {
    if (_disposed) return;
    await clearCurrentConversation();
  }

  // FIXED: Start a new conversation without creating placeholder entries
  Future<void> startNewConversation() async {
    if (_disposed) return;

    try {
      print('Starting new conversation...');

      // Save current conversation if it exists and has messages
      if (_currentConversationId != null && _messages.isNotEmpty) {
        await _saveCurrentConversation();
        print('Saved current conversation before starting new one');
      }

      // FIXED: Clear all state without creating placeholder conversation
      _messages.clear();
      _currentThreadId = null;
      _currentConversationId =
          null; // Don't set a new ID yet - wait for first message
      _error = null;
      _isLoading = false;
      _isTyping = false;
      _isLoadingConversation = false;

      // Don't add any placeholder conversation to history
      // The conversation will be created when the user sends the first message

      // Always notify listeners when starting new conversation
      notifyListeners();

      print('Successfully started new conversation - ready for first message');
    } catch (e) {
      print('Error starting new conversation: $e');
      // Force clear state even if save fails
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

  // FIXED: Load conversation silently without triggering typing animation
  Future<void> loadConversationSilently(String conversationId) async {
    if (_disposed) return;

    // Validate inputs
    if (conversationId.isEmpty) {
      _setError('Invalid conversation ID');
      return;
    }

    // Prevent loading the same conversation twice
    if (_currentConversationId == conversationId && _messages.isNotEmpty) {
      print(
        'Conversation $conversationId already loaded with ${_messages.length} messages',
      );
      return;
    }

    try {
      _setLoadingConversation(true);
      _setError(null);

      // CRITICAL: DO NOT set _setLoading(true) or _setTyping(true) here
      // This prevents the typing animation from starting

      print('Loading conversation silently: $conversationId');

      // Save current conversation before switching if it exists and has messages
      if (_currentConversationId != null &&
          _currentConversationId != conversationId &&
          _messages.isNotEmpty) {
        await _saveCurrentConversation();
      }

      // Find the conversation to get thread_id
      final conversation = getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found in history');
      }

      // Validate conversation has required data
      if (conversation.id.isEmpty) {
        throw Exception('Invalid conversation: missing ID');
      }

      // Set the conversation ID and threadId
      final previousConversationId = _currentConversationId;
      final previousMessages = List<Message>.from(_messages);

      _currentConversationId = conversationId;
      if (conversation.threadId != null) {
        _currentThreadId = conversation.threadId;
      }

      // Try to load messages from various sources
      List<Message> loadedMessages = [];
      bool loadSuccess = false;

      // 1. Try loading from backend if user is logged in and threadId exists
      if (_apiService.accessToken != null && _currentThreadId != null) {
        try {
          print(
            'Attempting to load from backend with threadId: $_currentThreadId',
          );
          loadedMessages = await _loadConversationFromBackend(
            _currentThreadId!,
            conversationId,
          );
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
            print(
              'Successfully loaded ${loadedMessages.length} messages from backend',
            );
          }
        } catch (e) {
          print('Backend loading failed: $e');
        }
      }

      // 2. If backend failed, try loading from local storage
      if (!loadSuccess) {
        print('Loading from local storage');
        try {
          loadedMessages = await _loadConversationFromLocal(conversationId);
          if (loadedMessages.isNotEmpty) {
            loadSuccess = true;
            print(
              'Successfully loaded ${loadedMessages.length} messages from local storage',
            );
          }
        } catch (e) {
          print('Local storage loading failed: $e');
        }
      }

      // 3. Try cache as last resort
      if (!loadSuccess && _messageCache.containsKey(conversationId)) {
        loadedMessages = List.from(_messageCache[conversationId]!);
        if (loadedMessages.isNotEmpty) {
          loadSuccess = true;
          print(
            'Successfully loaded ${loadedMessages.length} messages from cache',
          );
        }
      }

      // Only update messages if we successfully loaded something
      // OR if this is a legitimately empty conversation
      if (loadSuccess || loadedMessages.isEmpty) {
        _messages = loadedMessages;
        if (loadedMessages.isNotEmpty) {
          _messageCache[conversationId] = List.from(loadedMessages);
        }
      } else {
        // If we failed to load, revert to previous state to prevent blank screen
        print('Failed to load conversation, reverting to previous state');
        _currentConversationId = previousConversationId;
        _messages = previousMessages;
        throw Exception('Failed to load conversation messages');
      }

      // IMPORTANT: Ensure typing states are false after silent loading
      _isLoading = false;
      _isTyping = false;
      _setLoadingConversation(false);

      notifyListeners();

      if (loadSuccess && loadedMessages.isNotEmpty) {
        print(
          'Successfully loaded conversation $conversationId with ${_messages.length} messages silently',
        );
      } else if (loadedMessages.isEmpty) {
        print('Conversation $conversationId is empty - showing empty state');
      }
    } catch (e) {
      print('Error loading conversation silently: $e');
      _setError('Failed to load conversation: ${e.toString()}');
      _setLoadingConversation(false);

      // Ensure no typing animation on error
      _isLoading = false;
      _isTyping = false;

      // Don't clear messages on error - keep current state to prevent blank screen
      notifyListeners();
    }
  }

  // Delete a conversation from history
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Remove from history list
      _conversationHistory.removeWhere((conv) => conv.id == conversationId);

      // Delete saved messages
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$conversationId');

      // Remove from cache
      _messageCache.remove(conversationId);

      // If this was the current conversation, clear it properly
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
      print('Error deleting conversation: $e');
      _setError('Failed to delete conversation');
    }
  }

  // Refresh conversation history from backend only
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

  // Better validation for conversation existence
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

  // Get conversation by ID with better validation
  ConversationHistory? getConversationById(String conversationId) {
    try {
      if (conversationId.isEmpty) return null;

      return _conversationHistory.firstWhere(
        (conv) => conv.id == conversationId,
      );
    } catch (e) {
      print('Conversation not found: $conversationId');
      return null;
    }
  }

  // Get conversation preview (first few words of title + message count)
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

  // Reset provider to initial state (useful for logout)
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

    // Clear local storage as well
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
      print('Error clearing local storage: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _messageCache.clear();
    super.dispose();
  }
}

// Enhanced ConversationHistory model with JSON serialization
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

  // Convert to JSON for storage
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

  // Create from JSON
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
