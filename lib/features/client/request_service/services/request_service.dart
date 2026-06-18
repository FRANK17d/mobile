import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Resultado de crear un pedido.
class CreateRequestResult {
  const CreateRequestResult({
    required this.success,
    this.requestId,
    this.message,
  });

  final bool success;
  final String? requestId;
  final String? message;
}

/// Un postulante a un pedido (lo que ve el cliente).
class Applicant {
  const Applicant({
    required this.applicationId,
    required this.technicianId,
    required this.firstName,
    this.lastName,
    this.avatarUrl,
    this.message,
    this.proposedPrice,
    this.avgRating,
    this.totalJobs,
    required this.status,
  });

  final String applicationId;
  final String technicianId;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? message;
  final num? proposedPrice;
  final num? avgRating;
  final int? totalJobs;
  final String status;

  factory Applicant.fromJson(Map<String, dynamic> j) => Applicant(
    applicationId: j['application_id'] as String,
    technicianId: j['technician_id'] as String,
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    message: j['message'] as String?,
    proposedPrice: j['proposed_price'] as num?,
    avgRating: j['avg_rating'] as num?,
    totalJobs: j['total_jobs_completed'] as int?,
    status: j['status'] as String? ?? 'pending',
  );
}

/// Un pedido del propio cliente (con estado y conteo de postulaciones).
class MyRequest {
  const MyRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryName,
    required this.categoryEmoji,
    required this.districtName,
    this.applicationsCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String categoryName;
  final String categoryEmoji;
  final String districtName;
  final int applicationsCount;
  final DateTime? createdAt;

  factory MyRequest.fromJson(Map<String, dynamic> j) => MyRequest(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'pending_review',
    categoryName: j['category_name'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '',
    districtName: j['district_name'] as String? ?? '',
    applicationsCount: (j['applications_count'] as num?)?.toInt() ?? 0,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Pedidos del cliente: crear, listar, ver postulantes, aceptar.
/// Habla con InsForge vía RPCs (auth.uid() resuelve el cliente).
class RequestService {
  final InsForgeClient _client = InsForgeClient();

  /// Lista los pedidos del cliente actual.
  Future<List<MyRequest>> getMyRequests() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_requests',
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => MyRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getMyRequests: $e');
      return const [];
    }
  }

  /// Crea un pedido (queda en revisión). Devuelve el id si tuvo éxito.
  Future<CreateRequestResult> createRequest({
    required int categoryId,
    required int districtId,
    required String title,
    required String description,
    DateTime? preferredDate,
    bool needsInvoice = false,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/create_service_request',
        body: {
          'p_category_id': categoryId,
          'p_district_id': districtId,
          'p_title': title,
          'p_description': description,
          'p_preferred_date': preferredDate?.toUtc().toIso8601String(),
          'p_needs_invoice': needsInvoice,
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_address': address,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return CreateRequestResult(
          success: r['success'] == true,
          requestId: r['request_id'] as String?,
          message: r['message'] as String?,
        );
      }
      debugPrint('createRequest error: ${response.statusCode} ${response.body}');
      return const CreateRequestResult(
        success: false,
        message: 'No se pudo crear el pedido.',
      );
    } catch (e) {
      debugPrint('Exception createRequest: $e');
      return const CreateRequestResult(
        success: false,
        message: 'Error de conexión.',
      );
    }
  }

  /// Postulantes de un pedido propio.
  Future<List<Applicant>> getRequestApplications(String requestId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_request_applications',
        body: {'p_request_id': requestId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Applicant.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getRequestApplications: $e');
      return const [];
    }
  }

  /// Acepta una postulación (asigna el técnico). Devuelve true si se asignó.
  Future<bool> acceptApplication(String applicationId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/accept_application',
        body: {'p_application_id': applicationId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return r['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Exception acceptApplication: $e');
      return false;
    }
  }
}
