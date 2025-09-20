import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import 'package:medical_chat_bot/screen/chat_message_screen.dart';
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
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadSavedToken();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
      
        if (!authProvider.isInitialized) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset("assets/logo.png", height: 100),
                    ),
                    SizedBox(height: 32),
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Iris Chat Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // If user is authenticated, show main app
        if (authProvider.isAuthenticated) {
          return ChangeNotifierProvider(
            create: (_) => ChatProvider(authProvider.apiService),
            child: ChatScreen(),
          );
        }

        // Show login screen for non-authenticated users
        return AuthScreen();
      },
    );
  }
}
