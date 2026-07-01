import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Una reseña pública de un técnico.
class TechnicianReview {
  const TechnicianReview({
    required this.id,
    required this.rating,
    this.comment,
    this.clientFirstName,
    this.clientAvatarUrl,
    this.requestTitle,
    this.categoryName,
    this.createdAt,
    this.requestId,
    this.requestDescription,
    this.requestImageUrls = const <String>[],
    this.requestOrderNumber,
    this.requestCompletedAt,
    this.categoryEmoji,
    this.districtName,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? clientFirstName;
  final String? clientAvatarUrl;
  final String? requestTitle;
  final String? categoryName;
  final DateTime? createdAt;

  // Campos añadidos por migración 0040
  final String? requestId;
  final String? requestDescription;
  final List<String> requestImageUrls;
  final int? requestOrderNumber;
  final DateTime? requestCompletedAt;
  final String? categoryEmoji;
  final String? districtName;

  factory TechnicianReview.fromJson(Map<String, dynamic> j) {
    // image_urls puede venir como List<String> o null
    final rawImages = j['request_image_urls'];
    final List<String> images;
    if (rawImages is List) {
      images = rawImages.whereType<String>().toList(growable: false);
    } else {
      images = const <String>[];
    }

    return TechnicianReview(
      id: j['id'] as String,
      rating: (j['rating'] as num).toInt(),
      comment: j['comment'] as String?,
      clientFirstName: j['client_first_name'] as String?,
      clientAvatarUrl: j['client_avatar_url'] as String?,
      requestTitle: j['request_title'] as String?,
      categoryName: j['category_name'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      requestId: j['request_id'] as String?,
      requestDescription: j['request_description'] as String?,
      requestImageUrls: images,
      requestOrderNumber: (j['request_order_number'] as num?)?.toInt(),
      requestCompletedAt: j['request_completed_at'] != null
          ? DateTime.tryParse(j['request_completed_at'] as String)
          : null,
      categoryEmoji: j['category_emoji'] as String?,
      districtName: j['district_name'] as String?,
    );
  }
}

/// Mi reseña existente para un pedido (si ya fue calificado).
class MyReview {
  const MyReview({required this.id, required this.rating, this.comment});

  final String id;
  final int rating;
  final String? comment;

  factory MyReview.fromJson(Map<String, dynamic> j) => MyReview(
    id: j['id'] as String,
    rating: (j['rating'] as num).toInt(),
    comment: j['comment'] as String?,
  );
}

/// Servicio para enviar y consultar reseñas.
class ReviewService {
  final InsForgeClient _client = InsForgeClient();

  /// Envía (o actualiza) una reseña para un pedido.
  Future<({bool success, String? message})> submitReview({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/submit_review',
        body: {
          'p_request_id': requestId,
          'p_rating': rating,
          'p_comment': comment,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          success: r['success'] == true,
          message: r['message'] as String?,
        );
      }
      return (success: false, message: 'No se pudo enviar la reseña.');
    } catch (e) {
      debugPrint('Exception submitReview: $e');
      return (success: false, message: 'Error de conexión.');
    }
  }

  /// Reseñas públicas de un técnico.
  Future<List<TechnicianReview>> getTechnicianReviews(
    String technicianId,
  ) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_technician_reviews',
        body: {'p_technician_id': technicianId},
        requireAuth: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => TechnicianReview.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getTechnicianReviews: $e');
      return const [];
    }
  }

  /// Obtiene la reseña existente del cliente para un pedido (null si no existe).
  Future<MyReview?> getMyReviewForRequest(String requestId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_review_for_request',
        body: {'p_request_id': requestId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return MyReview.fromJson(decoded);
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Exception getMyReviewForRequest: $e');
      return null;
    }
  }
}
