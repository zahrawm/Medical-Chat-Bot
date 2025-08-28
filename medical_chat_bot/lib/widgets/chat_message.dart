import 'package:flutter/material.dart';
import 'package:medical_chat_bot/model/chat_model.dart';


class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: message.isBot ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0),
                  bottomLeft: message.isBot ? Radius.circular(4.0) : Radius.circular(18.0),
                  bottomRight: message.isBot ? Radius.circular(18.0) : Radius.circular(4.0),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isBot ? Colors.black87 : Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          if (!message.isBot) ...[
            Container(
              margin: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey[400],
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

