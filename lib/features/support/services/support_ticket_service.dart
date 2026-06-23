import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/network/insforge_client.dart';

/// Un mensaje de un ticket de soporte.
class TicketMessage {
  const TicketMessage({
    required this.body,
    required this.isAdmin,
    this.createdAt,
  });

  final String body;
  final bool isAdmin;
  final DateTime? createdAt;

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
    body: j['body'] as String? ?? '',
    isAdmin: j['is_admin'] as bool? ?? false,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

class SupportTicketService {
  final InsForgeClient _client = InsForgeClient();
  final Random _random = Random.secure();

  Future<String?> createTicket({
    required String subject,
    required String message,
    String category = 'general',
  }) async {
    try {
      final userId = await _client.getCurrentUserId();
      if (userId == null || userId.isEmpty) return null;

      final ticketId = _uuidV4();
      final ticketResponse = await _client.post(
        '/api/database/records/support_tickets',
        body: [
          {
            'id': ticketId,
            'user_id': userId,
            'subject': _trim(subject, 200),
            'category': category,
            'priority': 'normal',
          },
        ],
        requireAuth: true,
      );

      if (ticketResponse.statusCode < 200 || ticketResponse.statusCode >= 300) {
        debugPrint('createTicket error: ${ticketResponse.body}');
        return null;
      }

      final messageResponse = await _client.post(
        '/api/database/records/ticket_messages',
        body: [
          {
            'ticket_id': ticketId,
            'sender_id': userId,
            'body': message,
            'is_admin': false,
          },
        ],
        requireAuth: true,
      );

      if (messageResponse.statusCode < 200 ||
          messageResponse.statusCode >= 300) {
        debugPrint('createTicket message error: ${messageResponse.body}');
        final rollbackResponse = await _client.delete(
          '/api/database/records/support_tickets?id=eq.$ticketId',
          requireAuth: true,
        );
        if (rollbackResponse.statusCode < 200 ||
            rollbackResponse.statusCode >= 300) {
          debugPrint('createTicket rollback error: ${rollbackResponse.body}');
        }
        return null;
      }

      return ticketId;
    } catch (e) {
      debugPrint('Exception createTicket: $e');
      return null;
    }
  }

  /// Ticket más reciente del usuario (para retomar la conversación), o null.
  Future<({String id, String status})?> getLatestTicket() async {
    try {
      final userId = await _client.getCurrentUserId();
      if (userId == null || userId.isEmpty) return null;
      final resp = await _client.get(
        '/api/database/records/support_tickets'
        '?user_id=eq.$userId&order=created_at.desc&limit=1',
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        if (data is List && data.isNotEmpty) {
          final t = data.first as Map<String, dynamic>;
          return (
            id: t['id'] as String,
            status: t['status'] as String? ?? 'open',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('getLatestTicket error: $e');
      return null;
    }
  }

  /// Mensajes de un ticket, en orden cronológico.
  Future<List<TicketMessage>> getMessages(String ticketId) async {
    try {
      final resp = await _client.get(
        '/api/database/records/ticket_messages'
        '?ticket_id=eq.$ticketId&order=created_at.asc',
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          return data
              .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } catch (e) {
      debugPrint('getMessages error: $e');
      return const [];
    }
  }

  /// Envía un mensaje del usuario a un ticket existente.
  Future<bool> sendMessage(String ticketId, String body) async {
    try {
      final userId = await _client.getCurrentUserId();
      if (userId == null || userId.isEmpty) return false;
      final resp = await _client.post(
        '/api/database/records/ticket_messages',
        body: [
          {
            'ticket_id': ticketId,
            'sender_id': userId,
            'body': _trim(body, 2000),
            'is_admin': false,
          },
        ],
        requireAuth: true,
      );
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return false;
    }
  }

  String _trim(String value, int maxLength) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxLength) return normalized;
    return normalized.substring(0, maxLength - 1).trimRight();
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
