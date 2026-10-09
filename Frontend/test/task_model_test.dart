import 'package:flutter_test/flutter_test.dart';
import 'package:task_todo/models/task_model.dart';

void main() {
  group('Task', () {
    test('toMap/fromMap round-trip preserves every field', () {
      final original = Task(
        id: 'task-1',
        parentId: 'parent-1',
        title: 'Write tests',
        priority: 'high',
        category: 'legacy',
        categoryId: 'cat-1',
        isCompleted: true,
        isPinned: true,
        isDeleted: false,
        deadline: DateTime.utc(2026, 10, 15, 9, 30),
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 2),
      );

      final restored = Task.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.parentId, original.parentId);
      expect(restored.title, original.title);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
      expect(restored.categoryId, original.categoryId);
      expect(restored.isCompleted, isTrue);
      expect(restored.isPinned, isTrue);
      expect(restored.isDeleted, isFalse);
      expect(restored.deadline, original.deadline);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('toMap stores booleans as 0/1 for SQLite', () {
      final map = Task(title: 'x', isCompleted: true).toMap();

      expect(map['is_completed'], 1);
      expect(map['is_pinned'], 0);
      expect(map['is_deleted'], 0);
    });

    test('fromMap accepts the boolean encodings SQLite and the server send', () {
      Task build(dynamic flag) => Task.fromMap({
            'id': 'a',
            'title': 't',
            'is_completed': flag,
            'created_at': '2026-10-01T00:00:00.000Z',
            'updated_at': '2026-10-01T00:00:00.000Z',
          });

      expect(build(1).isCompleted, isTrue);
      expect(build(0).isCompleted, isFalse);
      expect(build(true).isCompleted, isTrue);
      expect(build('1').isCompleted, isTrue);
      expect(build('TRUE').isCompleted, isTrue);
      expect(build('false').isCompleted, isFalse);
      expect(build(null).isCompleted, isFalse);
    });

    test('fromMap falls back to defaults when optional fields are missing', () {
      final task = Task.fromMap({
        'id': 'a',
        'title': 't',
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-01T00:00:00.000Z',
      });

      expect(task.priority, 'medium');
      expect(task.category, '');
      expect(task.parentId, isNull);
      expect(task.categoryId, isNull);
      expect(task.deadline, isNull);
      expect(task.isPinned, isFalse);
    });

    test('an empty deadline string is treated as no deadline', () {
      final task = Task.fromMap({
        'id': 'a',
        'title': 't',
        'deadline': '',
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-01T00:00:00.000Z',
      });

      expect(task.deadline, isNull);
    });

    test('new tasks get unique ids', () {
      expect(Task(title: 'a').id, isNot(Task(title: 'a').id));
    });
  });
}
