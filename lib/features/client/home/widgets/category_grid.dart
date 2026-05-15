import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/responsive/breakpoints.dart';

/// Grid de categorias de servicios.
/// Adaptivo: 2 columnas en movil, 3-4 en tablet.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, this.onCategoryTap});

  final void Function(String category)? onCategoryTap;

  static const _categories = [
    _CategoryData('Electricidad', Icons.electrical_services_rounded, Color(0xFFFFF3E0), Color(0xFFFF9800)),
    _CategoryData('Plomeria', Icons.plumbing_rounded, Color(0xFFE3F2FD), Color(0xFF2196F3)),
    _CategoryData('Cerrajeria', Icons.lock_rounded, Color(0xFFFCE4EC), Color(0xFFE91E63)),
    _CategoryData('Pintura', Icons.format_paint_rounded, Color(0xFFE8F5E9), Color(0xFF4CAF50)),
    _CategoryData('Limpieza', Icons.cleaning_services_rounded, Color(0xFFE0F7FA), Color(0xFF00BCD4)),
    _CategoryData('Carpinteria', Icons.handyman_rounded, Color(0xFFFFF8E1), Color(0xFFFFC107)),
    _CategoryData('A/C', Icons.ac_unit_rounded, Color(0xFFE8EAF6), Color(0xFF3F51B5)),
    _CategoryData('Mas', Icons.grid_view_rounded, Color(0xFFF3E5F5), Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);
    final columns = breakpoint.gridColumns;
    final spacing = breakpoint.isMobile ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: breakpoint.isMobile ? 1.1 : 1.2,
          ),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return _CategoryItem(
              data: cat,
              onTap: () => onCategoryTap?.call(cat.name),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryData {
  const _CategoryData(this.name, this.icon, this.bgColor, this.iconColor);
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.data, this.onTap});

  final _CategoryData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                data.icon,
                color: data.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.name,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
