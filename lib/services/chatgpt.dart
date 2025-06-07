import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatGptService {
  String apiKey = dotenv.env['OPENAI_API'] ?? 'API KEY NOT FOUND';

  Map<String, List<Map<String, String>>> _allConversations = {};
  String _currentSessionId = DateTime.now().toIso8601String();

  ChatGptService() {
    _loadAllConversations();
  }

  String get currentSessionId => _currentSessionId;

  List<Map<String, String>> get currentHistory =>
      _allConversations[_currentSessionId] ?? [];

  Map<String, List<Map<String, String>>> get allConversations =>
      _allConversations;

  void setCurrentSession(String sessionId) {
    _currentSessionId = sessionId;
  }

  Future<void> _loadAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('all_conversations');
    if (raw != null) {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      _allConversations = decoded.map(
        (key, value) => MapEntry(key, List<Map<String, String>>.from(value)),
      );
    }
  }

  Future<void> _saveAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('all_conversations', jsonEncode(_allConversations));
  }

  Future<List<String>> getConversationIds() async {
    await _loadAllConversations();
    return _allConversations.keys.toList();
  }

  void startNewSession() {
    _currentSessionId = DateTime.now().toIso8601String();
    _allConversations[_currentSessionId] = [];
    _saveAllConversations();
  }

  Future<String> getChatGptResponse(String userInput) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    if (_isImagePrompt(userInput)) {
      return await generateImage(userInput);
    }

    final session = _allConversations[_currentSessionId] ?? [];
    session.add({"role": "user", "content": userInput});

    if (session.length > 10) session.removeAt(0);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content':
                // Edit this system prompt to change the behavior of the AI
                'You are ChatBot, an AI assistant created by Mantresh. '
                'You help users with daily tasks, calculations, and coding. '
                'You remember previous interactions for better responses.',
          },
          ...session,
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'].trim();

      session.add({"role": "assistant", "content": reply});
      _allConversations[_currentSessionId] = session;

      await _saveAllConversations();
      return reply;
    } else {
      throw Exception(
        'Failed to get response: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> generateImage(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/images/generations');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'prompt': prompt, 'n': 1, 'size': '1024x1024'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'][0]['url'];
    } else {
      throw Exception(
        'Failed to generate image: ${response.statusCode} ${response.body}',
      );
    }
  }

  bool _isImagePrompt(String input) {
    final lowerInput = input.toLowerCase();
    return lowerInput.contains("create an image") ||
        lowerInput.contains("generate an image") ||
        lowerInput.contains("draw") ||
        lowerInput.contains("picture of") ||
        lowerInput.contains("image of");
  }
}
