import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

class TokeProPlanData {
  const TokeProPlanData({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.pricePen,
    required this.includedCredits,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final int durationDays;
  final double pricePen;
  final int includedCredits;
  final int sortOrder;

  factory TokeProPlanData.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price_pen'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return TokeProPlanData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      pricePen: price,
      includedCredits: (json['included_credits'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class TokeProService {
  final InsForgeClient _client = InsForgeClient();

  Future<List<TokeProPlanData>?> getActivePlans() async {
    try {
      final response = await _client.get(
        '/api/database/records/subscription_plans'
        '?is_active=eq.true&order=sort_order.asc&select=id,name,duration_days,price_pen,included_credits,sort_order',
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final plans =
            data
                .map((e) => TokeProPlanData.fromJson(e as Map<String, dynamic>))
                .where((plan) => plan.id > 0 && plan.durationDays > 0)
                .toList()
              ..sort((a, b) {
                final order = a.sortOrder.compareTo(b.sortOrder);
                return order != 0
                    ? order
                    : a.durationDays.compareTo(b.durationDays);
              });
        return plans;
      }

      debugPrint('getActivePlans error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Exception getActivePlans: $e');
      return null;
    }
  }
}
