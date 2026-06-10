class District {
  final int id;
  final String name;
  final String province;
  final String department;
  final bool isActive;
  final DateTime createdAt;

  const District({
    required this.id,
    required this.name,
    required this.province,
    required this.department,
    required this.isActive,
    required this.createdAt,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      province: json['province'] as String? ?? 'Trujillo',
      department: json['department'] as String? ?? 'La Libertad',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'department': department,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
