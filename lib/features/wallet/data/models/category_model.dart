enum CategoryKind { income, expense }

class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    this.icon,
    this.color,
    this.sortOrder = 0,
  });

  final String id;
  final String? userId; // null = system preset
  final String name;
  final CategoryKind kind;
  final String? icon; // Material icon identifier (resolved in presentation)
  final String? color; // hex string, e.g. '#FF7043'
  final int sortOrder;

  bool get isSystem => userId == null;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      kind: json['kind'] == 'income' ? CategoryKind.income : CategoryKind.expense,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toInsert(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'kind': kind.name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    };
  }
}
