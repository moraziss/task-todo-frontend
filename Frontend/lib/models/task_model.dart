import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String? parentId; // null для главных задач
  final String title;
  final String priority; // low, medium, high
  final String category; // legacy текстовая категория (для совместимости)
  final String? categoryId; // нормализованная категория
  bool isCompleted;
  bool isPinned;
  bool isDeleted;
  final DateTime? deadline; // может быть null
  final DateTime createdAt;
  DateTime updatedAt;

  Task({
    String? id,
    this.parentId,
    required this.title,
    this.priority = 'medium',
    this.category = '',
    this.categoryId,
    this.isCompleted = false,
    this.isPinned = false,
    this.isDeleted = false,
    this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Превращаем из Map (который отдает SQLite/JSON) в объект Dart (устойчиво к отсутствующим полям)
  factory Task.fromMap(Map<String, dynamic> map) {
    String? parseString(dynamic v) => v?.toString();
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null || (v is String && v.isEmpty)) return null;
      return DateTime.parse(v as String);
    }

    return Task(
      id: map['id'] as String,
      parentId: parseString(map['parent_id']),
      title: map['title'] as String,
      priority: (map['priority'] as String?) ?? 'medium',
      category: (map['category'] as String?) ?? '',
      categoryId: parseString(map['category_id']),
      isCompleted: parseBool(map['is_completed']),
      isPinned: parseBool(map['is_pinned']),
      isDeleted: parseBool(map['is_deleted']),
      deadline: parseDate(map['deadline']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Превращаем объект Dart в Map для записи в SQLite или отправки в JSON на бэк
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'title': title,
      'priority': priority,
      'category': category,
      'category_id': categoryId,
      'is_completed': isCompleted ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}