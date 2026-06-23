import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/auth_store.dart';

/// Muestra la pantalla de cierre de sesión (logo T+ con animación suave) por
/// encima de todo, ejecuta el logout y devuelve al home como no autenticado.
///
/// Sirve tanto desde el perfil del cliente como desde el menú del técnico: la
/// propia pantalla limpia el stack imperativo (overlay + menú) antes de
/// navegar, así que quien la invoca solo necesita llamar a este helper.
void showLogoutTransition(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, _, _) => const LogoutTransitionScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

/// Vista de transición de cierre de sesión: logo Toke+ con un latido suave
/// mientras se cierra la sesión.
class LogoutTransitionScreen extends StatefulWidget {
  const LogoutTransitionScreen({super.key});

  @override
  State<LogoutTransitionScreen> createState() => _LogoutTransitionScreenState();
}

class _LogoutTransitionScreenState extends State<LogoutTransitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _run();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final nav = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);

    // Cierra sesión y respeta una duración mínima para que la animación suave
    // se aprecie (en lugar de un parpadeo).
    await Future.wait<void>([
      _logout(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);

    if (!mounted) return;

    // Quita el overlay (y el menú, si venimos de él) y vuelve al home como
    // usuario no autenticado.
    nav.popUntil((route) => route.isFirst);
    router.go(AppRoutes.clientHome);
  }

  Future<void> _logout() async {
    await AuthService().logout();
    AuthStore.instance.setUnauthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        // Bloquea el botón atrás mientras se cierra la sesión.
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo con latido suave ──
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_pulse.value);
                    return Transform.scale(
                      scale: 0.94 + 0.12 * t,
                      child: Opacity(opacity: 0.82 + 0.18 * t, child: child),
                    );
                  },
                  child: Image.asset(
                    AppImages.logo,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Cerrando sesión…',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
