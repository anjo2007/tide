import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/services/ai_service.dart';
import 'package:tide/theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIAssistantPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AIAssistantPanel({super.key, required this.onClose});

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _showSettings = false;
  bool _hasApiKey = false;
  String _selectedModel = 'gemini-1.5-flash';
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _addInitialGreeting();
  }

  @override
  void dispose() {
    _textController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final key = await _aiService.getApiKey();
    final model = await _aiService.getModelName();
    setState(() {
      _apiKeyController.text = key;
      _hasApiKey = key.isNotEmpty;
      _selectedModel = model;
    });
  }

  void _addInitialGreeting() {
    _messages.add(
      ChatMessage(
        text: "Hello! I am Tide AI. I can analyze your workspace and help suggest tasks. Try asking me:\n\n• \"What's my most overdue task?\"\n• \"Summarize this week\"\n• \"Suggest tasks for my project\"",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _saveApiKey() async {
    await _aiService.saveApiKey(_apiKeyController.text.trim());
    setState(() {
      _hasApiKey = _apiKeyController.text.trim().isNotEmpty;
      _showSettings = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasApiKey ? 'Gemini API Key saved successfully!' : 'API Key cleared. Using local Mock Mode.'),
        ),
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.tasks;

    final aiResponse = await _aiService.getAIResponse(
      userMessage: text,
      tasks: tasks,
    );

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: Color(0xFFECE7DF), width: 1.5)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.creamBg,
              border: Border(bottom: BorderSide(color: Color(0xFFECE7DF), width: 1.5)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.waves_rounded, color: AppTheme.goldAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tide AI Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _hasApiKey ? AppTheme.successSage : AppTheme.goldAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasApiKey ? 'Gemini Live' : 'Mock Mode (No Key)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: _showSettings ? AppTheme.goldAccent : AppTheme.textMuted),
                    onPressed: () => setState(() => _showSettings = !_showSettings),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),

          // API Key Settings panel
          if (_showSettings)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                border: Border(bottom: BorderSide(color: Color(0xFFECE7DF))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gemini API Key Settings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                      ),
                      InkWell(
                        onTap: () {
                          // Inform user about Google AI Studio
                        },
                        child: const Text(
                          'Google AI Studio ↗',
                          style: TextStyle(color: AppTheme.infoBlue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Paste Gemini API Key...',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save_rounded, color: AppTheme.goldAccent),
                        onPressed: _saveApiKey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Model:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFECE7DF)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedModel,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldAccent),
                              onChanged: (String? val) async {
                                if (val != null) {
                                  await _aiService.saveModelName(val);
                                  setState(() {
                                    _selectedModel = val;
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash (Recommended)')),
                                DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro')),
                                DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('Gemini 2.0 Flash')),
                                DropdownMenuItem(value: 'gemini-1.0-pro', child: Text('Gemini 1.0 Pro')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFEA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.goldAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Suggestion Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECE7DF), width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSuggestionChip("What's my most overdue task?"),
                  _buildSuggestionChip("Summarize this week"),
                  _buildSuggestionChip("Suggest tasks for my project"),
                ],
              ),
            ),
          ),

          // Input Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (val) => _sendMessage(val),
                    decoration: const InputDecoration(
                      hintText: 'Ask Tide AI...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _sendMessage(_textController.text),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
        backgroundColor: AppTheme.goldLight,
        side: const BorderSide(color: Color(0xFFECE7DF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final alignRight = msg.isUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!alignRight) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.goldAccent,
              child: Icon(Icons.waves_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: alignRight ? AppTheme.goldLight : const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(alignRight ? 16 : 0),
                  bottomRight: Radius.circular(alignRight ? 0 : 16),
                ),
                border: Border.all(color: const Color(0xFFECE7DF), width: 1),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark, height: 1.4),
              ),
            ),
          ),
          if (alignRight) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.infoBlue,
              child: Icon(Icons.person_rounded, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
