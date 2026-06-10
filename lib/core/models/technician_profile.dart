class TechnicianProfile {
  final String id;
  final String dni;
  final int districtId;
  final String? bio;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final double avgRating;
  final int totalJobsCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianProfile({
    required this.id,
    required this.dni,
    required this.districtId,
    this.bio,
    required this.verificationStatus,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    required this.avgRating,
    required this.totalJobsCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      id: json['id'] as String,
      dni: json['dni'] as String,
      districtId: json['district_id'] as int,
      bio: json['bio'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      verifiedBy: json['verified_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      avgRating: double.parse((json['avg_rating'] ?? 0.0).toString()),
      totalJobsCompleted: json['total_jobs_completed'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dni': dni,
      'district_id': districtId,
      'bio': bio,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'rejection_reason': rejectionReason,
      'avg_rating': avgRating,
      'total_jobs_completed': totalJobsCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
