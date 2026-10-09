import 'package:flutter_test/flutter_test.dart';
import 'package:task_todo/models/category_model.dart';

void main() {
  group('Category', () {
    test('toMap/fromMap round-trip preserves every field', () {
      final original = Category(
        id: 'cat-1',
        name: 'Study',
        color: '#FFB6C1',
        isDefault: true,
      );

      final restored = Category.fromMap(original.toMap());

      expect(restored.id, 'cat-1');
      expect(restored.name, 'Study');
      expect(restored.color, '#FFB6C1');
      expect(restored.isDefault, isTrue);
    });

    test('toMap stores isDefault as 0/1', () {
      expect(Category(name: 'a', color: '#000000').toMap()['is_default'], 0);
      expect(
        Category(name: 'a', color: '#000000', isDefault: true).toMap()['is_default'],
        1,
      );
    });

    test('fromMap accepts both integer and boolean is_default', () {
      Category build(dynamic flag) => Category.fromMap(
            {'id': 'c', 'name': 'n', 'color': '#000000', 'is_default': flag},
          );

      expect(build(1).isDefault, isTrue);
      expect(build(true).isDefault, isTrue);
      expect(build(0).isDefault, isFalse);
      expect(build(false).isDefault, isFalse);
    });

    test('generates an id when none is given', () {
      expect(Category(name: 'a', color: '#000000').id, isNotEmpty);
    });
  });
}
