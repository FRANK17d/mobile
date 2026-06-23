import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../web/in_app_web_view_screen.dart';
import '../../../features/auth/screens/account_prompt_screen.dart';
import '../../../features/auth/services/auth_store.dart';
import '../../../features/client/explore/screens/explore_screen.dart';
import '../../../features/client/orders/screens/public_requests_screen.dart';
import '../../../features/client/request_service/screens/request_service_wizard_screen.dart';

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
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
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

  /// "Pedir servicio": con sesión abre el wizard; sin sesión, el prompt de
  /// cuenta (¿Tenés una cuenta?).
  void _onRequestService(BuildContext context) {
    final authed = AuthStore.instance.value.isAuthenticated;
    // Se apila ENCIMA del menú: al retroceder se vuelve al menú.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => authed
            ? const RequestServiceWizardScreen()
            : const AccountPromptScreen(),
      ),
    );
  }

  /// Empuja una pantalla ENCIMA del menú (no go_router): al retroceder vuelve
  /// al menú hamburguesa.
  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  /// Navega a una ruta go_router tras cerrar el menú.
  void _goRoute(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
  }

  void _openWebView(BuildContext context, String url, String title) {
    _pushScreen(context, InAppWebViewScreen(url: url, title: title));
  }

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
                    onTap: () => _onRequestService(context),
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
                          onTap: () => _goRoute(context, AppRoutes.login),
                        ),
                        const SizedBox(height: 4),
                        _MenuTile(
                          icon: Icons.person_add_outlined,
                          label: 'Únete a Toke+',
                          onTap: () => _goRoute(context, AppRoutes.register),
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
                    onTap: () => _pushScreen(context, const PublicRequestsScreen()),
                  ),
                  _MenuTile(
                    icon: Icons.layers_outlined,
                    label: 'Servicios',
                    onTap: () => _pushScreen(context, const ExploreScreen()),
                  ),
                  _MenuTile(
                    icon: Icons.share_outlined,
                    label: 'Compartir',
                    onTap: () {
                      // No cerramos el menú: la hoja de compartir es del
                      // sistema y al cerrarla se vuelve al menú.
                      SharePlus.instance.share(
                        ShareParams(text: AppStrings.shareMessage),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Seccion legal ──
                  _MenuTile(
                    icon: Icons.description_outlined,
                    label: 'Términos y condiciones',
                    onTap: () => _openWebView(
                      context,
                      'https://tokeplus.app/terminos',
                      'Términos y condiciones',
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Política de privacidad',
                    onTap: () => _openWebView(
                      context,
                      'https://tokeplus.app/privacidad',
                      'Política de privacidad',
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.language_rounded,
                    label: 'Nuestro sitio web',
                    onTap: () => _openWebView(
                      context,
                      'https://tokeplus.app',
                      'Toke+',
                    ),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
          ],
        ),
      ),
    );
  }
}
