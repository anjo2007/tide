import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tide/models/category_model.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';

class TaskEditorScreen extends StatefulWidget {
  final String userId;
  final TaskModel? existingTask;

  const TaskEditorScreen({
    super.key,
    required this.userId,
    this.existingTask,
  });

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskInputController = TextEditingController();

  String _selectedCategoryId = 'work';
  String _selectedPriority = 'Medium';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  
  List<SubtaskModel> _subtasks = [];

  XFile? _pickerImageFile;
  Uint8List? _webImageBytes;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _descController.text = task.description;
      _selectedCategoryId = task.categoryId;
      _selectedPriority = task.priority;
      _selectedDate = task.dueDate;
      _selectedTime = TimeOfDay(hour: task.dueDate.hour, minute: task.dueDate.minute);
      _subtasks = List.from(task.subtasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _pickerImageFile = image;
            _webImageBytes = bytes;
          });
        } else {
          setState(() {
            _pickerImageFile = image;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addSubtask() {
    final title = _subtaskInputController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subtasks.add(
          SubtaskModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            isCompleted: false,
          ),
        );
        _subtaskInputController.clear();
      });
    }
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final combinedDueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      setState(() => _isUploadingImage = true);

      if (widget.existingTask != null) {
        var updatedTask = widget.existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          priority: _selectedPriority,
          dueDate: combinedDueDate,
          subtasks: _subtasks,
        );

        if (_pickerImageFile != null) {
          await provider.uploadAndSetTaskImage(
            task: updatedTask,
            imageFile: _pickerImageFile!,
            webImageBytes: _webImageBytes,
          );
        } else {
          await provider.updateTask(updatedTask);
        }
      } else {
        await provider.createTask(
          userId: widget.userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          categoryId: _selectedCategoryId,
          priority: _selectedPriority,
          dueDate: combinedDueDate,
          subtasks: _subtasks,
          imageFile: _pickerImageFile,
          webImageBytes: _webImageBytes,
        );
      }

      setState(() => _isUploadingImage = false);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;
    final formattedDate = DateFormat('EEEE, MMM d, y').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.goldAccent),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: isDesktop ? 600 : double.infinity,
            padding: isDesktop ? const EdgeInsets.all(28) : EdgeInsets.zero,
            decoration: isDesktop
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(color: const Color(0xFFECE7DF), width: 1.5),
                  )
                : null,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'What needs to be done?',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details or notes...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Category', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CategoryModel.defaultCategories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            avatar: Icon(
                              cat.iconData,
                              size: 16,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                            selectedColor: cat.color,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : const Color(0xFFECE7DF),
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategoryId = cat.id);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Low', 'Medium', 'High'].map((prio) {
                      final isSelected = _selectedPriority == prio;
                      Color chipColor;
                      switch (prio) {
                        case 'High':
                          chipColor = AppTheme.dangerRose;
                          break;
                        case 'Medium':
                          chipColor = AppTheme.goldAccent;
                          break;
                        default:
                          chipColor = AppTheme.infoBlue;
                      }

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(prio)),
                            selected: isSelected,
                            selectedColor: chipColor,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : const Color(0xFFECE7DF),
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedPriority = prio);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DUE DATE',
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(formattedDate, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null) setState(() => _selectedTime = picked);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DUE TIME',
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(formattedTime, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Photo Attachment', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_pickerImageFile != null || (widget.existingTask != null && widget.existingTask!.imageUrl != null)) ...[
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFECE7DF)),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: _webImageBytes != null
                                  ? MemoryImage(_webImageBytes!)
                                  : (!kIsWeb && _pickerImageFile != null)
                                      ? FileImage(File(_pickerImageFile!.path)) as ImageProvider
                                      : NetworkImage(widget.existingTask?.imageUrl ?? '') as ImageProvider,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
                          onPressed: () {
                            setState(() {
                              _pickerImageFile = null;
                              _webImageBytes = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                      label: const Text('Add Photo'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Subtasks Checklist', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskInputController,
                          decoration: const InputDecoration(
                            hintText: 'Add a subtask...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _addSubtask,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.goldAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_subtasks.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subtasks.length,
                      itemBuilder: (context, index) {
                        final sub = _subtasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFECE7DF)),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            leading: Icon(
                              sub.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: sub.isCompleted ? AppTheme.successSage : AppTheme.textMuted,
                              size: 18,
                            ),
                            title: Text(
                              sub.title,
                              style: TextStyle(
                                decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                color: sub.isCompleted ? AppTheme.textMuted : AppTheme.textDark,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFC05A5A)),
                              onPressed: () => _removeSubtask(sub.id),
                            ),
                          ),
                        );
                      },
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
