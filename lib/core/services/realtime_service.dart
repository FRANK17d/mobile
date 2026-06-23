import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/insforge_client.dart';

/// Callback que recibe el payload (Map) de un evento realtime.
typedef RealtimeHandler = void Function(Map<String, dynamic> payload);

/// Cliente Realtime (Socket.IO) de InsForge.
///
/// Conexión única para toda la app. Se conecta con el JWT del usuario y
/// permite suscribirse a canales y escuchar eventos (INSERT/UPDATE/DELETE o
/// eventos personalizados publicados por los triggers de la BD).
///
/// Uso:
///   await RealtimeService.instance.connect();
///   RealtimeService.instance.subscribe('requests');
///   RealtimeService.instance.on('new_open_request', (payload) { ... });
class RealtimeService {
  RealtimeService._internal();
  static final RealtimeService instance = RealtimeService._internal();

  static const String _baseUrl = InsForgeClient.baseUrl;

  io.Socket? _socket;
  final InsForgeClient _client = InsForgeClient();
  bool _listenersRegistered = false;

  /// Canales suscritos actualmente (se re-suscriben al reconectar).
  final Set<String> _channels = {};

  /// Handlers por evento. Cada evento puede tener varios listeners.
  final Map<String, List<RealtimeHandler>> _handlers = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Abre la conexión con el token actual. Idempotente.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _client.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('Realtime: sin token, no se conecta.');
      return;
    }

    // Reusar socket si ya existe pero está desconectado.
    _socket ??= io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    final socket = _socket!;

    if (!_listenersRegistered) {
      socket.onConnect((_) {
        debugPrint('Realtime: conectado (${socket.id})');
        // Re-suscribir todos los canales tras (re)conectar.
        for (final ch in _channels) {
          socket.emit('realtime:subscribe', {'channel': ch});
        }
      });
      socket.onDisconnect(
        (reason) => debugPrint('Realtime: desconectado ($reason)'),
      );
      socket.onConnectError(
        (e) => debugPrint('Realtime: error de conexión $e'),
      );

      // Re-emitir cada evento entrante a sus handlers registrados.
      socket.onAny((event, data) {
        final list = _handlers[event];
        if (list == null || list.isEmpty) return;
        final payload = data is Map<String, dynamic>
            ? data
            : (data is Map
                  ? Map<String, dynamic>.from(data)
                  : <String, dynamic>{});
        for (final h in List<RealtimeHandler>.from(list)) {
          h(payload);
        }
      });

      _listenersRegistered = true;
    }

    socket.connect();
  }

  /// Suscribe a un canal (recordado para re-suscribir al reconectar).
  void subscribe(String channel) {
    final added = _channels.add(channel);
    if (!added) return;
    if (isConnected) {
      _socket!.emit('realtime:subscribe', {'channel': channel});
    }
  }

  void unsubscribe(String channel) {
    _channels.remove(channel);
    if (isConnected) {
      _socket!.emit('realtime:unsubscribe', {'channel': channel});
    }
  }

  /// Publica un evento de cliente en un canal (debe estar suscrito).
  void publish(String channel, String event, Map<String, dynamic> payload) {
    if (!isConnected) return;
    _socket!.emit('realtime:publish', {
      'channel': channel,
      'event': event,
      'payload': payload,
    });
  }

  /// Registra un listener para un evento. Devuelve una función para quitarlo.
  VoidCallback on(String event, RealtimeHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    return () => off(event, handler);
  }

  void off(String event, RealtimeHandler handler) {
    _handlers[event]?.remove(handler);
  }

  /// Cierra la conexión y limpia el estado (al cerrar sesión).
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _listenersRegistered = false;
    _channels.clear();
    _handlers.clear();
  }
}
