import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

class CreditPackageData {
  const CreditPackageData({
    required this.id,
    required this.name,
    required this.credits,
    required this.pricePen,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final int credits;
  final double pricePen;
  final int sortOrder;

  factory CreditPackageData.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price_pen'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return CreditPackageData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      pricePen: price,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Lee el saldo de créditos del técnico (tabla credit_wallets).
/// RLS garantiza que solo devuelve la fila propia.
class CreditService {
  final InsForgeClient _client = InsForgeClient();

  /// Saldo actual de créditos. Devuelve 0 si no hay billetera o falla.
  Future<int> getBalance() async {
    try {
      final response = await _client.get(
        '/api/database/records/credit_wallets?select=balance',
        requireAuth: true,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isEmpty) return 0;
        final row = data.first as Map<String, dynamic>;
        return (row['balance'] as num?)?.toInt() ?? 0;
      }
      debugPrint('getBalance error: ${response.statusCode}');
      return 0;
    } catch (e) {
      debugPrint('Exception getBalance: $e');
      return 0;
    }
  }

  /// Paquetes activos editables desde el panel admin.
  Future<List<CreditPackageData>?> getActivePackages() async {
    try {
      final response = await _client.get(
        '/api/database/records/credit_packages'
        '?is_active=eq.true&order=sort_order.asc&select=id,name,credits,price_pen,sort_order',
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final packages =
            data
                .map(
                  (e) => CreditPackageData.fromJson(e as Map<String, dynamic>),
                )
                .where((pack) => pack.id > 0 && pack.credits > 0)
                .toList()
              ..sort((a, b) {
                final order = a.sortOrder.compareTo(b.sortOrder);
                return order != 0 ? order : a.credits.compareTo(b.credits);
              });
        return packages;
      }

      debugPrint('getActivePackages error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Exception getActivePackages: $e');
      return null;
    }
  }
}
