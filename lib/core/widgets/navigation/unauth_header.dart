import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../theme/app_typography.dart';
import 'app_menu_sheet.dart';

/// Header oscuro reutilizable para las vistas sin sesión (Pedidos, Mensajes…):
/// título + botón "Entrar" + botón de menú. Opcionalmente, una barra de
/// búsqueda debajo (cuando se pasa [searchHint]).
class UnauthHeader extends StatelessWidget {
  const UnauthHeader({
    super.key,
    required this.title,
    this.searchHint,
    this.onSearchTap,
  });

  final String title;

  /// Si no es null, muestra la barra de búsqueda con este texto guía.
  final String? searchHint;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(color: Color(0xFF1D2939)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _EntrarButton(onTap: () => context.push(AppRoutes.login)),
              const SizedBox(width: 10),
              _MenuButton(onTap: () => showAppMenuSheet(context)),
            ],
          ),
          if (searchHint != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3B4F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        searchHint!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntrarButton extends StatelessWidget {
  const _EntrarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Entrar',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}
