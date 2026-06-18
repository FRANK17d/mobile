import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/network/insforge_client.dart';

/// Una conversación 1:1 (lo que ve en la lista de chats).
class Conversation {
  const Conversation({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.categoryEmoji,
    required this.otherFirstName,
    this.otherAvatarUrl,
    this.lastBody,
    this.lastMessageAt,
    this.proposedPrice,
    required this.iAmClient,
  });

  final String id;
  final String requestId;
  final String requestTitle;
  final String categoryEmoji;
  final String otherFirstName;
  final String? otherAvatarUrl;
  final String? lastBody;
  final DateTime? lastMessageAt;
  final num? proposedPrice;
  final bool iAmClient;

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    requestId: j['request_id'] as String,
    requestTitle: j['request_title'] as String? ?? '',
    categoryEmoji: j['category_emoji'] as String? ?? '💬',
    otherFirstName: j['other_first_name'] as String? ?? 'Usuario',
    otherAvatarUrl: j['other_avatar_url'] as String?,
    lastBody: j['last_body'] as String?,
    lastMessageAt: j['last_message_at'] != null
        ? DateTime.tryParse(j['last_message_at'] as String)
        : null,
    proposedPrice: j['proposed_price'] as num?,
    iAmClient: j['i_am_client'] as bool? ?? false,
  );
}

/// Un mensaje del hilo.
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.body,
    required this.mine,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String body;
  final bool mine;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> j, {String? myId}) => Message(
    id: j['id'] as String,
    senderId: j['sender_id'] as String? ?? '',
    body: j['body'] as String? ?? '',
    // 'mine' viene de get_messages; en eventos realtime se calcula con myId.
    mine: j['mine'] as bool? ?? (myId != null && j['sender_id'] == myId),
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Chat: lista de conversaciones, mensajes e envío.
class ChatService {
  final InsForgeClient _client = InsForgeClient();

  Future<List<Conversation>> getMyConversations() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_conversations',
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getMyConversations: $e');
      return const [];
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_messages',
        body: {'p_conversation_id': conversationId},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('Exception getMessages: $e');
      return const [];
    }
  }

  /// Envía un mensaje. Devuelve true si se guardó (el realtime lo refleja).
  Future<bool> sendMessage(String conversationId, String body) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/send_message',
        body: {'p_conversation_id': conversationId, 'p_body': body},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return r['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Exception sendMessage: $e');
      return false;
    }
  }
}
