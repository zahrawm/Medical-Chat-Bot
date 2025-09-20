import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:medical_chat_bot/service/api_service.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../provider/chat_provider.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String? conversationID;

  const ChatDetailsScreen({super.key, this.conversationID});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  static const String baseUrl = 'https://liveapi.tybhealth.com';

  final _messageController = TextEditingController();
  ChatProvider? chatProvider;
  ApiService apiService = ApiService();
  String? _accessToken;

  List  messages = [];
  bool isLoading = true;
  String? conversationTitle;
  String? error;

  @override
  void initState() {
    super.initState();
    // Add null check here
    if (widget.conversationID != null) {
      fetchConversation(widget.conversationID);
    } else {
      // Handle the case where there's no conversation ID
      setState(() {
        isLoading = false;
        messages = [];
      });
    }
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<void> fetchConversation(String? conversationChatID) async {
    // Add null check at the beginning of the method
    if (conversationChatID == null) {
      setState(() {
        isLoading = false;
        messages = [];
        error = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = await prefs.getString('access_token');
      print("THE ACCESS TOKEN : ${_accessToken}");

      final fetchedMessages = await getConversationMessages(conversationChatID);
      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      // Format time as HH:MM
      String timeString =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      if (messageDate == today) {
        return 'Today $timeString';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday $timeString';
      } else {
        // Format date as MMM dd, HH:MM
        List<String> months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        String monthName = months[date.month - 1];
        return '$monthName ${date.day}, $timeString';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _startNewConversation() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewConversation();

    // Wait for the conversation ID to be generated and then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newConversationId = chatProvider.currentConversationId;
      if (newConversationId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatDetailsScreen(conversationID: newConversationId),
          ),
        );
      } else {
        // Handle the case where conversation ID is still null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to create new conversation. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/logo.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              'Loading conversation...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              widget.conversationID != null
                  ? 'No messages found'
                  : 'Start a new conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.conversationID != null
                  ? 'This conversation appears to be empty'
                  : 'Send a message to begin chatting',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // return ListView.builder(
    //   padding: const EdgeInsets.all(16),
    //   itemCount: messages.length,
    //   itemBuilder: (context, index) {

    //},
    // );
    // return _buildInputSection();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageTile(message, index);
            },
          ),
        ),
        _buildInputSection(),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: chatProvider.isLoading ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: chatProvider.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final chatMessage = _messageController.text.trim();
    if (chatMessage.isEmpty) return;

    _messageController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    messages.add(chatMessage);
    chatProvider.sendMessage(chatMessage);

    /// _scrollToBottom();
  }

  Widget _buildMessageTile(Map<String, dynamic> message, int index) {
    final input = message['input'] as String? ?? '';
    final output = message['output'] as String? ?? '';
    final date = message['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              if (date.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),

              if (date.isNotEmpty) const SizedBox(height: 16),

              if (input.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: MarkdownBody(
                              data: input,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.shade200,
                                  fontFamily: 'monospace',
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Bot response
              if (output.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Iris Chat Bot',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: MarkdownBody(
                              data: output,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                                h1: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                                h2: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade600,
                                ),
                                h3: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade500,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                em: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.shade200,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                blockquote: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                blockquoteDecoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.green.shade300,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                listBullet: TextStyle(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(
    String threadId,
  ) async {
    try {
      print('Fetching messages for thread: $threadId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/get-user-conversation?thread_id=$threadId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      print('Conversation messages response status: ${response.statusCode}');
      print('Conversation messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract conversation title if available
        if (data is Map && data.containsKey('title')) {
          setState(() {
            conversationTitle = data['title'];
          });
        }

        List<Map<String, dynamic>> messages = [];

        if (data is Map && data.containsKey('messages')) {
          messages = List<Map<String, dynamic>>.from(data['messages']);
        } else if (data is List) {
          messages = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data.containsKey('data')) {
            var dataValue = data['data'];
            if (dataValue is List) {
              messages = List<Map<String, dynamic>>.from(dataValue);
            }
          } else if (data.containsKey('history')) {
            messages = List<Map<String, dynamic>>.from(data['history']);
          } else if (data.containsKey('conversation')) {
            messages = List<Map<String, dynamic>>.from(data['conversation']);
          }
        }

        print('Parsed ${messages.length} messages from backend');
        return messages;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        print('No messages found for thread (404)');
        return [];
      } else {
        throw Exception(
          'Failed to get conversation messages: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Get conversation messages error: $e');
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      }
      throw Exception('Failed to load conversation messages: $e');
    }
  }
}
