class UserProfile {
  final String id;
  final String role; // 'client' or 'technician'
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final int? districtId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.districtId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return email?.split('@').first ?? 'Usuario';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'client',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      districtId: json['district_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'district_id': districtId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? role,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? avatarUrl,
    int? districtId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      districtId: districtId ?? this.districtId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
