import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import 'database_helper.dart';
import 'sync_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _selectedCategoryId = 'all';

  List<Category> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;

  Future<void> initialize() async {
    await loadCategories();
    await loadTasks();
  }

  List<Task> get tasks {
    Iterable<Task> filtered = _tasks;
    
    // 1. Фильтрация по категории
    if (_selectedCategoryId != 'all') {
      filtered = filtered.where((t) => t.categoryId == _selectedCategoryId);
    }

    List<Task> sorted = filtered.toList();

    // 2. Умная сортировка
    sorted.sort((a, b) {
      // Правило 1: Сначала невыполненные, потом выполненные
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      if (!a.isCompleted) {
        // Правило 2: Закрепленные (pinned) в самом верху среди активных
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }

        // Правило 3: Просроченные дедлайны поднимаются выше в своей группе
        bool aOverdue = a.deadline != null && a.deadline!.isBefore(DateTime.now());
        bool bOverdue = b.deadline != null && b.deadline!.isBefore(DateTime.now());
        if (aOverdue != bOverdue) {
          return aOverdue ? -1 : 1;
        }

        // Правило 4: Приоритет (High -> Medium -> Low)
        final priorityMap = {'high': 0, 'medium': 1, 'low': 2};
        int aPrio = priorityMap[a.priority.toLowerCase()] ?? 1;
        int bPrio = priorityMap[b.priority.toLowerCase()] ?? 1;
        if (aPrio != bPrio) {
          return aPrio.compareTo(bPrio);
        }
      }

      // По умолчанию сортируем по времени обновления (свежие выше)
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return sorted;
  }

  void setCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _tasks = await _dbHelper.getMainTasks();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _dbHelper.getCategories();
    notifyListeners();
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Color getCategoryColor(String? categoryId) {
    final cat = getCategoryById(categoryId);
    if (cat != null) {
      try {
        return Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
      } catch (_) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  Future<void> addTaskDirect({
    required String title,
    required String priority,
    String? categoryId,
    DateTime? deadline,
  }) async {
    if (title.trim().isEmpty) return;
    
    final newTask = Task(
      title: title.trim(),
      priority: priority,
      categoryId: categoryId ?? 'system-default-uncategorized',
      deadline: deadline,
    );
    
    await _dbHelper.upsertTask(newTask);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    task.updatedAt = DateTime.now();
    await _dbHelper.upsertTask(task);
    await loadTasks();
  }

  Future<void> togglePin(Task task) async {
    final newStatus = !task.isPinned;
    await _dbHelper.togglePin(task.id, newStatus);
    await loadTasks();
  }

  Future<void> softDelete(Task task) async {
    await _dbHelper.softDeleteTask(task.id);
    await loadTasks();
  }

  Future<void> restore(Task task) async {
    await _dbHelper.restoreTask(task.id);
    await loadTasks();
  }

  Future<void> bulkClearCompleted() async {
    await _dbHelper.clearCompletedToDeleted();
    await loadTasks();
  }

  Future<void> addCategory(String name, String colorHex) async {
    final newCat = Category(name: name, color: colorHex);
    await _dbHelper.upsertCategory(newCat);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _dbHelper.deleteCategory(id);
    await loadCategories();
    await loadTasks(); // Задачи могли сменить категорию
  }

  Future<void> syncWithServer() async {
    await SyncService().syncTasks();
    await loadCategories();
    await loadTasks();
  }

  Future<List<Task>> getSubtasks(String parentId) async {
    return await _dbHelper.getSubtasks(parentId);
  }

  double calculateProgress(List<Task> subtasks) {
    if (subtasks.isEmpty) return 0.0;
    final completed = subtasks.where((t) => t.isCompleted).length;
    return completed / subtasks.length;
  }

  Future<void> addSubtask(String parentId, String title) async {
    if (title.trim().isEmpty) return;
    final subtask = Task(title: title, parentId: parentId);
    await _dbHelper.upsertTask(subtask);
    await loadTasks();
  }

  Future<void> attachFile(String taskId) async {
    print("Attaching file to task: $taskId");
    notifyListeners();
  }
}
