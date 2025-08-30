
class User {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;

  User({
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      username: json['username'],
    );
  }
}

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class Conversation {
  final String threadId;
  final List<Message> messages;

  Conversation({
    required this.threadId,
    required this.messages,
  });
}