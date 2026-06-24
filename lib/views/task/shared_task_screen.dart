import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tide/models/category_model.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';

class SharedTaskScreen extends StatefulWidget {
  final String taskId;

  const SharedTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<SharedTaskScreen> createState() => _SharedTaskScreenState();
}

class _SharedTaskScreenState extends State<SharedTaskScreen> {
  TaskModel? _task;
  String? _ownerName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSharedTask();
  }

  Future<void> _loadSharedTask() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final data = await provider.getSharedTask(widget.taskId);
      if (mounted) {
        setState(() {
          if (data != null) {
            _task = data['task'] as TaskModel;
            _ownerName = data['ownerName'] as String?;
          } else {
            _errorMessage = 'The shared task could not be found or has been deleted.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load the shared task: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.goldAccent),
        ),
      );
    } else if (_errorMessage != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.dangerRose),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    } else {
      final task = _task!;
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

      bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Owner Info Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.goldLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE7DF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.share_rounded, color: AppTheme.goldAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textDark),
                      children: [
                        const TextSpan(text: 'Viewing a read-only shared task from '),
                        TextSpan(
                          text: _ownerName ?? 'a Tide user',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Attached Photo
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

          // Badges Row
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

          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? AppTheme.successSage : AppTheme.goldAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
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

          // Description
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

          // Due Date
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

          // Subtasks
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
                    onChanged: null, // Read-only view
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Task'),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
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
            child: bodyContent,
          ),
        ),
      ),
    );
  }
}
