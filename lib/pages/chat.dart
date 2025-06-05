import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:chatbot/services/chatgpt.dart';
import 'package:chatbot/widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatGptService _chatGptService = ChatGptService();

  List<Map<String, dynamic>> _messages = [];
  List<String> _conversationIds = [];

  bool _isTyping = false;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final ids = await _chatGptService.getConversationIds();
    setState(() {
      _conversationIds = ids;
    });
  }

  void _sendMessage(String message) async {
    setState(() {
      _messages.add({
        "message": message,
        "isUser": true,
        "time": _getCurrentTime(),
      });
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatGptService.getChatGptResponse(message);
      final isImage =
          Uri.tryParse(response)?.hasAbsolutePath == true &&
          (response.endsWith('.png') ||
              response.endsWith('.jpg') ||
              response.contains('openai.com'));

      setState(() {
        _messages.add({
          "message": response,
          "isUser": false,
          "isImage": isImage,
          "time": _getCurrentTime(),
        });
        _isTyping = false;
      });

      _loadConversations(); // Refresh sidebar list
    } catch (e) {
      setState(() {
        _messages.add({
          "message": "Sorry, something went wrong.",
          "isUser": false,
          "time": _getCurrentTime(),
        });
        _isTyping = false;
      });
    }

    _scrollToBottom();
    _controller.clear();
  }

  void _startNewChat() {
    _chatGptService.startNewSession();
    setState(() {
      _messages.clear();
    });
    _loadConversations();
  }

  void _loadConversation(String sessionId) {
    final history = _chatGptService.allConversations[sessionId] ?? [];
    _chatGptService.setCurrentSession(sessionId);

    setState(() {
      _messages =
          history.map((m) {
            return {
              "message": m["content"],
              "isUser": m["role"] == "user",
              "time": _getCurrentTime(),
            };
          }).toList();
    });
  }

  String _getCurrentTime() {
    return DateFormat('h:mm a').format(DateTime.now());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Row(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 0 : 250,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(
                    _isSidebarCollapsed ? 0 : 15.0,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.white),
                      title: const Text(
                        "New Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: _startNewChat,
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _conversationIds.length,
                        itemBuilder: (context, index) {
                          final id = _conversationIds[index];
                          return ListTile(
                            title: Text(
                              'Chat ${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () => _loadConversation(id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleSidebar,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isSidebarCollapsed
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    key: ValueKey(_isSidebarCollapsed),
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 7.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const TypingIndicator(),
                          ),
                        );
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message["isUser"];
    final String text = message["message"];
    final String time = message["time"];
    final bool isImage = message["isImage"] ?? false;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            isImage
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    text,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        "Image failed to load",
                        style: TextStyle(color: Colors.red),
                      );
                    },
                  ),
                )
                : MarkdownBody(
                  data: text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white),
                    a: const TextStyle(color: Colors.blueAccent),
                    strong: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    code: const TextStyle(color: Colors.yellow),
                  ),
                ),
            const SizedBox(height: 6),
            Text(
              time,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                cursorColor: Colors.grey,
                decoration: const InputDecoration(
                  hintText: "Ask ChatBot...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _sendMessage(value.trim());
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                CupertinoIcons.paperplane_fill,
                color: Colors.white,
              ),
              onPressed:
                  _isTyping || _controller.text.trim().isEmpty
                      ? null
                      : () => _sendMessage(_controller.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}
