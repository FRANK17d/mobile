import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/account_type_screen.dart';
import '../../features/auth/screens/client_registration_screen.dart';
import '../../features/auth/screens/become_provider_screen.dart';
import '../../features/auth/screens/provider_registration_screen.dart';
import '../../features/auth/screens/registration_processing_screen.dart';
import '../../features/auth/screens/registration_otp_screen.dart';
import '../../features/auth/screens/registration_success_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/auth_processing_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/support/screens/ai_support_screen.dart';
import '../navigation/client_shell.dart';
import '../navigation/technician_shell.dart';

/// Configuracion principal del router de Toke+
/// Usa GoRouter para navegacion declarativa sin flujo de autenticacion.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: kDebugMode,

  // Red de seguridad: ante cualquier navegación fallida (ruta inexistente,
  // deep link inesperado, etc.) volvemos al splash en vez de pantalla en negro.
  onException: (context, state, router) => router.go(AppRoutes.splash),

  routes: [
    // ─── Splash ───
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ─── Auth: pantalla de carga (callback OAuth de Google) ───
    GoRoute(
      path: AppRoutes.authProcessing,
      name: 'authProcessing',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthProcessingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    ),

    // ─── Onboarding ───
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    ),

    // ─── Login ───
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Registro: Seleccion tipo de cuenta ───
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AccountTypeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Registro: Formulario cliente (3 pasos) ───
    GoRoute(
      path: '/register/client',
      name: 'registerClient',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ClientRegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Registro: Formulario prestador (5 pasos) ───
    GoRoute(
      path: '/register/provider',
      name: 'registerProvider',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProviderRegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Cliente → Prestador: conversión de la cuenta actual ───
    GoRoute(
      path: '/become-provider',
      name: 'becomeProvider',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BecomeProviderScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Registro: Procesando ───
    GoRoute(
      path: '/register/processing',
      name: 'registerProcessing',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: RegistrationProcessingScreen(
          registrationData: state.extra as Map<String, dynamic>?,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // ─── Registro: Verificación OTP (técnico) ───
    GoRoute(
      path: '/register/otp',
      name: 'registerOtp',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: RegistrationOtpScreen(
            email: extra['email'] as String? ?? '',
            registrationData:
                extra['registrationData'] as Map<String, dynamic>? ?? {},
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),

    // ─── Registro: Exito ───
    GoRoute(
      path: '/register/success',
      name: 'registerSuccess',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: RegistrationSuccessScreen(
          role: state.extra as String? ?? 'client',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // ─── Recuperar contraseña ───
    GoRoute(
      path: '/forgot-password',
      name: 'forgotPassword',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── OTP Verificacion ───
    GoRoute(
      path: '/forgot-password/otp',
      name: 'forgotPasswordOtp',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: OtpVerificationScreen(email: state.extra as String? ?? ''),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Nueva contraseña ───
    GoRoute(
      path: '/forgot-password/new-password',
      name: 'forgotPasswordNewPassword',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final resetToken = extra is Map<String, dynamic>
            ? extra['resetToken'] as String? ?? ''
            : '';

        return CustomTransitionPage(
          key: state.pageKey,
          child: NewPasswordScreen(resetToken: resetToken),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    ),

    // ─── Contraseña actualizada exitosamente ───
    GoRoute(
      path: '/forgot-password/success',
      name: 'forgotPasswordSuccess',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PasswordResetSuccessScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // ─── Soporte compartido ───
    GoRoute(
      path: AppRoutes.support,
      name: 'support',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiSupportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Ajustes ───
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // ─── Client Shell ───
    GoRoute(
      path: AppRoutes.clientHome,
      name: 'clientHome',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ClientShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    ),

    // ─── Technician Shell ───
    GoRoute(
      path: AppRoutes.techHome,
      name: 'techHome',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const TechnicianShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    ),
  ],
);
