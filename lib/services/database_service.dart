import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tide/models/task_model.dart';
import 'auth_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _loadSeedTasks();
  }

  bool get isFirebaseAvailable => AuthService().isFirebaseAvailable;

  // Mock In-Memory Database
  final List<TaskModel> _mockTasks = [];
  final _tasksController = StreamController<List<TaskModel>>.broadcast();

  void _loadSeedTasks() {
    final now = DateTime.now();
    _mockTasks.addAll([
      TaskModel(
        id: 'seed_task_1',
        userId: 'mock_user_123',
        title: 'Design Tide Brand Identity',
        description: 'Create brand guidelines, typography scale, cream-themed palettes, and logo options.',
        categoryId: 'work',
        priority: 'High',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 10)),
        subtasks: [
          SubtaskModel(id: 's1', title: 'Brainstorm logo concepts', isCompleted: true),
          SubtaskModel(id: 's2', title: 'Define HSL color variables', isCompleted: false),
          SubtaskModel(id: 's3', title: 'Design dashboard prototype', isCompleted: false),
        ],
      ),
      TaskModel(
        id: 'seed_task_2',
        userId: 'mock_user_123',
        title: 'Weekly Grocery Shopping',
        description: 'Stock up on clean eating items, healthy greens, and ambient candles.',
        categoryId: 'shopping',
        priority: 'Medium',
        dueDate: now.add(const Duration(days: 3)),
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TaskModel(
        id: 'seed_task_3',
        userId: 'mock_user_123',
        title: 'Meditation & Breathwork',
        description: '20 minutes of daily mindfulness for relaxation and stress relief.',
        categoryId: 'health',
        priority: 'Low',
        dueDate: now,
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
    _notifyMockListeners();
  }

  void _notifyMockListeners() {
    if (!_tasksController.isClosed) {
      _tasksController.add(List.unmodifiable(_mockTasks));
    }
  }

  // --- Task CRUD Operations ---

  // Stream tasks for a user
  Stream<List<TaskModel>> getTasksStream(String userId) {
    if (isFirebaseAvailable) {
      return FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();
      });
    } else {
      // Return a stream that emits when mock tasks change
      // Seed initial data first
      Timer.run(() => _notifyMockListeners());
      return _tasksController.stream.map((tasks) {
        return tasks.where((t) => t.userId == userId || userId == 'mock_google_user' || t.userId == 'mock_google_user').toList();
      });
    }
  }

  // Add or Update a task
  Future<void> saveTask(TaskModel task) async {
    if (isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      final idx = _mockTasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) {
        _mockTasks[idx] = task;
      } else {
        _mockTasks.add(task);
      }
      _notifyMockListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    if (isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .delete();
    } else {
      await Future.delayed(const Duration(milliseconds: 150));
      _mockTasks.removeWhere((t) => t.id == taskId);
      _notifyMockListeners();
    }
  }

  // --- Share Operations ---
  static final Map<String, Map<String, dynamic>> _mockShares = {};

  Future<void> shareTask(TaskModel task, String ownerName) async {
    if (isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.id)
          .collection('shares')
          .doc('public')
          .set({
        'task': task.toMap(),
        'ownerName': ownerName,
        'sharedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockShares[task.id] = {
        'task': task.toMap(),
        'ownerName': ownerName,
        'sharedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>?> getSharedTask(String taskId) async {
    if (isFirebaseAvailable) {
      final doc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('shares')
          .doc('public')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'task': TaskModel.fromMap(Map<String, dynamic>.from(data['task'])),
          'ownerName': data['ownerName'],
        };
      }
      return null;
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_mockShares.containsKey(taskId)) {
        final data = _mockShares[taskId]!;
        return {
          'task': TaskModel.fromMap(Map<String, dynamic>.from(data['task'])),
          'ownerName': data['ownerName'],
        };
      }
      return null;
    }
  }

  void dispose() {
    _tasksController.close();
  }
}
