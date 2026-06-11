import 'package:flutter/foundation.dart';

/// Snapshot inmutable del estado de sesión en memoria.
@immutable
class AuthSnapshot {
  const AuthSnapshot({required this.isAuthenticated, this.profile});

  final bool isAuthenticated;
  final Map<String, dynamic>? profile;

  bool get isTechnician => profile != null && profile!['role'] == 'technician';

  /// Estado inicial: aún no autenticado / sin resolver.
  static const unknown = AuthSnapshot(isAuthenticated: false);
}

/// Cache en memoria del estado de autenticación.
///
/// Se resuelve una sola vez en el splash (y se actualiza en login / OAuth /
/// logout). Los home la leen de forma **síncrona** para pintar el header con el
/// estado correcto desde el primer frame, evitando el parpadeo
/// "no autenticado → autenticado" que producía el chequeo por red en initState.
class AuthStore {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  final ValueNotifier<AuthSnapshot> notifier = ValueNotifier<AuthSnapshot>(
    AuthSnapshot.unknown,
  );

  AuthSnapshot get value => notifier.value;

  /// Marca la sesión como activa, opcionalmente con el perfil ya cargado.
  void setAuthenticated(Map<String, dynamic>? profile) {
    notifier.value = AuthSnapshot(isAuthenticated: true, profile: profile);
  }

  /// Limpia el estado: usado al cerrar sesión o cuando no hay sesión activa.
  void setUnauthenticated() {
    notifier.value = const AuthSnapshot(isAuthenticated: false);
  }
}
