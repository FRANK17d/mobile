import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Un pedido disponible para postular (lo que ve el técnico en su feed).
class AvailableRequest {
  const AvailableRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
    required this.districtId,
    required this.districtName,
    this.budgetMin,
    this.budgetMax,
    this.preferredDate,
    this.needsInvoice = false,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int categoryId;
  final String categoryName;
  final String categoryEmoji;
  final int districtId;
  final String districtName;
  final num? budgetMin;
  final num? budgetMax;
  final DateTime? preferredDate;
  final bool needsInvoice;
  final double? latitude;
  final double? longitude;
  final num? distanceKm;
  final DateTime? createdAt;

  factory AvailableRequest.fromJson(Map<String, dynamic> j) => AvailableRequest(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    categoryId: j['category_id'] as int,
    categoryName: j['category_name'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '',
    districtId: j['district_id'] as int,
    districtName: j['district_name'] as String? ?? '',
    budgetMin: j['budget_min'] as num?,
    budgetMax: j['budget_max'] as num?,
    preferredDate: j['preferred_date'] != null
        ? DateTime.tryParse(j['preferred_date'] as String)
        : null,
    needsInvoice: j['needs_invoice'] as bool? ?? false,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    distanceKm: j['distance_km'] as num?,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Resultado de postular a un pedido.
class ApplyResult {
  const ApplyResult({required this.success, this.balance, this.message, this.error});

  final bool success;
  final int? balance;
  final String? message;
  final String? error;
}

/// Feed del técnico: pedidos disponibles + postular (débito atómico).
class TechnicianFeedService {
  final InsForgeClient _client = InsForgeClient();

  /// Pedidos disponibles. Por defecto solo de su zona + sus categorías;
  /// con [allCategories] true muestra cualquier categoría; con [allZones]
  /// true muestra cualquier zona.
  Future<List<AvailableRequest>> getAvailableRequests({
    bool allCategories = false,
    bool allZones = false,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_available_requests',
        body: {
          'p_all_categories': allCategories,
          'p_all_zones': allZones,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => AvailableRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint('getAvailableRequests error: ${response.statusCode}');
      return const [];
    } catch (e) {
      debugPrint('Exception getAvailableRequests: $e');
      return const [];
    }
  }

  /// Postula a un pedido (cobra 1 crédito atómicamente).
  Future<ApplyResult> applyToRequest(
    String requestId, {
    String? message,
    num? proposedPrice,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/apply_to_request',
        body: {
          'p_request_id': requestId,
          'p_message': message,
          'p_proposed_price': proposedPrice,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplyResult(
          success: r['success'] == true,
          balance: (r['balance'] as num?)?.toInt(),
          message: r['message'] as String?,
          error: r['error'] as String?,
        );
      }
      return const ApplyResult(success: false, message: 'No se pudo postular.');
    } catch (e) {
      debugPrint('Exception applyToRequest: $e');
      return const ApplyResult(success: false, message: 'Error de conexión.');
    }
  }
}
