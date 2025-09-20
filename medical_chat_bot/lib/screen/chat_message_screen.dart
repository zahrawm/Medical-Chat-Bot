import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import 'package:medical_chat_bot/screen/chat_details_screen.dart';
import 'package:medical_chat_bot/screen/profile_screen.dart';
import 'package:medical_chat_bot/widgets/message_input.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _thinkingAnimationController;
  late Animation<double> _thinkingAnimation;
  bool _showQuickQuestions = true;

  final List<String> _quickQuestions = [
    "What causes obesity and type 2 diabetes?",
    "how many carbs should I eat daily to support brain function",
    "Does eating saturated fat from meat, butter or egg increase risk of CVD",
    "Should I eat 3x per day to maintain consistent blood sugar",
  ];

  final List<Feature> _features = [
    Feature(
      emoji: "🎯",
      title: "Personalized Coaching",
      text:
          "Get tailored advice based on your unique metabolic profile and goals.",
    ),
    Feature(
      emoji: "🍎",
      title: "Nutrition Analysis",
      text:
          "Analyze your meals and get instant feedback on nutritional content.",
    ),
    Feature(
      emoji: "📊",
      title: "Progress Tracking",
      text: "Monitor your health journey with detailed insights and analytics.",
    ),
  ];
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
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      chatProvider
          .refreshConversationHistory()
          .then((_) {
            print(
              'Conversation history loaded: ${chatProvider.conversationHistory.length} conversations',
            );
          })
          .catchError((error) {
            print('Error refreshing conversation history: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unable to load conversation history'),
                  backgroundColor: Colors.orange.shade600,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
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
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      drawer: _buildHistoryDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              key: ValueKey('chat_consumer'),
              builder: (context, chatProvider, child) {
                return Stack(
                  children: [
                    _buildBackgroundPattern(),
                    if (chatProvider.messages.isEmpty)
                      _buildWelcomeScreen()
                    else
                      _buildChatList(chatProvider),
                  ],
                );
              },
            ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0000000),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/logo.png', height: 20, width: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'IRIS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Metabolic Health Coach',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Color(000000)),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/logo.png', height: 40, width: 40)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Iris Metabolic Health Coach',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // In your ChatScreen's _buildHistoryDrawer method, replace the "New Chat" button section with this:

          // New Chat Button Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close drawer first

                  final chatProvider = Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  );

                  // FIXED: Clear current conversation properly without navigation
                  chatProvider.startNewConversation();

                  // No navigation needed - we're already in ChatScreen
                  // The UI will automatically update through the Consumer<ChatProvider>
                },
                icon: Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'New Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4BB543),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  elevation: 2,
                ),
              ),
            ),
          ),

          // Recent Chats Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Chats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Chat History List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoadingHistory) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: const Color.fromARGB(255, 160, 174, 161),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading conversations...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (chatProvider.conversationHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start chatting to see your history here',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final groupedConversations = chatProvider.groupConversationsByTime();

                return RefreshIndicator(
                  onRefresh: () async {
                    await chatProvider.refreshConversationHistory();
                  },
                  color: Colors.green.shade600,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: chatProvider.getGroupedConversationCount(groupedConversations),
                    itemBuilder: (context, index) {
                      final (section, itemIndex) = chatProvider.getItemPosition(index, groupedConversations);

                      if (itemIndex == -1) {
                        return _buildSectionHeader(section);
                      }

                      final conversation = groupedConversations[section]![itemIndex];
                      final isCurrentConversation = conversation.id == chatProvider.currentConversationId;

                      return Container(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 6),
                          minVerticalPadding: 0,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            conversation.title,
                            style: TextStyle(
                              fontWeight: isCurrentConversation
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: isCurrentConversation
                                  ? Colors.black87
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: chatProvider.isLoadingConversation
                              ? null
                              : () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailsScreen(
                                  conversationID: conversation.threadId,
                                ),
                              ),
                            );
                          },
                          trailing: chatProvider.isLoadingConversation &&
                              isCurrentConversation
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green.shade600,
                            ),
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4BB543), Color(0xFF388E3C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  _getProfileInitials(authProvider),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen()),
                              );
                            },
                            tooltip: 'Profile',
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  authProvider.user?.firstName ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              Text(
                                  'User'
                              )
                              ]
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings_outlined, size: 22),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                        );                        },
                      tooltip: 'Profile',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: Icon(Icons.logout, size: 22),
                        onPressed: () {
                          _showLogoutConfirmation();
                        },
                        tooltip: 'Logout',
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: CustomPaint(size: Size.infinite, painter: ChatBackgroundPainter()),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'How can I help you today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            textAlign: TextAlign.center,
            'Your AI metabolic health coach is ready to provide personalized guidance for your wellness journey.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),

          SizedBox(height: 10),
          _buildFeatures(),

          SizedBox(height: 10),
           _buildQuickQuestions(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showQuickQuestions = !_showQuickQuestions;
                });
              },
              child: Text(_showQuickQuestions ? 'Hide' : 'Show'),
            ),
          ],
        ),
        if (_showQuickQuestions)...[
          SizedBox(height: 8),
          Column(
            children: _quickQuestions.map((question) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _sendQuickQuestion(question),
                  child: Card(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(000000)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Color((0xFF4BB543)),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      children: _features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF000000).withAlpha(26)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(27),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.emoji, style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          feature.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      itemCount:
          chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length && chatProvider.isLoading) {
          return _buildThinkingIndicator();
        }

        final message = chatProvider.messages[index];
        return MessageBubble(
          message: message,
          shouldAnimate:
              !message.isUser && index == chatProvider.messages.length - 1,
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
            color: Colors.black.withAlpha(27),
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

  void _sendQuickQuestion(String question) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(question);
    _scrollToBottom();
  }

  void _startNewConversation() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startNewConversation();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailsScreen(
          conversationID: chatProvider.currentConversationId,
        ),
      ),
    );
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

    Future.delayed(Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showDeleteConversationDialog(ConversationHistory conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red.shade600),
            SizedBox(width: 8),
            Text('Delete Conversation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this conversation?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${conversation.messageCount} messages',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              await chatProvider.deleteConversation(conversation.id);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation deleted'),
                  backgroundColor: Colors.red.shade600,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange.shade600),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: Text(
          'Are you sure you want to log out? Your conversations are saved and will be available when you return.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.clear_all, color: Colors.orange.shade600),
            SizedBox(width: 8),
            Text('Start New Chat'),
          ],
        ),
        content: Text(
          'Start a new conversation? Your current conversation will be saved in history.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewConversation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Start New Chat',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this helper method to your _ChatScreenState class
String _getProfileInitials(AuthProvider authProvider) {
  if (authProvider.user != null) {
    final firstName = authProvider.user!.firstName ?? '';
    final lastName = authProvider.user!.lastName ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      final username = authProvider.user!.username ?? '';
      return username.isNotEmpty ? username[0].toUpperCase() : 'U';
    }

    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }
  return 'U';
}

class ChatBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withAlpha(5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Feature {
  final String emoji;
  final String title;
  final String text;

  Feature({required this.emoji, required this.title, required this.text});
}

Widget _buildSectionHeader(String section) {
  return Text(
    section,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      decoration: TextDecoration.underline,
      color: Colors.grey.shade700,
    ),
  );
}