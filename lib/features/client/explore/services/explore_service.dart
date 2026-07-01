import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Un técnico que ofrece una categoría (tarjeta "Algunos que brindan...").
class CategoryProvider {
  const CategoryProvider({
    required this.id,
    required this.firstName,
    this.lastName,
    this.avatarUrl,
    this.districtName,
    this.avgRating,
    this.totalJobs,
    this.bio,
    this.verificationStatus,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? districtName;
  final num? avgRating;
  final int? totalJobs;
  final String? bio;
  final String? verificationStatus;

  String get fullName =>
      [firstName, lastName ?? ''].where((s) => s.trim().isNotEmpty).join(' ');

  bool get isVerified => verificationStatus == 'verified';

  Map<String, dynamic> toPublicProfileData({
    String? serviceName,
    String? serviceEmoji,
    String? serviceDescription,
  }) {
    final services = serviceName == null || serviceName.trim().isEmpty
        ? null
        : [
            {
              'name': serviceName,
              'emoji': serviceEmoji,
              'description': serviceDescription,
            },
          ];
    final technician = <String, dynamic>{
      'id': id,
      'bio': bio,
      'district_name': districtName,
      'avg_rating': avgRating,
      'total_jobs_completed': totalJobs,
    };

    final profile = <String, dynamic>{
      'id': id,
      'technician_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'district_name': districtName,
      'viewer_context': 'client',
      'technician': technician,
    };

    if (verificationStatus != null) {
      profile['verification_status'] = verificationStatus;
      technician['verification_status'] = verificationStatus;
    }
    if (services != null) {
      profile['services'] = services;
      technician['services'] = services;
    }

    return profile;
  }

  factory CategoryProvider.fromJson(Map<String, dynamic> j) => CategoryProvider(
    id: j['id'] as String,
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    districtName: j['district_name'] as String?,
    avgRating: j['avg_rating'] as num?,
    totalJobs: (j['total_jobs_completed'] as num?)?.toInt(),
    bio: j['bio'] as String?,
    // Estos RPCs públicos solo devuelven técnicos verificados; si el backend
    // empieza a enviar el estado explícito, ese valor tiene prioridad.
    verificationStatus: _readVerificationStatus(j) ?? 'verified',
  );
}

String? _readVerificationStatus(Map<String, dynamic> j) {
  final status = (j['verification_status'] ?? j['verificationStatus'])
      ?.toString()
      .trim();
  if (status != null && status.isNotEmpty && status != 'null') return status;
  final isVerified = j['is_verified'] ?? j['isVerified'];
  if (isVerified == true) return 'verified';
  return null;
}

/// Un pedido reciente de cliente en una categoría (prueba social).
class CategoryRequest {
  const CategoryRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.districtName,
    this.clientFirstName,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String? districtName;
  final String? clientFirstName;
  final DateTime? createdAt;

  factory CategoryRequest.fromJson(Map<String, dynamic> j) => CategoryRequest(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'open',
    districtName: j['district_name'] as String?,
    clientFirstName: j['client_first_name'] as String?,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Un pedido público (vista "Explorar pedidos de otros clientes").
class PublicRequest {
  const PublicRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryName,
    required this.categoryEmoji,
    this.districtName,
    this.clientFirstName,
    this.applicationsCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String categoryName;
  final String categoryEmoji;
  final String? districtName;
  final String? clientFirstName;
  final int applicationsCount;
  final DateTime? createdAt;

  /// Código corto para mostrar como "#XXXX" (los pedidos usan uuid).
  String get shortCode => id.replaceAll('-', '').substring(0, 4).toUpperCase();

  factory PublicRequest.fromJson(Map<String, dynamic> j) => PublicRequest(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'open',
    categoryName: j['category_name'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '',
    districtName: j['district_name'] as String?,
    clientFirstName: j['client_first_name'] as String?,
    applicationsCount: (j['applications_count'] as num?)?.toInt() ?? 0,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Datos de la vista de detalle de categoría (prestadores + pedidos) y de la
/// vista pública de pedidos. Los RPCs son públicos (anon + authenticated), así
/// que no requieren sesión.
class ExploreService {
  final InsForgeClient _client = InsForgeClient();

  Future<List<CategoryProvider>> getCategoryProviders(int categoryId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_category_providers',
        body: {'p_category_id': categoryId},
        requireAuth: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => CategoryProvider.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getCategoryProviders: $e');
      return const [];
    }
  }

  Future<List<CategoryRequest>> getCategoryRecentRequests(
    int categoryId,
  ) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_category_recent_requests',
        body: {'p_category_id': categoryId},
        requireAuth: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => CategoryRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getCategoryRecentRequests: $e');
      return const [];
    }
  }

  Future<List<PublicRequest>> getPublicRequests() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_public_requests',
        requireAuth: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => PublicRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getPublicRequests: $e');
      return const [];
    }
  }

  Future<List<CategoryProvider>> getAllProviders() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_all_providers',
        requireAuth: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => CategoryProvider.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getAllProviders: $e');
      return const [];
    }
  }
}
