import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../client/home/widgets/home_mascot.dart';

/// Prompt "¿Tenés una cuenta?" que aparece al pedir un servicio sin sesión.
/// "Sí, tengo" lleva al login; "No, soy nuevo por aquí" al registro
/// (donde se elige cliente o técnico).
class AccountPromptScreen extends StatelessWidget {
  const AccountPromptScreen({super.key});

  /// Cierra todas las rutas "crudas" (este prompt + menú/detalle/etc.) hasta el
  /// shell go_router y recién entonces navega a la ruta de auth. Evita mezclar
  /// rutas imperativas con go_router (que dejaría la pantalla de login debajo).
  void _leave(BuildContext context, String route) {
    final nav = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    nav.popUntil((r) => r.isFirst);
    router.push(route);
  }

  void _goLogin(BuildContext context) => _leave(context, AppRoutes.login);

  void _goRegister(BuildContext context) => _leave(context, AppRoutes.register);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF454F5E), Color(0xFF2B333F)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // ── Cerrar ──
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  Text(
                    '¿Tenés una cuenta?',
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // ── Mascota Toke+ ──
                  const HomeMascot(size: 180),

                  const Spacer(flex: 2),

                  // ── Botones ──
                  _PromptButton(
                    label: 'Sí, tengo',
                    onTap: () => _goLogin(context),
                  ),
                  const SizedBox(height: 12),
                  _PromptButton(
                    label: 'No, soy nuevo por aquí',
                    onTap: () => _goRegister(context),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón blanco redondeado del prompt.
class _PromptButton extends StatelessWidget {
  const _PromptButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF1D2939),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
