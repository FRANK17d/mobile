import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/service_card.dart';

/// Lista horizontal de tecnicos cercanos.
class NearbyTechnicians extends StatelessWidget {
  const NearbyTechnicians({super.key, this.onViewAll, this.onTechnicianTap});

  final VoidCallback? onViewAll;
  final void Function(String id)? onTechnicianTap;

  // Datos mock
  static const _mockTechnicians = [
    _TechData('Carlos Rodriguez', 'Electricista', 4.8, 124, '1.2 km', '\$25/h'),
    _TechData('Maria Gonzalez', 'Plomera', 4.9, 89, '2.0 km', '\$30/h'),
    _TechData('Jose Martinez', 'Cerrajero', 4.7, 56, '0.8 km', '\$20/h'),
    _TechData('Ana Lopez', 'Pintora', 4.6, 78, '3.1 km', '\$22/h'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tecnicos cercanos',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'Ver todos',
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mockTechnicians.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final tech = _mockTechnicians[index];
            return TechnicianCard(
              name: tech.name,
              specialty: tech.specialty,
              rating: tech.rating,
              reviewCount: tech.reviewCount,
              imageUrl: '',
              distance: tech.distance,
              price: tech.price,
              onTap: () => onTechnicianTap?.call('tech_$index'),
            );
          },
        ),
      ],
    );
  }
}

class _TechData {
  const _TechData(
    this.name,
    this.specialty,
    this.rating,
    this.reviewCount,
    this.distance,
    this.price,
  );

  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String distance;
  final String price;
}
