import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../network/insforge_client.dart';
import 'realtime_service.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: j['type'] as String? ?? '',
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    data: j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : {},
    readAt: j['read_at'] != null
        ? DateTime.tryParse(j['read_at'] as String)
        : null,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

/// Servicio de notificaciones in-app.
/// - Escucha realtime `notifications:{userId}` para nuevas notificaciones.
/// - Carga historial desde el RPC `get_my_notifications`.
/// - Expone un ValueNotifier con la cantidad de no leídas (para badge).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final InsForgeClient _client = InsForgeClient();
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  String? _channel;
  VoidCallback? _rtOff;

  Future<void> init() async {
    final userId = await _client.getCurrentUserId();
    if (userId == null) {
      dispose();
      return;
    }

    final channel = 'notifications:$userId';
    if (_channel == channel && _rtOff != null) {
      await loadHistory();
      return;
    }

    if (_channel != null && _channel != channel) {
      dispose();
    }

    _channel = channel;

    final rt = RealtimeService.instance;
    await rt.connect();
    rt.subscribe(channel);
    _rtOff = rt.on('notification', (payload) {
      final n = AppNotification.fromJson(payload);
      final current = [...notifications.value];
      if (!current.any((e) => e.id == n.id)) {
        notifications.value = [n, ...current];
        unreadCount.value = notifications.value.where((e) => !e.isRead).length;
      }
    });

    await loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_notifications',
        body: {'p_limit': 50},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final list = data
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        notifications.value = list;
        unreadCount.value = list.where((e) => !e.isRead).length;
      }
    } catch (e) {
      debugPrint('NotificationService.loadHistory error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.post(
        '/api/database/rpc/mark_notification_read',
        body: {'p_notification_id': notificationId},
        requireAuth: true,
      );
      final current = notifications.value.map((n) {
        if (n.id == notificationId) {
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifications.value = current;
      unreadCount.value = current.where((e) => !e.isRead).length;
    } catch (e) {
      debugPrint('NotificationService.markAsRead error: $e');
    }
  }

  /// Borra una notificación (swipe-to-delete). Optimista: la quita de la lista
  /// local de inmediato y, si el RPC falla, recarga para re-sincronizar.
  Future<void> deleteNotification(String notificationId) async {
    final previous = notifications.value;
    final updated = previous
        .where((n) => n.id != notificationId)
        .toList(growable: false);
    notifications.value = updated;
    unreadCount.value = updated.where((e) => !e.isRead).length;

    try {
      final response = await _client.post(
        '/api/database/rpc/delete_notification',
        body: {'p_notification_id': notificationId},
        requireAuth: true,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        await loadHistory();
      }
    } catch (e) {
      debugPrint('NotificationService.deleteNotification error: $e');
      await loadHistory();
    }
  }

  void dispose() {
    _rtOff?.call();
    _rtOff = null;
    if (_channel != null) {
      RealtimeService.instance.unsubscribe(_channel!);
    }
    _channel = null;
  }
}
