import 'package:flutter/material.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';

/// Tipo de pedido elegido en el selector "Elegí el tipo de pedido".
enum OrderType { basic, exclusive }

/// Abre el bottom sheet "Elegí el tipo de pedido".
///
/// Devuelve el [OrderType] elegido al presionar "Continuar", o `null` si el
/// usuario lo descarta.
Future<OrderType?> showOrderTypeSheet(BuildContext context) {
  return showModalBottomSheet<OrderType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OrderTypeSheet(),
  );
}

class _OrderTypeSheet extends StatefulWidget {
  const _OrderTypeSheet();

  @override
  State<_OrderTypeSheet> createState() => _OrderTypeSheetState();
}

class _OrderTypeSheetState extends State<_OrderTypeSheet> {
  OrderType _selected = OrderType.basic;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottomPadding + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Elegí el tipo de pedido',
            style: AppTypography.headingMedium.copyWith(
              color: const Color(0xFF162033),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _OrderOptionCard(
            asset: AppImages.hiwOrderBasic,
            title: 'Toke+ básico',
            subtitle:
                'Recibirás varias propuestas y elegís con quien trabajar.',
            selected: _selected == OrderType.basic,
            onTap: () => setState(() => _selected = OrderType.basic),
          ),
          const SizedBox(height: AppSpacing.md),
          _OrderOptionCard(
            asset: AppImages.hiwOrderExclusive,
            title: 'Toke+ exclusivo',
            subtitle: 'Propuestas de los mejores prestadores de servicios.',
            badge: '+Seguridad',
            selected: _selected == OrderType.exclusive,
            onTap: () => setState(() => _selected = OrderType.exclusive),
          ),
          const SizedBox(height: AppSpacing.xl),

          GradientPillButton(
            label: 'Continuar',
            onTap: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class _OrderOptionCard extends StatelessWidget {
  const _OrderOptionCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String asset;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // ── Ilustración ──
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.neutral100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.handyman_outlined,
                    color: AppColors.neutral400,
                    size: 34,
                  ),
                ),
              ),
            ),
            // ── Texto ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSmall.copyWith(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFF162033),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF5F6678),
                        height: 1.35,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        badge!,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
