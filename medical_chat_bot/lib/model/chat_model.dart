class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? messageId;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
    this.messageId,
  }) : timestamp = timestamp ?? DateTime.now();
}
