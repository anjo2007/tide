import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tide/models/task_model.dart';
import 'package:tide/services/database_service.dart';
import 'package:tide/services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  // Filters & Sorting state
  String _searchQuery = '';
  String? _selectedCategoryId; // null = "All"
  String _priorityFilter = 'All'; // 'All', 'Low', 'Medium', 'High'
  String _statusFilter = 'All'; // 'All', 'Pending', 'Completed'
  String _sortBy = 'dueDate'; // 'dueDate', 'priority', 'createdAt'

  // Getters
  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  String get priorityFilter => _priorityFilter;
  String get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  // Setters for filters
  void setSearchQuery(String val) {
    _searchQuery = val;
    notifyListeners();
  }

  void setSelectedCategoryId(String? val) {
    _selectedCategoryId = val;
    notifyListeners();
  }

  void setPriorityFilter(String val) {
    _priorityFilter = val;
    notifyListeners();
  }

  void setStatusFilter(String val) {
    _statusFilter = val;
    notifyListeners();
  }

  void setSortBy(String val) {
    _sortBy = val;
    notifyListeners();
  }

  // Bind tasks stream to user session
  void bindUserTasks(String userId) {
    _isLoading = true;
    _tasksSubscription?.cancel();
    
    _tasksSubscription = _dbService.getTasksStream(userId).listen(
      (tasksList) {
        _tasks = tasksList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  void unbindTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _tasks = [];
    notifyListeners();
  }

  // Filtered & Sorted Tasks list
  List<TaskModel> get filteredTasks {
    List<TaskModel> list = List.from(_tasks);

    // Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
    }

    // Category
    if (_selectedCategoryId != null) {
      list = list.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    // Priority
    if (_priorityFilter != 'All') {
      list = list.where((t) => t.priority == _priorityFilter).toList();
    }

    // Status
    if (_statusFilter != 'All') {
      final isCompletedVal = _statusFilter == 'Completed';
      list = list.where((t) => t.isCompleted == isCompletedVal).toList();
    }

    // Sort
    list.sort((a, b) {
      if (_sortBy == 'dueDate') {
        return a.dueDate.compareTo(b.dueDate);
      } else if (_sortBy == 'priority') {
        const pMap = {'High': 3, 'Medium': 2, 'Low': 1};
        final pa = pMap[a.priority] ?? 0;
        final pb = pMap[b.priority] ?? 0;
        return pb.compareTo(pa); // Descending priority
      } else {
        return b.createdAt.compareTo(a.createdAt); // Descending creation date
      }
    });

    return list;
  }

  // Helpers for dashboard metrics
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get highPriorityCount => _tasks.where((t) => t.priority == 'High' && !t.isCompleted).length;
  
  double get completionRate {
    if (_tasks.isEmpty) return 0.0;
    return completedCount / totalCount;
  }

  // CRUD Actions

  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> createTask({
    required String userId,
    required String title,
    required String description,
    required String categoryId,
    required String priority,
    required DateTime dueDate,
    required List<SubtaskModel> subtasks,
    XFile? imageFile,
    Uint8List? webImageBytes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final taskId = _generateId();
    String? imageUrl;

    try {
      if (imageFile != null) {
        imageUrl = await _storageService.uploadTaskImage(
          taskId: taskId,
          userId: userId,
          imageFile: imageFile,
          webImageBytes: webImageBytes,
        );
      }

      final task = TaskModel(
        id: taskId,
        userId: userId,
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        dueDate: dueDate,
        isCompleted: false,
        imageUrl: imageUrl,
        subtasks: subtasks,
        createdAt: DateTime.now(),
      );

      await _dbService.saveTask(task);
    } catch (e) {
      debugPrint('Create Task Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _dbService.saveTask(task);
    } catch (e) {
      debugPrint('Update Task Error: $e');
    }
  }

  Future<void> uploadAndSetTaskImage({
    required TaskModel task,
    required XFile imageFile,
    required Uint8List? webImageBytes,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final imageUrl = await _storageService.uploadTaskImage(
        taskId: task.id,
        userId: task.userId,
        imageFile: imageFile,
        webImageBytes: webImageBytes,
      );
      final updatedTask = task.copyWith(imageUrl: imageUrl);
      await _dbService.saveTask(updatedTask);
    } catch (e) {
      debugPrint('Upload Image Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _dbService.deleteTask(taskId);
    } catch (e) {
      debugPrint('Delete Task Error: $e');
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      final task = _tasks[idx];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _dbService.saveTask(updatedTask);
    }
  }

  Future<void> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      final task = _tasks[idx];
      final updatedSubtasks = task.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(isCompleted: !s.isCompleted);
        }
        return s;
      }).toList();
      final updatedTask = task.copyWith(subtasks: updatedSubtasks);
      await _dbService.saveTask(updatedTask);
    }
  }

  Future<String> shareTask(TaskModel task, String ownerName) async {
    await _dbService.shareTask(task, ownerName);
    final baseUri = Uri.base;
    return '${baseUri.scheme}://${baseUri.authority}/#/shared?taskId=${task.id}';
  }

  Future<Map<String, dynamic>?> getSharedTask(String taskId) async {
    return await _dbService.getSharedTask(taskId);
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
