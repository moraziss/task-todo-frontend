import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/category_model.dart';
import 'database_helper.dart';

class SyncService {
  static const String baseUrl = 'http://localhost:8080';

  Future<void> syncTasks() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Собираем локальные данные
      List<Task> localTasks = await dbHelper.getAllTasks();
      List<Category> localCategories = await dbHelper.getCategories();

      final tasksJson = localTasks.map((t) {
        final map = t.toMap();
        map['is_completed'] = t.isCompleted;
        map['is_pinned'] = t.isPinned;
        map['is_deleted'] = t.isDeleted;
        return map;
      }).toList();

      final categoriesJson = localCategories.map((c) => c.toMap()).toList();

      // 2. Отправляем на сервер

      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tasks': tasksJson,
          'categories': categoriesJson,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> serverData = jsonDecode(response.body);
        
        // Сервер теперь должен возвращать объект с ключами tasks и categories
        if (serverData.containsKey('categories')) {
          for (var catMap in serverData['categories']) {
            await dbHelper.upsertCategory(Category.fromMap(catMap));
          }
        }

        if (serverData.containsKey('tasks')) {
          for (var taskMap in serverData['tasks']) {
            await dbHelper.upsertTask(Task.fromMap(taskMap));
          }
        }
        
        print("Синхронизация завершена успешно");
      } else {
        print("Ошибка сервера: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка синхронизации: $e");
    }
  }
}
