import 'package:cloud_firestore/cloud_firestore.dart';

class SubtaskModel {
  final String id;
  final String title;
  final bool isCompleted;

  SubtaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubtaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String categoryId;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dueDate;
  final bool isCompleted;
  final String? imageUrl;
  final List<SubtaskModel> subtasks;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
    this.imageUrl,
    this.subtasks = const [],
    required this.createdAt,
  });

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? categoryId,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    String? imageUrl,
    List<SubtaskModel>? subtasks,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'imageUrl': imageUrl,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return TaskModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? 'work',
      priority: map['priority'] ?? 'Medium',
      dueDate: parseDateTime(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
      imageUrl: map['imageUrl'],
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => SubtaskModel.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      createdAt: parseDateTime(map['createdAt']),
    );
  }
}
