import 'package:chatbot/pages/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color(0xFF2C2C2E),
          primaryContainer: Color(0xFF3A3A3C),
          secondary: Color(0xFF4D4D4F),
          secondaryContainer: Color(0xFF3A3A3C),
          surface: Color(0xFF1C1C1E),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2C2C2E)),
        cardColor: const Color(0xFF2C2C2E),
        dialogBackgroundColor: const Color(0xFF2C2C2E),
      ),
      home: const SafeArea(child: ChatPage()),
    );
  }
}
