import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Item de navegacion para el bottom nav bar personalizado.
class NavBarItem {
  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.customWidget,
    this.activeCustomWidget,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget? customWidget;
  final Widget? activeCustomWidget;
}

/// Bottom Navigation Bar personalizado estilo floating con pill indicator.
///
/// Diseño: barra flotante con bordes redondeados, indicador pill
/// en el item activo con fondo suave, color rojo suave para el estado activo.
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  // Color activo: rojo suave
  static const Color _activeColor = Color(0xFFD94F4F);
  static const Color _activeBgColor = Color(0xFFFEECEC);
  static const Color _inactiveColor = Color(0xFF2E3A4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = index == currentIndex;
          return _NavBarItemWidget(
            item: items[index],
            isActive: isActive,
            onTap: () => onTap(index),
          );
        }),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  const _NavBarItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavBarItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? CustomBottomNavBar._activeColor
        : CustomBottomNavBar._inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono con pill indicator si esta activo
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? CustomBottomNavBar._activeBgColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: item.customWidget != null
                  ? (isActive
                        ? (item.activeCustomWidget ?? item.customWidget!)
                        : item.customWidget!)
                  : Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
