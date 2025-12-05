class Notebook {
  final String id;
  final String name;
  final int color;
  final String icon;
  final DateTime createdAt;

  Notebook({
    required this.id,
    required this.name,
    this.color = 0xFF2DBD6C,
    this.icon = 'folder',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as int,
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Notebook copyWith({
    String? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Notebook(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
