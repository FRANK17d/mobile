import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../navigation/client_shell.dart';
import '../navigation/technician_shell.dart';

/// Configuracion principal del router de Toke+
/// Usa GoRouter para navegacion declarativa sin flujo de autenticacion.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,

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
