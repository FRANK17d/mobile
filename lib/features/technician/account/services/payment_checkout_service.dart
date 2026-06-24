import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/insforge_client.dart';

class PaymentCheckoutData {
  const PaymentCheckoutData({required this.orderId, required this.checkoutUrl});

  final String orderId;
  final String checkoutUrl;

  factory PaymentCheckoutData.fromJson(Map<String, dynamic> json) {
    return PaymentCheckoutData(
      orderId: json['orderId'] as String? ?? '',
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
    );
  }
}

class PaymentCheckoutService {
  PaymentCheckoutService();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'TOKE_API_BASE_URL',
    defaultValue: 'https://api.tokeplus.app',
  );

  final InsForgeClient _client = InsForgeClient();

  String get _apiBaseUrl =>
      _configuredApiBaseUrl.replaceFirst(RegExp(r'/+$'), '');

  Future<PaymentCheckoutData?> createCreditsCheckout(int packageId) {
    return _createCheckout('/credits/checkout', {'packageId': packageId});
  }

  Future<PaymentCheckoutData?> createTokeProCheckout(int planId) {
    return _createCheckout('/tokepro/checkout', {'planId': planId});
  }

  Future<PaymentCheckoutData?> _createCheckout(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _client.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('Payment checkout failed: missing session token');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/payments$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final datos = payload['datos'] as Map<String, dynamic>?;
        if (datos == null) return null;

        final checkout = PaymentCheckoutData.fromJson(datos);
        return checkout.checkoutUrl.isEmpty ? null : checkout;
      }

      debugPrint(
        'Payment checkout error (${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Exception creating payment checkout: $e');
      return null;
    }
  }
}
