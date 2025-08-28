class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}