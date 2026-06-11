import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Banner de promocion horizontal con scroll.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ofertas especiales', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: const [
              _PromoCard(
                title: '20% OFF',
                subtitle: 'En tu primer servicio de electricidad',
                gradient: [Color(0xFFE8461E), Color(0xFFFF6B42)],
                icon: Icons.electrical_services_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _PromoCard(
                title: 'Gratis',
                subtitle: 'Diagnostico de plomeria este mes',
                gradient: [Color(0xFF1A2B4A), Color(0xFF2D4470)],
                icon: Icons.plumbing_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _PromoCard(
                title: '15% OFF',
                subtitle: 'Servicio de limpieza profunda',
                gradient: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                icon: Icons.cleaning_services_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            icon,
            size: 48,
            color: AppColors.textInverse.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
