class User {
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? dob;

  User({this.email, this.firstName, this.lastName, this.username, this.dob});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      username: json['username'],
      dob: json['dob'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Message copyWith({String? content, bool? isUser, DateTime? timestamp}) {
    return Message(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class Conversation {
  final String threadId;
  final List<Message> messages;

  Conversation({required this.threadId, required this.messages});

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      threadId: json['threadId'],
      messages: (json['messages'] as List)
          .map((msgJson) => Message.fromJson(msgJson))
          .toList(),
    );
  }
}
