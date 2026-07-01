import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Resultado de agendar un horario preferido.
typedef BookingResult = ({bool success, String? message});

/// Servicio para agendar horarios en pedidos de servicio.
class BookingService {
  final InsForgeClient _client = InsForgeClient();

  /// Actualiza la fecha/hora preferida de un pedido existente.
  /// Usa el RPC `update_service_request` con el campo `p_preferred_date`.
  Future<BookingResult> updatePreferredDate(
    String requestId,
    DateTime dateTime,
  ) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/update_service_request',
        body: {
          'p_request_id': requestId,
          'p_preferred_date': dateTime.toUtc().toIso8601String(),
        },
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        final ok = r['success'] == true;
        return (
          success: ok,
          message: ok
              ? 'Horario agendado correctamente.'
              : (r['message'] as String? ?? 'No se pudo agendar el horario.'),
        );
      }

      debugPrint(
        'updatePreferredDate error: ${response.statusCode} ${response.body}',
      );
      return (
        success: false,
        message: 'No se pudo agendar el horario.',
      );
    } catch (e) {
      debugPrint('Exception updatePreferredDate: $e');
      return (success: false, message: 'Error de conexión.');
    }
  }
}
