import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatGptService {
  String apiKey = dotenv.env['OPENAI_API'] ?? 'API KEY NOT FOUND';

  List<Map<String, String>> _conversationHistory = [];

  ChatGptService() {
    _loadConversationHistory(); // Load history when the service is initialized
  }

  Future<void> _loadConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedHistory = prefs.getString('chat_history');
    if (savedHistory != null) {
      _conversationHistory = List<Map<String, String>>.from(
        jsonDecode(savedHistory),
      );
    }
  }

  Future<void> _saveConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_conversationHistory));
  }

  Future<String> getChatGptResponse(String userInput) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Detect if the user wants to generate an image
    if (_isImagePrompt(userInput)) {
      return await generateImage(userInput);
    }

    _conversationHistory.add({"role": "user", "content": userInput});

    // Maintain a conversation window of the last 10 exchanges
    if (_conversationHistory.length > 10) {
      _conversationHistory.removeAt(0);
    }

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
                'You are ChatBot an AI assistant created by Mantresh. '
                'You help users with daily tasks, calculations, and coding. '
                'You also remember previous interactions for better responses.',
          },
          ..._conversationHistory,
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final assistantResponse = data['choices'][0]['message']['content'].trim();

      _conversationHistory.add({
        "role": "assistant",
        "content": assistantResponse,
      });

      await _saveConversationHistory(); // Save updated history

      return assistantResponse;
    } else {
      throw Exception('Failed to load response');
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
      return data['data'][0]['url']; // Return image URL
    } else {
      throw Exception('Failed to generate image');
    }
  }

  bool _isImagePrompt(String input) {
    final lowerInput = input.toLowerCase();
    return lowerInput.contains("create an image") ||
        lowerInput.contains("generate an image") ||
        lowerInput.contains("draw") ||
        lowerInput.contains("picture of");
  }

  Future<void> clearConversationHistory() async {
    _conversationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}
