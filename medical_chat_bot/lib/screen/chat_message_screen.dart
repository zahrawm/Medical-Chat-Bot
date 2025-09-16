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

  // Replace your initState method in ChatScreen with this fixed version:

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

    // Load conversation history from backend after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Always refresh history from backend when screen loads
      chatProvider
          .refreshConversationHistory()
          .then((_) {
            // Only auto-load the most recent conversation if:
            // 1. There's conversation history
            // 2. No current conversation is loaded
            // 3. Current messages are empty
            // 4. User is logged in
            if (chatProvider.conversationHistory.isNotEmpty &&
                chatProvider.messages.isEmpty &&
                chatProvider.currentConversationId == null &&
                chatProvider.accessToken != null) {
              final mostRecentConversation =
                  chatProvider.conversationHistory.first;
              print(
                'Auto-loading most recent conversation: ${mostRecentConversation.id}',
              );

              chatProvider
                  .loadConversation(mostRecentConversation.id)
                  .then((_) {
                    // Scroll to bottom after loading messages
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  })
                  .catchError((error) {
                    print('Error loading most recent conversation: $error');
                    // Don't show error to user here, just continue with empty state
                    // The conversation will still be available in the history drawer
                  });
            }
          })
          .catchError((error) {
            print('Error refreshing conversation history: $error');
            // Show error if completely unable to load history
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
            width: 20,
            height: 20,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
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
                  'Your Medical Assistant',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Profile Button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Container(
                  width: 30,
                  height: 30,
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
            );
          },
        ),

        Padding(
          padding: EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Icon(Icons.history, size: 22),
            onPressed: () {
              // Refresh conversation history from backend before opening drawer
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );
              chatProvider.refreshConversationHistory();
              _scaffoldKey.currentState?.openDrawer();
            },
            tooltip: 'History',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),

        // Menu Button
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 22),
          padding: EdgeInsets.all(4),
          onSelected: (value) {
            if (value == 'clear') {
              _showClearConfirmation();
            } else if (value == 'logout') {
              _showLogoutConfirmation();
            } else if (value == 'new') {
              _startNewConversation();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.green.shade600, size: 20),
                  SizedBox(width: 8),
                  Text('New Chat', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),

            PopupMenuItem(
              value: 'logout',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.grey.shade600, size: 20),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(000000),
            ), // Professional grey
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16), //

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Center align for better side-by-side look
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Text(
                      'Iris Metabolic Health Coach',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black, // White text on grey background
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Chats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // E
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

                return RefreshIndicator(
                  onRefresh: () async {
                    await chatProvider.refreshConversationHistory();
                  },
                  color: Colors.green.shade600,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: chatProvider.conversationHistory.length,
                    itemBuilder: (context, index) {
                      final conversation =
                          chatProvider.conversationHistory[index];
                      final isCurrentConversation =
                          conversation.id == chatProvider.currentConversationId;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    chatProvider.getConversationPreview(
                                      conversation,
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (chatProvider.isSyncingWithBackend) ...[
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        color: Colors.green.shade400,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          // Replace your ListTile onTap handler in the history drawer with this safer version:
                          // Replace your ListTile onTap handler in the history drawer with this:
                          onTap: chatProvider.isLoadingConversation
                              ? null
                              : () async {
                                  // await chatProvider!.loadConversation(
                                  //   conversation.id.toString(),
                                  // );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailsScreen(
                                        conversationID: conversation.threadId,
                                      ),
                                    ),
                                  );
                                },

                          // : () async {
                          //     // Close drawer first
                          //     Navigator.of(context).pop();
                          //
                          //     try {
                          //       // Validate conversation data
                          //       if (conversation.id.isEmpty) {
                          //         if (mounted) {
                          //           ScaffoldMessenger.of(
                          //             context,
                          //           ).showSnackBar(
                          //             SnackBar(
                          //               content: Text(
                          //                 'Invalid conversation: missing ID',
                          //               ),
                          //               backgroundColor:
                          //                   Colors.red.shade600,
                          //               duration: Duration(seconds: 2),
                          //             ),
                          //           );
                          //         }
                          //         return;
                          //       }
                          //
                          //       // Don't reload if it's already the current conversation
                          //       if (conversation.id == chatProvider.currentConversationId) {
                          //         // Just scroll to bottom if messages exist
                          //         if (chatProvider.messages.isNotEmpty) {
                          //           WidgetsBinding.instance
                          //               .addPostFrameCallback((_) {
                          //                 _scrollToBottom();
                          //               });
                          //         }
                          //         return;
                          //       }
                          //
                          //       // Show loading feedback
                          //       if (mounted) {
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).showSnackBar(
                          //           SnackBar(
                          //             content: Row(
                          //               children: [
                          //                 SizedBox(
                          //                   width: 16,
                          //                   height: 16,
                          //                   child:
                          //                       CircularProgressIndicator(
                          //                         strokeWidth: 2,
                          //                         color: Colors.white,
                          //                       ),
                          //                 ),
                          //                 SizedBox(width: 12),
                          //                 Expanded(
                          //                   child: Text(
                          //                     'Loading "${conversation.title.length > 30 ? conversation.title.substring(0, 30) + '...' : conversation.title}"',
                          //                   ),
                          //                 ),
                          //               ],
                          //             ),
                          //             backgroundColor: Colors.blue.shade600,
                          //             duration: Duration(seconds: 2),
                          //           ),
                          //         );
                          //       }
                          //
                          //       // Load the conversation
                          //       // await chatProvider.loadConversation(
                          //       //   conversation.id,
                          //       // );
                          //
                          //       Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatScreen()));
                          //
                          //
                          //       // Clear loading snackbar
                          //       if (mounted) {
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).hideCurrentSnackBar();
                          //       }
                          //
                          //       // Show result feedback
                          //       if (chatProvider.messages.isNotEmpty) {
                          //         if (mounted) {
                          //           ScaffoldMessenger.of(
                          //             context,
                          //           ).showSnackBar(
                          //             SnackBar(
                          //               content: Text(
                          //                 'Loaded ${chatProvider.messages.length} messages',
                          //               ),
                          //               backgroundColor:
                          //                   Colors.green.shade600,
                          //               duration: Duration(seconds: 1),
                          //             ),
                          //           );
                          //         }
                          //
                          //         // Scroll to bottom after loading
                          //         WidgetsBinding.instance
                          //             .addPostFrameCallback((_) {
                          //               _scrollToBottom();
                          //             });
                          //       } else {
                          //         // Conversation loaded but empty - this is OK, don't show as error
                          //         if (mounted) {
                          //           ScaffoldMessenger.of(
                          //             context,
                          //           ).showSnackBar(
                          //             SnackBar(
                          //               content: Text(
                          //                 'This conversation is empty. Start chatting!',
                          //               ),
                          //               backgroundColor:
                          //                   Colors.blue.shade600,
                          //               duration: Duration(seconds: 2),
                          //             ),
                          //           );
                          //         }
                          //       }
                          //     } catch (e) {
                          //       print('Error loading conversation: $e');
                          //
                          //       // Clear loading snackbar
                          //       if (mounted) {
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).hideCurrentSnackBar();
                          //       }
                          //
                          //       // Show error with retry option
                          //       if (mounted) {
                          //         ScaffoldMessenger.of(
                          //           context,
                          //         ).showSnackBar(
                          //           SnackBar(
                          //             content: Column(
                          //               mainAxisSize: MainAxisSize.min,
                          //               crossAxisAlignment:
                          //                   CrossAxisAlignment.start,
                          //               children: [
                          //                 Text(
                          //                   'Failed to load conversation',
                          //                 ),
                          //                 if (e.toString().isNotEmpty)
                          //                   Text(
                          //                     e.toString().length > 60
                          //                         ? '${e.toString().substring(0, 60)}...'
                          //                         : e.toString(),
                          //                     style: TextStyle(
                          //                       fontSize: 12,
                          //                       color: Colors.white70,
                          //                     ),
                          //                   ),
                          //               ],
                          //             ),
                          //             backgroundColor: Colors.red.shade600,
                          //             duration: Duration(seconds: 4),
                          //             action: SnackBarAction(
                          //               label: 'RETRY',
                          //               textColor: Colors.white,
                          //               onPressed: () async {
                          //                 try {
                          //                   await chatProvider
                          //                       .loadConversation(
                          //                         conversation.id,
                          //                       );
                          //                   if (chatProvider
                          //                       .messages
                          //                       .isNotEmpty) {
                          //                     ScaffoldMessenger.of(
                          //                       context,
                          //                     ).showSnackBar(
                          //                       SnackBar(
                          //                         content: Text(
                          //                           'Successfully loaded conversation',
                          //                         ),
                          //                         backgroundColor:
                          //                             Colors.green.shade600,
                          //                         duration: Duration(
                          //                           seconds: 1,
                          //                         ),
                          //                       ),
                          //                     );
                          //                     _scrollToBottom();
                          //                   }
                          //                 } catch (retryError) {
                          //                   ScaffoldMessenger.of(
                          //                     context,
                          //                   ).showSnackBar(
                          //                     SnackBar(
                          //                       content: Text(
                          //                         'Retry failed. Please try again later.',
                          //                       ),
                          //                       backgroundColor:
                          //                           Colors.red.shade600,
                          //                       duration: Duration(
                          //                         seconds: 2,
                          //                       ),
                          //                     ),
                          //                   );
                          //                 }
                          //               },
                          //             ),
                          //           ),
                          //         );
                          //       }
                          //     }
                          //   },
                          trailing:
                              chatProvider.isLoadingConversation &&
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
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
          SizedBox(height: 40),
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
            'Hello! I\'m IRIS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          Text(
            'How can I help you today',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 32),
          if (_showQuickQuestions) _buildQuickQuestions(),
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
        SizedBox(height: 16),
        Column(
          children: _quickQuestions.map((question) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
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
                          color: Colors.black.withOpacity(0.05),
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
      ],
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
                    color: Colors.black.withOpacity(0.05),
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
      ..color = Colors.green.withOpacity(0.02)
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
