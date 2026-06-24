import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tide/models/category_model.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';
import 'package:tide/views/task/task_detail_screen.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.filteredTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 48,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All Clear!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tasks found for the current selection.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task, taskProvider);
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task, TaskProvider provider) {
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

    final formattedDate = DateFormat('MMM d, y').format(task.dueDate);
    
    final today = DateTime.now();
    final isOverdue = task.dueDate.isBefore(today) && 
        !task.isCompleted && 
        !(task.dueDate.year == today.year && task.dueDate.month == today.month && task.dueDate.day == today.day);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          final tempTask = task;
          provider.deleteTask(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${tempTask.title}" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  provider.updateTask(tempTask);
                },
              ),
            ),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.dangerRose,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(taskId: task.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.premiumShadow,
              border: Border.all(
                color: const Color(0xFFECE7DF),
                width: 1.2,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: task.isCompleted ? AppTheme.successSage : AppTheme.goldAccent,
                                  size: 24,
                                ),
                                onPressed: () {
                                  provider.toggleTaskCompletion(task.id);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: task.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                ),
                              ),
                              if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.image_outlined, size: 18, color: AppTheme.textMuted),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (task.description.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(
                                task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: category.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.iconData,
                                        size: 12,
                                        color: category.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          color: category.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: isOverdue ? const Color(0xFFC05A5A) : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: isOverdue ? const Color(0xFFC05A5A) : AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                if (task.subtasks.isNotEmpty) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.checklist_rounded, size: 12, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
