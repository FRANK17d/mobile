import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/technician_profile.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  unverified, // Registered but OTP email verification pending
}

enum AppViewMode {
  client,
  technician,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final TechnicianProfile? technicianProfile;
  final AppViewMode viewMode;
  final String? emailToVerify;
  final String? nameToRegister;
  final String? errorMessage;
  final bool isInitializing;
  final bool hasCompletedOnboarding;

  const AuthState({
    required this.status,
    this.userProfile,
    this.technicianProfile,
    required this.viewMode,
    this.emailToVerify,
    this.nameToRegister,
    this.errorMessage,
    required this.isInitializing,
    required this.hasCompletedOnboarding,
  });

  const AuthState.initial()
      : status = AuthStatus.unauthenticated,
        userProfile = null,
        technicianProfile = null,
        viewMode = AppViewMode.client,
        emailToVerify = null,
        nameToRegister = null,
        errorMessage = null,
        isInitializing = true,
        hasCompletedOnboarding = false;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    TechnicianProfile? technicianProfile,
    AppViewMode? viewMode,
    String? emailToVerify,
    String? nameToRegister,
    String? errorMessage,
    bool? isInitializing,
    bool? hasCompletedOnboarding,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      technicianProfile: technicianProfile ?? this.technicianProfile,
      viewMode: viewMode ?? this.viewMode,
      emailToVerify: emailToVerify ?? this.emailToVerify,
      nameToRegister: nameToRegister ?? this.nameToRegister,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitializing: isInitializing ?? this.isInitializing,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  static const String _onboardingKey = 'has_completed_onboarding';

  AuthNotifier() : super(const AuthState.initial()) {
    initSession();
  }

  Future<void> initSession() async {
    state = state.copyWith(isInitializing: true);
    try {
      // 1. Check onboarding status
      final onboardingVal = await _storage.read(key: _onboardingKey);
      final hasCompletedOnboarding = onboardingVal == 'true';

      // 2. Check current session
      final userId = await _authService.checkCurrentSession();
      if (userId != null) {
        final profile = await _authService.fetchUserProfile(userId);
        if (profile != null) {
          final techProfile = await _authService.fetchTechnicianProfile(userId);
          
          state = AuthState(
            status: AuthStatus.authenticated,
            userProfile: profile,
            technicianProfile: techProfile,
            viewMode: AppViewMode.client, // Default to client mode on startup
            isInitializing: false,
            hasCompletedOnboarding: true,
            emailToVerify: null,
            nameToRegister: null,
          );
          return;
        }
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isInitializing: false,
        hasCompletedOnboarding: hasCompletedOnboarding,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, isInitializing: false);
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: _onboardingKey, value: 'true');
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final userId = await _authService.login(email, password);
    if (userId != null) {
      final profile = await _authService.fetchUserProfile(userId);
      if (profile != null) {
        final techProfile = await _authService.fetchTechnicianProfile(userId);
        state = AuthState(
          status: AuthStatus.authenticated,
          userProfile: profile,
          technicianProfile: techProfile,
          viewMode: AppViewMode.client, // Login always takes you to client home
          isInitializing: false,
          hasCompletedOnboarding: true,
          emailToVerify: null,
          nameToRegister: null,
        );
        return true;
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'No se pudo cargar el perfil.');
        return false;
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'Correo o contraseña incorrectos.');
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      await _authService.loginWithGoogle();
      // Retornar al estado unauthenticated para liberar la UI mientras abre el navegador externo
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al abrir el inicio de sesión con Google.',
      );
    }
  }

  Future<bool> exchangeOAuthCode(String code) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final data = await _authService.exchangeOAuthCode(code);
      debugPrint('OAuth exchange data: $data');
      if (data != null) {
        final userMap = data['user'] as Map<String, dynamic>?;
        final userId = userMap?['id'] as String? ?? '';
        final email = userMap?['email'] as String? ?? '';
        debugPrint('OAuth user info: userId=$userId, email=$email');

        if (userId.isEmpty) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: 'Respuesta inválida de InsForge.',
          );
          return false;
        }

        // 1. Intentar cargar el perfil
        var profile = await _authService.fetchUserProfile(userId);
        debugPrint('Fetched profile initially: $profile');

        // 2. Si no existe (es la primera vez que ingresa con Google), crearlo
        if (profile == null) {
          final profileMap = userMap?['profile'] as Map<String, dynamic>?;
          final userMeta = (userMap?['userMetadata'] ?? userMap?['user_metadata']) as Map<String, dynamic>?;
          debugPrint('User metadata: $userMeta, Profile metadata: $profileMap');

          final rawName = userMap?['name'] as String? ?? 
                          userMap?['displayName'] as String? ??
                          profileMap?['name'] as String? ??
                          profileMap?['displayName'] as String? ??
                          userMeta?['name'] as String? ?? 
                          userMeta?['fullName'] as String? ??
                          userMeta?['full_name'] as String? ??
                          email.split('@').first;

          final avatarUrl = profileMap?['avatar_url'] as String? ?? 
                            profileMap?['avatarUrl'] as String? ?? 
                            userMeta?['avatar_url'] as String? ?? 
                            userMeta?['avatarUrl'] as String?;

          debugPrint('Creating profile with name: $rawName, avatarUrl: $avatarUrl');
          final created = await _authService.createInitialProfile(userId, email, rawName, avatarUrl: avatarUrl);
          debugPrint('Create profile result: $created');
          if (created) {
            profile = await _authService.fetchUserProfile(userId);
            debugPrint('Fetched profile after creation: $profile');
          }
        }

        if (profile != null) {
          final techProfile = await _authService.fetchTechnicianProfile(userId);
          state = AuthState(
            status: AuthStatus.authenticated,
            userProfile: profile,
            technicianProfile: techProfile,
            viewMode: AppViewMode.client,
            isInitializing: false,
            hasCompletedOnboarding: true,
            emailToVerify: null,
            nameToRegister: null,
          );
          return true;
        }
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'No se pudo verificar la sesión de Google.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Excepción durante el inicio de sesión con Google.',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final success = await _authService.register(email, password, name: name);
    if (success) {
      state = state.copyWith(
        status: AuthStatus.unverified,
        emailToVerify: email,
        nameToRegister: name,
      );
      return true;
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'Error al registrar usuario.');
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final email = state.emailToVerify;
    final name = state.nameToRegister ?? 'Usuario';
    if (email == null) {
      state = state.copyWith(errorMessage: 'No hay correo para verificar.');
      return false;
    }

    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    final userId = await _authService.verifyEmail(email, otp);
    if (userId != null) {
      // 1. Try to fetch user profile
      var profile = await _authService.fetchUserProfile(userId);
      
      // 2. If it does not exist (new user without trigger), create it!
      if (profile == null) {
        final created = await _authService.createInitialProfile(userId, email, name);
        if (created) {
          profile = await _authService.fetchUserProfile(userId);
        }
      }

      if (profile != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          userProfile: profile,
          viewMode: AppViewMode.client,
          isInitializing: false,
          hasCompletedOnboarding: true,
          emailToVerify: null,
          nameToRegister: null,
        );
        return true;
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'No se pudo cargar o crear el perfil verificado.');
        return false;
      }
    } else {
      state = state.copyWith(status: AuthStatus.unverified, errorMessage: 'Código de verificación incorrecto.');
      return false;
    }
  }

  Future<bool> registerAsTechnician({
    required String dni,
    required int districtId,
    required String bio,
    required List<int> categoryIds,
  }) async {
    final user = state.userProfile;
    if (user == null) return false;

    final success = await _authService.createTechnicianProfile(
      user.id,
      dni: dni,
      districtId: districtId,
      bio: bio,
      categoryIds: categoryIds,
    );

    if (success) {
      final updatedProfile = await _authService.fetchUserProfile(user.id);
      final techProfile = await _authService.fetchTechnicianProfile(user.id);
      state = state.copyWith(
        userProfile: updatedProfile,
        technicianProfile: techProfile,
        viewMode: AppViewMode.client, // Keep client mode because verification is pending
      );
      return true;
    }
    return false;
  }

  void toggleViewMode() {
    if (state.userProfile == null || state.technicianProfile == null) return;
    final nextMode = state.viewMode == AppViewMode.client ? AppViewMode.technician : AppViewMode.client;
    state = state.copyWith(viewMode: nextMode);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      userProfile: null,
      technicianProfile: null,
      viewMode: AppViewMode.client,
      isInitializing: false,
      hasCompletedOnboarding: state.hasCompletedOnboarding,
      emailToVerify: null,
      nameToRegister: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
