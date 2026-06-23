import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../network/insforge_client.dart';

/// Acceso biométrico (huella / rostro) para iniciar sesión sin escribir la
/// contraseña.
///
/// Al activarlo, se guardan las credenciales del usuario en almacenamiento
/// seguro (cifrado por el sistema). Para usarlas (login) o activarlo, se exige
/// primero la verificación biométrica del dispositivo.
class BiometricService {
  BiometricService._internal();
  static final BiometricService instance = BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kEnabled = 'biometric_enabled';
  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';
  static const _kUserId = 'biometric_user_id';

  /// ¿El dispositivo tiene hardware biométrico utilizable y configurado?
  Future<bool> isDeviceSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('Biometric isDeviceSupported error: $e');
      return false;
    }
  }

  /// ¿El usuario activó el acceso biométrico en esta app?
  Future<bool> isEnabled() async {
    return (await _storage.read(key: _kEnabled)) == 'true';
  }

  /// Muestra el prompt biométrico. Devuelve true si la verificación fue exitosa.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authenticate error: $e');
      return false;
    }
  }

  /// Activa el acceso biométrico: pide verificación y guarda las credenciales
  /// junto al id del usuario (para saber a quién pertenece). Devuelve true si
  /// quedó activado.
  Future<bool> enable({
    required String email,
    required String password,
    String? userId,
  }) async {
    final ok = await authenticate(
      'Verifica tu identidad para activar el acceso biométrico',
    );
    if (!ok) return false;
    final uid = userId ?? await InsForgeClient().getCurrentUserId();
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
    if (uid != null) await _storage.write(key: _kUserId, value: uid);
    await _storage.write(key: _kEnabled, value: 'true');
    return true;
  }

  /// Desactiva el acceso biométrico y borra las credenciales guardadas.
  Future<void> disable() async {
    await _storage.delete(key: _kEnabled);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
    await _storage.delete(key: _kUserId);
  }

  /// Id del usuario que activó la biometría (para verificar que coincide con la
  /// sesión actual en Ajustes).
  Future<String?> enabledUserId() => _storage.read(key: _kUserId);

  /// Pide verificación biométrica y devuelve las credenciales guardadas para
  /// iniciar sesión, o null si falla / no hay credenciales.
  Future<({String email, String password})?> getCredentials() async {
    if (!await isEnabled()) return null;
    final ok = await authenticate('Inicia sesión con tu huella');
    if (!ok) return null;
    final email = await _storage.read(key: _kEmail);
    final password = await _storage.read(key: _kPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// Email guardado (para mostrar en el botón de login biométrico).
  Future<String?> savedEmail() => _storage.read(key: _kEmail);
}
