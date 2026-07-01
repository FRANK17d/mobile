import 'dart:io';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/insforge_client.dart';

/// Handler de mensajes en background (top-level function requerida por Firebase).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Push] Background message: ${message.messageId}');
}

/// Canal de notificaciones Android de alta importancia.
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'toke_plus_notifications',
  'Notificaciones Toke+',
  description: 'Notificaciones de pedidos, postulaciones y pagos.',
  importance: Importance.high,
);

/// Servicio de push notifications vía Firebase Cloud Messaging.
///
/// Flujo:
/// 1. [init] → inicializa Firebase, pide permiso, obtiene token FCM.
/// 2. [registerToken] → guarda token en tabla `device_tokens` (upsert por token único).
/// 3. Escucha mensajes foreground/background y muestra notificación local.
/// 4. [dispose] → limpia listeners.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final InsForgeClient _client = InsForgeClient();

  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;

  /// Inicializa Firebase y configura notificaciones.
  /// Llamar una vez en main() después de WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    if (_initialized) return;

    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // Inicializar local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Foreground presentation en iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Escuchar tap en notificación que abrió la app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app se abrió desde una notificación (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerTokenInBackend(newToken);
    });

    _initialized = true;
  }

  /// Pide permiso de notificaciones y registra el token FCM.
  /// Llamar después de que el usuario se autentique.
  Future<void> requestPermissionAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _registerTokenInBackend(token);
      }
    } else {
      debugPrint('[Push] Permission denied');
    }
  }

  /// Registra el token FCM en la tabla device_tokens (upsert).
  Future<void> _registerTokenInBackend(String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final userId = await _client.getCurrentUserId();
      if (userId == null) return;

      // Upsert: si el token ya existe, actualizar last_used_at
      final response = await _client.post(
        '/api/database/rpc/upsert_device_token',
        body: {'p_token': token, 'p_platform': platform},
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[Push] Token registrado: ${token.substring(0, 20)}...');
      } else {
        debugPrint('[Push] Error registrando token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Push] Error registrando token: $e');
    }
  }

  /// Desregistra el token actual (al hacer logout).
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _client.post(
        '/api/database/rpc/deactivate_device_token',
        body: {'p_token': _currentToken},
        requireAuth: true,
      );
      debugPrint('[Push] Token desregistrado');
    } catch (e) {
      debugPrint('[Push] Error desregistrando token: $e');
    }
    _currentToken = null;
  }

  /// Muestra una notificación local cuando llega un mensaje en foreground.
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Toke+',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFC8102E),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Maneja tap en notificación (navegar a pantalla específica).
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    debugPrint('[Push] Notification tapped: $data');
    // TODO: Implementar navegación según type:
    // - request_approved → /requests/{id}
    // - application_accepted → /requests/{id}
    // - new_application → /requests/{id}
    // - payment_received → /wallet
    // Por ahora el in-app notification service ya maneja la UI.
  }

  /// Callback de tap en notificación local.
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('[Push] Local notification tapped: $data');
      // Misma lógica que _handleNotificationTap
    } catch (_) {}
  }

  void dispose() {
    _initialized = false;
  }
}
