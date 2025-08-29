import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import 'package:medical_chat_bot/widgets/chat_message.dart';
import 'package:medical_chat_bot/widgets/message_input.dart';
import 'package:medical_chat_bot/widgets/typying_indicator.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IRIS Chat"),
        backgroundColor: Colors.blue,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
            },
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return Column(
            children: [
              
              if (chatProvider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatProvider.errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          chatProvider.clearError();
                        },
                      ),
                    ],
                  ),
                ),
              
              
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.0),
                  reverse: true,
                  itemBuilder: (_, int index) {
                    if (index == 0 && chatProvider.isTyping) {
                      return Column(
                        children: [
                          TypingIndicator(),
                          if (chatProvider.messages.isNotEmpty)
                            ChatMessageWidget(message: chatProvider.messages[0]),
                        ],
                      );
                    }
                    int messageIndex = chatProvider.isTyping ? index - 1 : index;
                    if (messageIndex < 0 || messageIndex >= chatProvider.messages.length) {
                      return SizedBox.shrink();
                    }
                    return ChatMessageWidget(message: chatProvider.messages[messageIndex]);
                  },
                  itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
                ),
              ),
              
              
              MessageInput(),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
