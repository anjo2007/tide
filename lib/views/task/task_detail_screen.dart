import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tide/models/category_model.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/providers/auth_provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';
import 'package:tide/views/task/task_editor_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    final taskIdx = taskProvider.tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx < 0) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }
    
    final TaskModel task = taskProvider.tasks[taskIdx];
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    final category = CategoryModel.defaultCategories.firstWhere(
      (c) => c.id == task.categoryId,
      orElse: () => CategoryModel(id: 'other', name: 'Other', iconName: 'bookmark', colorValue: 0xFF7A868A),
    );

    Color priorityColor;
    switch (task.priority) {
      case 'High':
        priorityColor = AppTheme.dangerRose;
        break;
      case 'Medium':
        priorityColor = AppTheme.goldAccent;
        break;
      default:
        priorityColor = AppTheme.infoBlue;
    }

    final formattedDate = DateFormat('EEEE, MMM d, y • h:mm a').format(task.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.goldAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskEditorScreen(
                    userId: task.userId,
                    existingTask: task,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.goldAccent),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final ownerName = auth.user?.displayName ?? 'A Tide User';
              final shareUrl = await taskProvider.shareTask(task, ownerName);
              
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Share Task'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Anyone with this link can view a read-only snapshot of this task:',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFECE7DF)),
                          ),
                          child: SelectableText(
                            shareUrl,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text('CLOSE', style: TextStyle(color: AppTheme.textMuted)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('COPY LINK', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC05A5A)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task?'),
                  content: const Text('Are you sure you want to permanently delete this task?'),
                  actions: [
                    TextButton(
                      child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('DELETE', style: TextStyle(color: Color(0xFFC05A5A))),
                      onPressed: () {
                        taskProvider.deleteTask(task.id);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isDesktop ? 650 : double.infinity,
            padding: isDesktop ? const EdgeInsets.all(32) : EdgeInsets.zero,
            decoration: isDesktop
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(color: const Color(0xFFECE7DF), width: 1.5),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppTheme.goldLight.withOpacity(0.3),
                        border: Border.all(color: const Color(0xFFECE7DF)),
                      ),
                      child: Image.network(
                        task.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppTheme.goldAccent),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: priorityColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.priority} Priority',
                            style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: category.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.iconData, size: 14, color: category.color),
                          const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: TextStyle(color: category.color, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(
                        task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: task.isCompleted ? AppTheme.successSage : AppTheme.goldAccent,
                        size: 28,
                      ),
                      onPressed: () {
                        taskProvider.toggleTaskCompletion(task.id);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (task.description.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF9F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE7DF)),
                    ),
                    child: Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Due: $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (task.subtasks.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Subtasks Checklist',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: task.subtasks.length,
                    itemBuilder: (context, index) {
                      final sub = task.subtasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFECE7DF)),
                        ),
                        child: CheckboxListTile(
                          value: sub.isCompleted,
                          onChanged: (_) {
                            taskProvider.toggleSubtaskCompletion(task.id, sub.id);
                          },
                          title: Text(
                            sub.title,
                            style: TextStyle(
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                              color: sub.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                            ),
                          ),
                          activeColor: AppTheme.successSage,
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
