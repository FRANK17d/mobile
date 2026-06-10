import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Abre el menu como vista full-screen.
/// Se usa desde el boton hamburguesa, perfil tab, etc.
void showAppMenuSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _AppMenuFullScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

class _AppMenuFullScreen extends StatelessWidget {
  const _AppMenuFullScreen();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Header: X + Pedir servicio ──
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Boton cerrar
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  // Boton CTA
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a pedir servicio
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Pedir servicio',
                        style: AppTypography.buttonMedium.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Divider sutil ──
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.neutral200,
            ),

            const SizedBox(height: 16),

            // ── Contenido scrolleable ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // ── Seccion auth (fondo azul claro) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.login_rounded,
                          label: 'Iniciar sesión',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.login);
                          },
                        ),
                        const SizedBox(height: 4),
                        _MenuTile(
                          icon: Icons.person_add_outlined,
                          label: 'Únete a Toke+',
                          onTap: () {
                            Navigator.of(context).pop();
                            // TODO: navegar a registro
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Navegacion principal ──
                  _MenuTile(
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a inicio
                    },
                  ),
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pedidos',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a pedidos
                    },
                  ),
                  _MenuTile(
                    icon: Icons.layers_outlined,
                    label: 'Servicios',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a servicios
                    },
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Descubrir',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6B7280),
                      size: 22,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a descubrir
                    },
                  ),
                  _MenuTile(
                    icon: Icons.share_outlined,
                    label: 'Compartir',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: compartir app
                    },
                  ),
                  _MenuTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Donar',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a donar
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Seccion legal ──
                  _MenuTile(
                    icon: Icons.description_outlined,
                    label: 'Términos y condiciones',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: abrir terminos
                    },
                  ),
                  _MenuTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Política de privacidad',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: abrir privacidad
                    },
                  ),
                  _MenuTile(
                    icon: Icons.language_rounded,
                    label: 'Nuestro sitio web',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: abrir sitio web
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Version ──
                  Center(
                    child: Text(
                      'Versión 1.0.0',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile individual del menu.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF374151)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleLarge.copyWith(
                  color: const Color(0xFF1D2939),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
