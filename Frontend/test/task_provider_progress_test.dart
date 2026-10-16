import 'package:flutter_test/flutter_test.dart';
import 'package:task_todo/models/task_model.dart';
import 'package:task_todo/services/task_provider.dart';

void main() {
  group('TaskProvider.calculateProgress', () {
    // The provider only touches the database when load/save methods are
    // called, so it can be constructed without any storage in a unit test.
    final provider = TaskProvider();

    Task subtask({required bool done}) =>
        Task(title: 'step', parentId: 'parent', isCompleted: done);

    test('is 0 when there are no subtasks', () {
      expect(provider.calculateProgress([]), 0.0);
    });

    test('is 0 when nothing is completed', () {
      expect(
        provider.calculateProgress([subtask(done: false), subtask(done: false)]),
        0.0,
      );
    });

    test('is the fraction of completed subtasks', () {
      final progress = provider.calculateProgress([
        subtask(done: true),
        subtask(done: false),
        subtask(done: true),
        subtask(done: false),
      ]);

      expect(progress, 0.5);
    });

    test('is 1 when every subtask is completed', () {
      expect(
        provider.calculateProgress([subtask(done: true), subtask(done: true)]),
        1.0,
      );
    });
  });
}
