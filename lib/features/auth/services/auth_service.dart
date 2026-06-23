import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/insforge_client.dart';

/// Modelo de datos para el registro de técnico
class TechnicianRegistrationData {
  final String firstName;
  final String lastName;
  final String dni;
  final String district;
  final int? districtId;
  final String bio;
  final String phone;
  final String email;
  final String password;
  final String? avatarUrl;
  final List<String> categories;

  const TechnicianRegistrationData({
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.district,
    this.districtId,
    required this.bio,
    required this.phone,
    required this.email,
    required this.password,
    this.avatarUrl,
    required this.categories,
  });
}

/// Resultado del registro de técnico
class TechnicianRegistrationResult {
  final bool success;
  final String? userId;
  final String? verificationStatus;
  final String? error;
  final String message;

  const TechnicianRegistrationResult({
    required this.success,
    this.userId,
    this.verificationStatus,
    this.error,
    required this.message,
  });
}

/// Modelo de datos para el registro de cliente.
class ClientRegistrationData {
  final String firstName;
  final String lastName;
  final String district;
  final int? districtId;
  final String phone;
  final String email;
  final String password;

  const ClientRegistrationData({
    required this.firstName,
    required this.lastName,
    required this.district,
    this.districtId,
    required this.phone,
    required this.email,
    required this.password,
  });
}

/// Resultado del registro/perfil de cliente.
class ClientRegistrationResult {
  final bool success;
  final String? userId;
  final String? error;
  final String message;

  const ClientRegistrationResult({
    required this.success,
    this.userId,
    this.error,
    required this.message,
  });
}

class AuthService {
  static const googleOAuthRedirectUri = 'tokeplus://auth/callback';
  static const _googleCodeVerifierKey = 'google_oauth_code_verifier';

  final InsForgeClient _client = InsForgeClient();
  final FlutterSecureStorage _oauthStorage = const FlutterSecureStorage();

  /// Logs in a user with email and password
  /// Returns the userId on success, or null on failure.
  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/api/auth/sessions?client_type=mobile',
        body: {'email': email, 'password': password},
        requireAuth: false, // Use anon key
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;
        final userId = user?['id'] as String?;

        if (accessToken != null && userId != null) {
          await _client.saveTokens(accessToken, refreshToken);
          return userId;
        }
        return null;
      } else {
        debugPrint('Login Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during login: $e');
      return null;
    }
  }

  /// Registers a new user. Assigns role "usuario" natively in DB via trigger or manual insert if needed.
  /// The InsForge API assigns default role 'client', we can pass name if supported.
  Future<bool> register(
    String email,
    String password, {
    String name = 'Usuario',
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/users?client_type=mobile',
        body: {'email': email, 'password': password, 'name': name},
        requireAuth: false, // Use anon key
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null) {
          await _client.saveTokens(accessToken, refreshToken);
        }
        return true;
      } else {
        debugPrint('Register Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during register: $e');
      return false;
    }
  }

  /// Completa el perfil app del cliente después de verificar email.
  Future<ClientRegistrationResult> completeClientProfile({
    required String userId,
    required ClientRegistrationData data,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/create_client_profile',
        body: {
          'p_user_id': userId,
          'p_first_name': data.firstName,
          'p_last_name': data.lastName,
          'p_district_name': data.district,
          'p_district_id': data.districtId,
          'p_phone': data.phone,
          'p_email': data.email,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return ClientRegistrationResult(
            success: true,
            userId: result['user_id'] ?? userId,
            message: result['message'] ?? 'Registro completado.',
          );
        }

        return ClientRegistrationResult(
          success: false,
          error: result['error'],
          message: result['message'] ?? 'Error al completar el perfil.',
        );
      }

      debugPrint('Client profile RPC Error: ${response.body}');
      return ClientRegistrationResult(
        success: false,
        error: 'rpc_failed',
        message:
            'Error al guardar los datos del cliente (${response.statusCode}).',
      );
    } catch (e) {
      debugPrint('Exception completing client profile: $e');
      return const ClientRegistrationResult(
        success: false,
        error: 'network',
        message: 'Error de conexión al guardar el perfil.',
      );
    }
  }

  /// Asegura que un usuario OAuth (Google) tenga perfil app como cliente.
  ///
  /// Solo crea el perfil la PRIMERA vez (si ya existe, respeta sus datos para no
  /// pisar lo que el usuario haya editado). Toma su nombre + un apellido (y foto)
  /// reales desde los datos del proveedor de Google.
  Future<bool> ensureClientProfile({
    required String userId,
    String? email,
    String? displayName,
  }) async {
    final currentProfile = await getMyTechnicianProfile();
    // Ya tiene perfil (cualquier rol): no sobrescribir.
    if (currentProfile != null) return true;

    final oauth = await getMyOAuthName();
    var firstName = (oauth?.givenName ?? '').trim();
    var lastName = _firstWord(oauth?.familyName ?? '');

    // Fallback: partir el display name si Google no trajo los campos separados.
    if (firstName.isEmpty || lastName.isEmpty) {
      final parts = (oauth?.name ?? displayName ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (firstName.isEmpty) {
        firstName = parts.isNotEmpty ? parts.first : 'Cliente';
      }
      if (lastName.isEmpty && parts.length > 1) lastName = parts[1];
    }

    final result = await completeClientProfile(
      userId: userId,
      data: ClientRegistrationData(
        firstName: firstName,
        lastName: lastName,
        district: 'Trujillo',
        phone: '',
        email: email ?? '',
        password: '',
      ),
    );

    // Foto de Google (el RPC de creación de perfil no la setea).
    final avatar = oauth?.avatarUrl;
    if (result.success && avatar != null && avatar.isNotEmpty) {
      await updateProfile(
        firstName: firstName,
        lastName: lastName,
        avatarUrl: avatar,
      );
    }

    return result.success;
  }

  /// Primera palabra (un solo apellido) de un texto.
  String _firstWord(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    final m = RegExp(r'\s').firstMatch(t);
    return m == null ? t : t.substring(0, m.start);
  }

  /// Datos del proveedor OAuth (Google) del usuario actual: nombre, un apellido
  /// y foto. Null si no es cuenta OAuth o no hay datos.
  Future<
    ({String? givenName, String? familyName, String? name, String? avatarUrl})?
  >
  getMyOAuthName() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_oauth_name',
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body);
        if (r is Map) {
          return (
            givenName: r['given_name'] as String?,
            familyName: r['family_name'] as String?,
            name: r['name'] as String?,
            avatarUrl: r['avatar_url'] as String?,
          );
        }
      }
    } catch (e) {
      debugPrint('getMyOAuthName error: $e');
    }
    return null;
  }

  /// Verifies the user's email with the OTP code sent
  /// Returns the userId on success, or null on failure.
  Future<String?> verifyEmail(String email, String otp) async {
    try {
      final response = await _client.post(
        '/api/auth/email/verify?client_type=mobile',
        body: {'email': email, 'otp': otp},
        requireAuth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (accessToken != null) {
          await _client.saveTokens(accessToken, refreshToken);
        }
        return user?['id'] as String?;
      } else {
        debugPrint('Verify Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during email verification: $e');
      return null;
    }
  }

  /// Resends the OTP verification code
  Future<bool> resendOtp(String email) async {
    try {
      final response = await _client.post(
        '/api/auth/email/send-verification',
        body: {'email': email},
        requireAuth: false,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Exception during resend OTP: $e');
      return false;
    }
  }

  /// Solicita el código de recuperación de contraseña por email.
  Future<bool> sendPasswordResetCode(String email) async {
    try {
      final response = await _client.post(
        '/api/auth/email/send-reset-password',
        body: {'email': email},
        requireAuth: false,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Exception sending password reset code: $e');
      return false;
    }
  }

  /// Intercambia el código OTP de recuperación por un token de reset.
  Future<String?> exchangePasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/email/exchange-reset-password-token',
        body: {'email': email, 'code': code},
        requireAuth: false,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Password reset code exchange error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['token'] as String?;
    } catch (e) {
      debugPrint('Exception exchanging password reset code: $e');
      return null;
    }
  }

  /// Actualiza la contraseña usando el token obtenido desde el OTP.
  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post(
        '/api/auth/email/reset-password',
        body: {'otp': resetToken, 'newPassword': newPassword},
        requireAuth: false,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Exception resetting password: $e');
      return false;
    }
  }

  /// Initiates Google OAuth flow. The callback is handled by TokeApp deep links.
  Future<bool> loginWithGoogle() async {
    // 1. Generate PKCE code verifier and challenge
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final codeVerifier = base64UrlEncode(values).replaceAll('=', '');

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    await _oauthStorage.write(key: _googleCodeVerifierKey, value: codeVerifier);

    final redirectUri = Uri.encodeComponent(googleOAuthRedirectUri);
    final apiUrl =
        '/api/auth/oauth/google?redirect_uri=$redirectUri&code_challenge=$codeChallenge';

    try {
      final response = await _client.get(apiUrl, requireAuth: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authUrl = data['authUrl'];

        final url = Uri.parse(authUrl);
        if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
          return true;
        }

        debugPrint('Could not launch $url');
      } else {
        debugPrint('Error getting Google auth URL: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during Google Auth: $e');
    }

    return false;
  }

  /// Completes the Google OAuth PKCE callback and creates a client profile.
  Future<String?> completeGoogleLogin(Uri callbackUri) async {
    final code = callbackUri.queryParameters['insforge_code'];
    if (code == null || code.isEmpty) return null;

    final codeVerifier = await _oauthStorage.read(key: _googleCodeVerifierKey);
    if (codeVerifier == null || codeVerifier.isEmpty) return null;

    try {
      final response = await _client.post(
        '/api/auth/oauth/exchange?client_type=mobile',
        body: {'code': code, 'code_verifier': codeVerifier},
        requireAuth: false,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Google OAuth exchange error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = data['user'] as Map<String, dynamic>?;
      final userId = user?['id'] as String?;

      if (accessToken == null || userId == null) return null;

      await _client.saveTokens(accessToken, refreshToken);
      await _oauthStorage.delete(key: _googleCodeVerifierKey);

      final profileReady = await ensureClientProfile(
        userId: userId,
        email: user?['email'] as String?,
        displayName: user?['name'] as String?,
      );

      if (!profileReady) {
        await _client.clearTokens();
        return null;
      }

      return userId;
    } catch (e) {
      debugPrint('Exception completing Google OAuth: $e');
      return null;
    }
  }

  /// Logs out the user and clears ALL stored auth state.
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      // Limpia todos los datos: tokens + code verifier OAuth + cualquier residuo.
      await _client.clearAllAuthData();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Registro completo de técnico (2 pasos atómicos)
  // ─────────────────────────────────────────────────────────

  /// Registra un técnico/prestador de servicio completo.
  /// Paso 1: Crea el usuario en auth (signUp con email+password)
  /// Paso 2: Llama RPC register_technician para crear perfil+datos
  Future<TechnicianRegistrationResult> registerTechnician(
    TechnicianRegistrationData data,
  ) async {
    try {
      // ── Paso 1: Crear usuario en auth ──
      final fullName = '${data.firstName} ${data.lastName}';
      final registerSuccess = await register(
        data.email,
        data.password,
        name: fullName,
      );

      if (!registerSuccess) {
        return const TechnicianRegistrationResult(
          success: false,
          error: 'auth_failed',
          message:
              'No se pudo crear la cuenta. Verifica tu correo e intenta de nuevo.',
        );
      }

      // ── Paso 2: Completar perfil de técnico via RPC ──
      final rpcResult = await completeTechnicianProfile(data);
      return rpcResult;
    } catch (e) {
      debugPrint('Exception during technician registration: $e');
      return TechnicianRegistrationResult(
        success: false,
        error: 'unexpected',
        message: 'Error inesperado: $e',
      );
    }
  }

  /// Completa el perfil de técnico llamando a la función RPC.
  /// Requiere que el usuario ya esté autenticado (tokens guardados).
  /// Se usa después de verificar email (OTP) en el flujo de registro.
  Future<TechnicianRegistrationResult> completeTechnicianProfile(
    TechnicianRegistrationData data,
  ) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/register_technician',
        body: {
          'p_first_name': data.firstName,
          'p_last_name': data.lastName,
          'p_dni': data.dni,
          'p_district_name': data.district,
          'p_district_id': data.districtId,
          'p_bio': data.bio,
          'p_phone': data.phone,
          'p_email': data.email.trim().isEmpty ? null : data.email.trim(),
          'p_avatar_url': data.avatarUrl,
          'p_categories': data.categories,
        },
        requireAuth: true, // Usa el JWT del usuario recién creado
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);

        if (result['success'] == true) {
          return TechnicianRegistrationResult(
            success: true,
            userId: result['user_id'],
            verificationStatus: result['verification_status'],
            message: result['message'] ?? 'Registro completado.',
          );
        } else {
          return TechnicianRegistrationResult(
            success: false,
            error: result['error'],
            message: result['message'] ?? 'Error al completar el perfil.',
          );
        }
      } else {
        debugPrint('RPC Error: ${response.body}');
        return TechnicianRegistrationResult(
          success: false,
          error: 'rpc_failed',
          message:
              'Error al guardar los datos del perfil (${response.statusCode}).',
        );
      }
    } catch (e) {
      debugPrint('Exception during RPC call: $e');
      return TechnicianRegistrationResult(
        success: false,
        error: 'network',
        message: 'Error de conexión al guardar el perfil.',
      );
    }
  }

  /// Obtiene el perfil completo del técnico autenticado.
  Future<Map<String, dynamic>?> getMyTechnicianProfile() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_technician_profile',
        requireAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Exception fetching technician profile: $e');
      return null;
    }
  }

  /// Sube una nueva foto de perfil al bucket público `avatars`.
  /// Devuelve la URL pública, o null si falla.
  Future<String?> uploadAvatar(String filePath) async {
    final userId = await _client.getCurrentUserId();
    if (userId == null || userId.isEmpty) return null;

    final ext = filePath.split('.').last.toLowerCase();
    final safeExt = switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => ext,
      _ => 'jpg',
    };
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectKey = 'clients/$userId/avatar-$timestamp.$safeExt';

    final result = await _client.uploadFile(
      bucket: 'avatars',
      filePath: filePath,
      objectKey: objectKey,
    );
    return result?['url'];
  }

  /// Actualiza los campos básicos del perfil propio (nombre, apellido,
  /// teléfono, avatar) vía RPC `update_profile`. No cambia rol ni email.
  Future<({bool success, String? message})> updateProfile({
    required String firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/update_profile',
        body: {
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_phone': phone,
          'p_avatar_url': avatarUrl,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          success: r['success'] == true,
          message: r['message'] as String?,
        );
      }
      debugPrint('updateProfile error: ${response.statusCode} ${response.body}');
      return (success: false, message: 'No se pudo actualizar el perfil.');
    } catch (e) {
      debugPrint('Exception updateProfile: $e');
      return (success: false, message: 'Error de conexión.');
    }
  }

  /// Email del usuario autenticado (desde la sesión actual). Se usa para el
  /// flujo de cambio de contraseña (que requiere enviar un código a su correo).
  Future<String?> getCurrentUserEmail() async {
    try {
      final response = await _client.get('/api/auth/sessions/current');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>?;
        final email = user?['email'] as String?;
        if (email != null && email.isNotEmpty) return email;
      }
    } catch (e) {
      debugPrint('getCurrentUserEmail error: $e');
    }
    return null;
  }

  /// Convierte la cuenta actual (cliente) en prestador de servicios. Solo
  /// requiere DNI y presentación; el resto (nombre/teléfono/distrito) se reutiliza
  /// del perfil. Las categorías se agregan luego en el panel del técnico.
  Future<({bool success, String? message})> convertToTechnician({
    required String dni,
    required String bio,
  }) async {
    try {
      final response = await _client.post(
        '/api/database/rpc/convert_to_technician',
        body: {'p_dni': dni, 'p_bio': bio},
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body);
        if (r is Map) {
          return (success: r['success'] == true, message: r['message'] as String?);
        }
        return (success: false, message: 'Respuesta inesperada del servidor.');
      }
      debugPrint(
        'convertToTechnician error: ${response.statusCode} ${response.body}',
      );
      return (success: false, message: 'No se pudo completar la conversión.');
    } catch (e) {
      debugPrint('Exception convertToTechnician: $e');
      return (success: false, message: 'Error de conexión.');
    }
  }

  /// True si la cuenta tiene contraseña (login por email). Las cuentas solo-Google
  /// devuelven false → no se les ofrece el acceso biométrico. Ante error asume
  /// true para no bloquear a usuarios de email.
  Future<bool> currentUserHasPassword() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/current_user_has_password',
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body);
        return r == true;
      }
    } catch (e) {
      debugPrint('currentUserHasPassword error: $e');
    }
    return true;
  }

  /// Desactiva (da de baja) la cuenta del usuario autenticado vía RPC
  /// `deactivate_my_account`. No borra datos históricos (pedidos) por integridad
  /// referencial: marca el perfil como inactivo para que deje de ser visible y
  /// no pueda operar. Devuelve true si se desactivó correctamente.
  Future<bool> deactivateAccount() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/deactivate_my_account',
        requireAuth: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final r = jsonDecode(response.body);
        return r is Map ? r['success'] == true : true;
      }
      debugPrint(
        'deactivateAccount error: ${response.statusCode} ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Exception deactivateAccount: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual tiene sesión activa
  Future<bool> hasActiveSession() async {
    final accessToken = await _client.getAccessToken();
    final refreshToken = await _client.getRefreshToken();
    if (accessToken == null && refreshToken == null) return false;

    try {
      final response = await _client.get('/api/auth/sessions/current');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['user'] != null;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _client.clearTokens();
      }
      return false;
    } catch (e) {
      debugPrint('Exception checking active session: $e');
      return false;
    }
  }
}
