import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/models/category_model.dart';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _apiKeyPrefsKey = 'gemini_api_key';
  static const String _modelPrefsKey = 'gemini_model_name';

  // Get saved API key
  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefsKey) ?? '';
  }

  // Save API key
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, apiKey.trim());
  }

  // Get saved Model Name
  Future<String> getModelName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefsKey) ?? 'gemini-1.5-flash';
  }

  // Save Model Name
  Future<void> saveModelName(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefsKey, modelName.trim());
  }

  // Send message to Gemini with task list context
  Future<String> getAIResponse({
    required String userMessage,
    required List<TaskModel> tasks,
  }) async {
    final apiKey = await getApiKey();
    final modelName = await getModelName();

    if (apiKey.isEmpty) {
      // No API key - Run offline mock intelligence
      return _getMockResponse(userMessage, tasks);
    }

    // 1. Construct system instruction context containing the user's tasks
    final now = DateTime.now();
    final tasksContext = tasks.map((t) {
      final category = CategoryModel.defaultCategories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => CategoryModel(id: 'other', name: 'Other', iconName: 'bookmark', colorValue: 0xFF7A868A),
      );
      return '- ID: ${t.id}, Title: "${t.title}", Desc: "${t.description}", Board: ${category.name}, Priority: ${t.priority}, Due: ${t.dueDate.toIso8601String()}, Done: ${t.isCompleted}';
    }).join('\n');

    final systemInstruction = '''
You are Tide AI, an advanced, premium, and friendly productivity assistant built into the Tide Task Manager.
You have direct, real-time access to the user's task database to answer their questions.

Current Local Time: ${now.toIso8601String()}

Here is the user's current task list:
$tasksContext

Instructions:
1. Always analyze the task list above when answering queries about overdue tasks, weekly agendas, summaries, or suggestions.
2. Answer concisely in clean, beautiful Markdown.
3. If they ask about "most overdue task", locate the incomplete tasks whose due dates are in the past, pick the oldest one, and describe it clearly.
4. If they ask to "summarize this week", count tasks due, completed rates, priority highlights, and write a summary.
5. If they ask to "suggest tasks", suggest 3 smart, highly relevant tasks based on the categories they currently work on (e.g. Work, Personal, Shopping).
''';

    // 2. Initialize Gemini Model
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    // 3. Generate content with automatic retries for transient server errors (503, 429)
    int maxRetries = 3;
    int delaySeconds = 1;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final content = [Content.text(userMessage)];
        final response = await model.generateContent(content);
        return response.text ?? 'I received an empty response from Gemini. Please try again.';
      } catch (e) {
        final errStr = e.toString();
        final isTransientError = errStr.contains('503') || errStr.contains('429') || errStr.contains('UNAVAILABLE');

        if (isTransientError && attempt < maxRetries) {
          debugPrint('Gemini transient error (attempt $attempt/$maxRetries): $e. Retrying in $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
          delaySeconds *= 2; // exponential backoff
          continue;
        }

        debugPrint('Gemini API Error (attempt $attempt/$maxRetries): $e');
        if (attempt == maxRetries) {
          if (errStr.contains('503') || errStr.contains('UNAVAILABLE')) {
            return '⚠️ **Tide AI is temporarily overloaded:** The Gemini model is currently experiencing extremely high demand.\n\n'
                   '*Tip: Try opening the chat settings gear ⚙️ and choosing a different model (such as Gemini 1.5 Pro or Gemini 2.0 Flash) to use another server cluster.*';
          }
          return 'Error connecting to Gemini: $errStr\n\n*Tip: Double-check your API key in the chat settings gear.*';
        }
      }
    }
    return 'Failed to obtain response from Gemini after multiple attempts. Please try again later.';
  }

  // High-fidelity local Dart-based parser for Offline Mock Mode
  Future<String> _getMockResponse(String message, List<TaskModel> tasks) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final cleanMsg = message.toLowerCase().trim();
    final now = DateTime.now();

    // 1. "What's my most overdue task?"
    if (cleanMsg.contains('overdue') || cleanMsg.contains('most overdue')) {
      final overdueTasks = tasks.where((t) {
        if (t.isCompleted) return false;
        // Check if due date is before today (and not today)
        return t.dueDate.isBefore(now) &&
            !(t.dueDate.year == now.year && t.dueDate.month == now.month && t.dueDate.day == now.day);
      }).toList();

      if (overdueTasks.isEmpty) {
        return "✨ **Tide AI:** Great news! You have **no overdue tasks** currently. Keep up the gentle flow!";
      }

      // Sort by due date (oldest first)
      overdueTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final mostOverdue = overdueTasks.first;
      final daysAgo = now.difference(mostOverdue.dueDate).inDays;
      final formattedDate = "${mostOverdue.dueDate.month}/${mostOverdue.dueDate.day}";

      return """
⚠️ **Your Most Overdue Task:**

*   **Task:** **${mostOverdue.title}**
*   **Due Date:** $formattedDate (${daysAgo == 0 ? 'Yesterday' : '$daysAgo days ago'})
*   **Priority:** `${mostOverdue.priority}`
*   **Notes:** ${mostOverdue.description.isNotEmpty ? mostOverdue.description : 'No notes added.'}

*Recommendation: Tackle this task first to clear your mind!*
""";
    }

    // 2. "Summarize this week"
    if (cleanMsg.contains('summarize') || cleanMsg.contains('summary') || cleanMsg.contains('week')) {
      final completed = tasks.where((t) => t.isCompleted).length;
      final pending = tasks.where((t) => !t.isCompleted).length;
      final highPrio = tasks.where((t) => t.priority == 'High' && !t.isCompleted).length;
      
      final completionRate = tasks.isEmpty ? 0 : ((completed / tasks.length) * 100).toInt();

      return """
📊 **Weekly Productivity Summary:**

Here is the status of your tasks:
*   **Total Tasks:** ${tasks.length}
*   **Completed:** $completed
*   **Pending:** $pending
*   **Urgent (High Priority):** $highPrio
*   **Completion Rate:** `$completionRate%`

💡 **AI Insights:**
${completionRate > 50 ? '🎉 You are doing great! More than half of your tasks are completed.' : '🌊 Take a deep breath. Focus on your High Priority tasks first to build momentum.'}
""";
    }

    // 3. "Suggest tasks for my project"
    if (cleanMsg.contains('suggest') || cleanMsg.contains('recommend') || cleanMsg.contains('project')) {
      // Find the most active category
      final categoryCounts = <String, int>{};
      for (var t in tasks) {
        categoryCounts[t.categoryId] = (categoryCounts[t.categoryId] ?? 0) + 1;
      }

      var topCategory = 'work';
      var maxCount = 0;
      categoryCounts.forEach((key, val) {
        if (val > maxCount) {
          maxCount = val;
          topCategory = key;
        }
      });

      final category = CategoryModel.defaultCategories.firstWhere(
        (c) => c.id == topCategory,
        orElse: () => CategoryModel(id: 'work', name: 'Work', iconName: 'work', colorValue: 0xFFC5A059),
      );

      return """
💡 **Suggested Tasks for your "${category.name}" board:**

Based on your current focus, here are 3 recommended follow-up actions:
1.  **Review progress milestones** — Block out 15 minutes to organize outstanding items on this board.
2.  **Define next subtasks** — Break down your largest pending task into 3 manageable chunks.
3.  **Clean up archives** — Mark older, completed tasks as done or delete items you no longer need.

*Note: Configure your Gemini API key in the chat settings to receive personalized, advanced suggestions!*
""";
    }

    // Generic response
    return """
👋 **Hello! I am Tide AI.**

I can help you analyze your tasks and plan your workflow. Try asking me:
*   *"What's my most overdue task?"*
*   *"Summarize this week"*
*   *"Suggest tasks for my project"*

*💡 Note: Connect your Gemini API Key in the chat settings (gear icon) to unlock real-time advanced conversational intelligence.*
""";
  }

  // Validate API key and fetch supported models from Google AI
  Future<Map<String, dynamic>> validateApiKeyAndGetModels(String apiKey) async {
    if (apiKey.isEmpty) {
      return {'success': false, 'error': 'API key cannot be empty.'};
    }
    
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> modelsList = data['models'] ?? [];
        
        // Extract model names that support generateContent method
        final List<String> availableModels = [];
        for (var m in modelsList) {
          final String name = m['name'] ?? '';
          final List<dynamic> methods = m['supportedGenerationMethods'] ?? [];
          
          if (methods.contains('generateContent')) {
            // strip the "models/" prefix for clean display
            final cleanName = name.replaceFirst('models/', '');
            availableModels.add(cleanName);
          }
        }
        
        return {
          'success': true,
          'models': availableModels,
        };
      } else {
        // Parse error response
        try {
          final errData = json.decode(response.body);
          final errorMsg = errData['error']?['message'] ?? 'Status Code: ${response.statusCode}';
          return {'success': false, 'error': errorMsg};
        } catch (_) {
          return {'success': false, 'error': 'Failed with Status Code: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: ${e.toString()}'};
    }
  }
}
