import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Formatea el número de pedido legible: 1 → "0001", 450 → "0450", 10000 → "10000".
String formatOrderNumber(int? n) =>
    n == null ? '—' : n.toString().padLeft(4, '0');

/// Resultado de crear un pedido.
class CreateRequestResult {
  const CreateRequestResult({
    required this.success,
    this.requestId,
    this.orderNumber,
    this.message,
  });

  final bool success;
  final String? requestId;
  final int? orderNumber;
  final String? message;
}

/// Resultado simple de una acción sobre un pedido (cancelar/editar).
class ActionResult {
  const ActionResult({required this.success, this.message});

  final bool success;
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
    this.orderNumber,
    this.imageUrls = const [],
    this.applicationsCount = 0,
    this.createdAt,
  });

  final String id;
  final int? orderNumber;
  final String title;
  final String description;
  final String status;
  final String categoryName;
  final String categoryEmoji;
  final String districtName;
  final List<String> imageUrls;
  final int applicationsCount;
  final DateTime? createdAt;

  /// Primera foto del pedido (miniatura), o null si no hay.
  String? get thumbnailUrl => imageUrls.isEmpty ? null : imageUrls.first;

  factory MyRequest.fromJson(Map<String, dynamic> j) => MyRequest(
    id: j['id'] as String,
    orderNumber: (j['order_number'] as num?)?.toInt(),
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'pending_review',
    categoryName: j['category_name'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '',
    districtName: j['district_name'] as String? ?? '',
    imageUrls:
        (j['image_urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        const [],
    applicationsCount: (j['applications_count'] as num?)?.toInt() ?? 0,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Ficha completa de un pedido propio (para verlo y editarlo).
class RequestDetail {
  const RequestDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
    required this.districtId,
    required this.districtName,
    this.orderNumber,
    this.address,
    this.imageUrls = const [],
    this.needsInvoice = false,
    this.preferredDate,
    this.rejectionReason,
    this.applicationsCount = 0,
    this.assignedTechnicianId,
    this.createdAt,
  });

  final String id;
  final int? orderNumber;
  final String title;
  final String description;
  final String status;
  final int categoryId;
  final String categoryName;
  final String categoryEmoji;
  final int districtId;
  final String districtName;
  final String? address;
  final List<String> imageUrls;
  final bool needsInvoice;
  final DateTime? preferredDate;
  final String? rejectionReason;
  final int applicationsCount;
  final String? assignedTechnicianId;
  final DateTime? createdAt;

  /// Se puede editar/cancelar solo mientras no haya técnico asignado.
  bool get canManage => status == 'pending_review' || status == 'open';

  factory RequestDetail.fromJson(Map<String, dynamic> j) => RequestDetail(
    id: j['id'] as String,
    orderNumber: (j['order_number'] as num?)?.toInt(),
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    status: j['status'] as String? ?? 'pending_review',
    categoryId: (j['category_id'] as num?)?.toInt() ?? 0,
    categoryName: j['category_name'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '',
    districtId: (j['district_id'] as num?)?.toInt() ?? 0,
    districtName: j['district_name'] as String? ?? '',
    address: j['address'] as String?,
    imageUrls:
        (j['image_urls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    needsInvoice: j['needs_invoice'] as bool? ?? false,
    preferredDate: j['preferred_date'] != null
        ? DateTime.tryParse(j['preferred_date'] as String)
        : null,
    rejectionReason: j['rejection_reason'] as String?,
    applicationsCount: (j['applications_count'] as num?)?.toInt() ?? 0,
    assignedTechnicianId: j['assigned_technician_id'] as String?,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Pedidos del cliente: crear, listar, ver postulantes, aceptar.
/// Habla con InsForge vía RPCs (auth.uid() resuelve el cliente).
class RequestService {
  /// Se incrementa cada vez que el usuario crea un pedido. El home escucha esto
  /// para recargar su lista de pedidos al volver (sin necesidad de recargar a
  /// mano), sin importar desde dónde se haya creado.
  static final ValueNotifier<int> ordersChanged = ValueNotifier<int>(0);

  final InsForgeClient _client = InsForgeClient();

  static const _photosBucket = 'request-photos';

  /// Sube las fotos del pedido al bucket público y devuelve sus URLs.
  /// Las que fallen se omiten (no bloquean la publicación).
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (filePaths.isEmpty) return const [];
    final userId = await _client.getCurrentUserId();
    if (userId == null || userId.isEmpty) return const [];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];
    for (var i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      final ext = _safeExtension(path);
      final objectKey = 'clients/$userId/requests/$timestamp-$i.$ext';
      final result = await _client.uploadFile(
        bucket: _photosBucket,
        filePath: path,
        objectKey: objectKey,
      );
      if (result != null && result['url'] != null) {
        urls.add(result['url']!);
      }
    }
    return urls;
  }

  String _safeExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }

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
    List<String>? imageUrls,
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
          'p_image_urls': imageUrls,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        final ok = r['success'] == true;
        // Avisa al home para que recargue su lista de pedidos.
        if (ok) ordersChanged.value++;
        return CreateRequestResult(
          success: ok,
          requestId: r['request_id'] as String?,
          orderNumber: (r['order_number'] as num?)?.toInt(),
          message: r['message'] as String?,
        );
      }
      debugPrint(
        'createRequest error: ${response.statusCode} ${response.body}',
      );
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

  /// Ficha completa de un pedido propio. Devuelve null si no existe o no es tuyo.
  Future<RequestDetail?> getRequestDetail(String requestId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_request_detail',
        body: {'p_request_id': requestId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return RequestDetail.fromJson(decoded);
        }
        return null; // body 'null' → no encontrado / ajeno
      }
      return null;
    } catch (e) {
      debugPrint('Exception getRequestDetail: $e');
      return null;
    }
  }

  /// Cancela un pedido propio (solo antes de asignar técnico).
  Future<ActionResult> cancelRequest(String requestId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/cancel_service_request',
        body: {'p_request_id': requestId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return ActionResult(
          success: r['success'] == true,
          message: r['message'] as String?,
        );
      }
      return const ActionResult(
        success: false,
        message: 'No se pudo cancelar el pedido.',
      );
    } catch (e) {
      debugPrint('Exception cancelRequest: $e');
      return const ActionResult(success: false, message: 'Error de conexión.');
    }
  }

  /// Edita los campos simples de un pedido propio (solo antes de asignar).
  /// Categoría, distrito y título no se modifican aquí.
  Future<ActionResult> updateRequest({
    required String requestId,
    required String description,
    DateTime? preferredDate,
    bool needsInvoice = false,
    String? address,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/update_service_request',
        body: {
          'p_request_id': requestId,
          'p_description': description,
          'p_preferred_date': preferredDate?.toUtc().toIso8601String(),
          'p_needs_invoice': needsInvoice,
          'p_address': address,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return ActionResult(
          success: r['success'] == true,
          message: r['message'] as String?,
        );
      }
      return const ActionResult(
        success: false,
        message: 'No se pudo actualizar el pedido.',
      );
    } catch (e) {
      debugPrint('Exception updateRequest: $e');
      return const ActionResult(success: false, message: 'Error de conexión.');
    }
  }
}
