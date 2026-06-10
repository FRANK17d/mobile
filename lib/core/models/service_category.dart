class ServiceCategory {
  final int id;
  final String name;
  final String? emoji;
  final String slug;
  final bool isActive;
  final DateTime createdAt;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.emoji,
    required this.slug,
    required this.isActive,
    required this.createdAt,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'slug': slug,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
