import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Header del home: logo SVG toke+ en blanco.
///
/// Cuando [isAuthenticated] es false: muestra botón "Entrar" + menú hamburguesa.
/// Cuando [isAuthenticated] es true: muestra campana de notificaciones + menú hamburguesa.
class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    this.onLoginTap,
    this.onMenuTap,
    this.onNotificationTap,
    this.isAuthenticated = false,
  });

  final VoidCallback? onLoginTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // ── Logo SVG toke+ en blanco ──
          SvgPicture.asset(
            AppImages.logoTextSvg,
            height: 36,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),

          const Spacer(),

          if (isAuthenticated) ...[
            // ── Campana de notificaciones ──
            _HeaderIconButton(
              icon: Icons.notifications_outlined,
              onTap: onNotificationTap,
            ),
            const SizedBox(width: 10),
            // ── Menu hamburguesa ──
            _HeaderIconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
          ] else ...[
            // ── Boton "Entrar" (usuario no autenticado) ──
            GestureDetector(
              onTap: onLoginTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Entrar',
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Menu hamburguesa ──
            _HeaderIconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(child: Icon(icon, size: 22, color: Colors.white)),
      ),
    );
  }
}
