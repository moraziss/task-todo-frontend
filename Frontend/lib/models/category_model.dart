import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String color; // Hex-код, например #FFB6C1
  final bool isDefault;

  Category({
    String? id,
    required this.name,
    required this.color,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      isDefault: (map['is_default'] == 1 || map['is_default'] == true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
