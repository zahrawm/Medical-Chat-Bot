import 'package:flutter/material.dart';
import 'package:medical_chat_bot/provider/auth_provider.dart';
import 'package:medical_chat_bot/provider/chat_provider.dart';
import 'package:medical_chat_bot/service/api_service.dart';
import 'package:medical_chat_bot/service/auth_wrapper.dart';
import 'package:provider/provider.dart';

main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider ()),
        ChangeNotifierProvider(create: (_) => ChatProvider(ApiService())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IRIS Chat', 
        theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
        home: AuthWrapper(),
      ),
    );
  }
}
