import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String defaultCategoryId = '00000000-0000-0000-0000-000000000000';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        title TEXT NOT NULL,
        priority TEXT DEFAULT 'medium',
        category TEXT, 
        category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
        is_completed INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        deadline TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Default System Category (matching PostgreSQL script)
    await db.insert('categories', {
      'id': defaultCategoryId,
      'name': 'Общие',
      'color': '#9E9E9E',
      'is_default': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // CATEGORIES
  Future<void> upsertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.update(
      'tasks',
      {'category_id': defaultCategoryId},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    await db.delete('categories', where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }

  // TASKS
  Future<void> upsertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getMainTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'parent_id IS NULL AND is_deleted = 0',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getSubtasks(String parentId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'parent_id = ? AND is_deleted = 0',
      whereArgs: [parentId],
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    return (await db.query('tasks')).map((e) => Task.fromMap(e)).toList();
  }

  Future<void> togglePin(String id, bool value) async {
    final db = await database;
    await db.update('tasks', {
      'is_pinned': value ? 1 : 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteTask(String id) async {
    final db = await database;
    await db.update('tasks', {
      'is_deleted': 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreTask(String id) async {
    final db = await database;
    await db.update('tasks', {
      'is_deleted': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCompletedToDeleted() async {
    final db = await database;
    await db.update('tasks', {
      'is_deleted': 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'is_completed = 1 AND is_deleted = 0');
  }
}
