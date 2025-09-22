import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medical_chat_bot/model/chat_model.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool shouldAnimate;

  MessageBubble({required this.message, this.shouldAnimate = false});

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late AnimationController _fadeController;
  String _displayedText = '';
  bool _isBot = false;

  @override
  void initState() {
    super.initState();

    _isBot = !widget.message.isUser;
    final fullText = widget.message.content;

    _typewriterController = AnimationController(
      duration: Duration(
        milliseconds:
            fullText.length * 3 + 100, // Changed from 8 to 3, and 200 to 100
      ),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 50),
      vsync: this,
    );

    if (_isBot && widget.shouldAnimate && fullText.isNotEmpty) {
      _animateText(fullText);
    } else {
      _displayedText = fullText;
      _fadeController.forward();
    }
  }

  void _animateText(String fullText) {
    // Start with fade in
    _fadeController.forward();

    _typewriterController.addListener(() {
      final progress = _typewriterController.value;
      final charactersToShow = (progress * fullText.length).floor();

      setState(() {
        _displayedText = fullText.substring(0, charactersToShow);
      });
    });

    // Start typing animation after a small delay
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) {
        _typewriterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: widget.message.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.message.isUser) ...[
              Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/logo.png', height: 30, width: 30)),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.message.isUser
                      ? Colors.green.shade600
                      : Colors.grey.shade100,
                  borderRadius: widget.message.isUser
                      ? BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        )
                      : BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(18),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _isBot
                              ? MarkdownBody(
                                  data: _displayedText,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                    h1: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    code: TextStyle(
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    blockquote: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : Text(
                                  _displayedText,
                                  style: TextStyle(
                                    color: widget.message.isUser
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        // Show typing cursor for bot messages during animation
                        if (!widget.message.isUser &&
                            widget.shouldAnimate &&
                            _typewriterController.isAnimating)
                          AnimatedBuilder(
                            animation: _typewriterController,
                            builder: (context, child) {
                              final cursorOpacity =
                                  (_typewriterController.value * 4) % 1.0 > 0.5
                                  ? 1.0
                                  : 0.0;
                              return AnimatedOpacity(
                                opacity: cursorOpacity,
                                duration: Duration(milliseconds: 50),
                                child: Container(
                                  margin: EdgeInsets.only(left: 2),
                                  width: 2,
                                  height: 16,
                                  color: const Color.fromARGB(255, 10, 65, 12),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    // Timestamp
                    if (_displayedText.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          _formatTime(widget.message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.message.isUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.message.isUser) ...[
              SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4BB543), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                    return Text(
                      _getProfileInitials(authProvider),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                      }),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

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

}
