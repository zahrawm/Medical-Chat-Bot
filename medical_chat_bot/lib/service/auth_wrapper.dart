import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import 'package:medical_chat_bot/screen/chat_screen.dart';
import 'package:medical_chat_bot/screen/login_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadSavedToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return ChangeNotifierProvider(
            create: (_) => ChatProvider(authProvider.apiService),
            child: ChatScreen(),
          );
        } else {
          return AuthScreen();
        }
      },
    );
  }
}

