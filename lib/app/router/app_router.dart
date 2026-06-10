import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/oauth_callback_screen.dart';
import '../../features/profile/screens/tech_registration_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../navigation/client_shell.dart';
import '../navigation/technician_shell.dart';

/// Helper to convert a stream into a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider que expone la configuración del router de Toke+.
/// Se enlaza dinámicamente con el estado de autenticación.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      debugPrint('GoRouter redirect: matchedLocation=${state.matchedLocation}, uri=${state.uri}');

      // Si la app se está inicializando (cargando sesión persistente), no redirigir
      if (authState.isInitializing) return null;

      // Interceptar callback de Google OAuth (esquema personalizado tokeplus://callback)
      if (state.uri.host == 'callback') {
        final code = state.uri.queryParameters['insforge_code'];
        debugPrint('GoRouter redirect: OAuth callback host detected, redirecting to: ${AppRoutes.oauthCallback}?insforge_code=$code');
        return '${AppRoutes.oauthCallback}?insforge_code=$code';
      }

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isUnverified = authState.status == AuthStatus.unverified;

      // Rutas públicas de autenticación y onboarding
      final isGoingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.oauthCallback;

      // 1. Caso: Usuario no verificado (OTP pendiente)
      if (isUnverified && state.matchedLocation != AppRoutes.otp) {
        return AppRoutes.otp;
      }

      // 2. Caso: Usuario no autenticado
      if (!isLoggedIn) {
        // Si no está logueado e intenta acceder a una ruta protegida
        if (!isGoingToAuth) {
          return AppRoutes.login;
        }
        return null;
      }

      // 3. Caso: Usuario autenticado intentando entrar a pantallas de Auth/Splash
      if (isGoingToAuth) {
        if (authState.viewMode == AppViewMode.technician) {
          return AppRoutes.techHome;
        } else {
          return AppRoutes.clientHome;
        }
      }

      return null;
    },

    routes: [
      // ─── Splash ───
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
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

      // ─── Autenticación ───
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) => const OTPScreen(),
      ),
      GoRoute(
        path: AppRoutes.oauthCallback,
        name: 'callback',
        builder: (context, state) {
          final code = state.uri.queryParameters['insforge_code'];
          return OAuthCallbackScreen(code: code);
        },
      ),

      // ─── Registro Técnico (Conversión de rol) ───
      GoRoute(
        path: AppRoutes.becomeTechnician,
        name: 'becomeTechnician',
        builder: (context, state) => const TechRegistrationScreen(),
      ),

      // ─── Client Shell ───
      GoRoute(
        path: AppRoutes.clientHome,
        name: 'clientHome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ClientShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
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
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
    ],
  );
});
