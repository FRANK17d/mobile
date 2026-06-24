import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Tipo de transacción de créditos.
enum CreditTransactionKind {
  purchase,
  subscriptionRenewal,
  debit,
  free;

  static CreditTransactionKind fromString(String? value) {
    return switch (value) {
      'purchase' => CreditTransactionKind.purchase,
      'subscription_renewal' => CreditTransactionKind.subscriptionRenewal,
      'debit' => CreditTransactionKind.debit,
      'free' => CreditTransactionKind.free,
      _ => CreditTransactionKind.purchase,
    };
  }

  String get label => switch (this) {
    CreditTransactionKind.purchase => 'Compra de créditos',
    CreditTransactionKind.subscriptionRenewal => 'Renovación suscripción',
    CreditTransactionKind.debit => 'Uso de crédito',
    CreditTransactionKind.free => 'Crédito gratuito',
  };
}

/// Modelo de una transacción de créditos.
class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.amount,
    required this.kind,
    required this.description,
    this.reference,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final CreditTransactionKind kind;
  final String description;
  final String? reference;
  final DateTime createdAt;

  /// True si es un movimiento que suma créditos.
  bool get isPositive =>
      kind == CreditTransactionKind.purchase ||
      kind == CreditTransactionKind.subscriptionRenewal ||
      kind == CreditTransactionKind.free;

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      kind: CreditTransactionKind.fromString(json['kind'] as String?),
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Servicio para obtener el historial de transacciones de créditos del técnico.
class EarningsService {
  final InsForgeClient _client = InsForgeClient();

  /// Obtiene las transacciones recientes del técnico autenticado.
  /// Llama al RPC `get_credit_transactions`.
  Future<List<CreditTransaction>> getTransactions({int limit = 50}) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_credit_transactions',
        body: {'p_limit': limit},
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => CreditTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      debugPrint(
        'getTransactions error (${response.statusCode}): ${response.body}',
      );
      return const [];
    } catch (e) {
      debugPrint('Exception getTransactions: $e');
      return const [];
    }
  }
}
