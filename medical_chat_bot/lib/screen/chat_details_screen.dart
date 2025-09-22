import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import '../widgets/message_input.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String? conversationID;
  final String? tile;

  const ChatDetailsScreen({super.key, this.conversationID, this.tile});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> with TickerProviderStateMixin  {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _isLoading = false;

  late AnimationController _thinkingAnimationController;

  late Animation<double> _thinkingAnimation;

  @override
  void initState() {
    super.initState();
    _thinkingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    _thinkingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _thinkingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  void _initializeConversation() {
    if (widget.conversationID == null) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (chatProvider.currentConversationId == widget.conversationID &&
        chatProvider.messages.isNotEmpty) {
      setState(() {
        _isInitialized = true;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.microtask(() async {
      try {
        await chatProvider.loadConversationFromBackend(widget.conversationID!);
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _scrollToBottom();
      } catch (error) {
        print('Error loading conversation: $error');
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    });
  }
  @override
  void dispose() {
    _thinkingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              ConversationHistory? conversation;

              if (widget.conversationID != null) {
                conversation = chatProvider.getConversationById(widget.conversationID!);

                if (conversation == null) {
                  conversation = chatProvider.conversationHistory.firstWhere(
                        (conv) => conv.threadId == widget.conversationID,
                    orElse: () => ConversationHistory(
                      id: '',
                      title: '',
                      lastMessage: '',
                      timestamp: DateTime.now(),
                      messageCount: 0,
                    ),
                  );
                }
              }

              String title = widget.tile ??  '';

              return Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;
        final isLoading = chatProvider.isLoading;

        if (messages.isEmpty && !isLoading) {
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

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && (isLoading )) {
                    return _buildThinkingIndicator();
                  }

                  final message = messages[index];
                  return MessageBubble(
                    message: message,
                    shouldAnimate:
                    !message.isUser && index == chatProvider.messages.length - 1,
                  );
                },
              ),
            ),
            _buildInputSection(),
          ],
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Iris is thinking',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _thinkingAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.5;
                          final animationValue =
                          (_thinkingAnimation.value - delay).clamp(
                            0.0,
                            1.0,
                          );
                          final opacity = (animationValue * 2).clamp(0.0, 1.0);

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedOpacity(
                              opacity: opacity > 1.0 ? 2.0 - opacity : opacity,
                              duration: Duration.zero,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
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
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}