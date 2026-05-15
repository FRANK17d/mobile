import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_grid.dart';

/// Dashboard del tecnico.
/// Muestra estadisticas, ganancias y solicitudes pendientes.
class TechDashboardScreen extends StatelessWidget {
  const TechDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: breakpoint.screenPadding,
          ),
          child: ContentContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: AppTypography.headingLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Resumen de tu actividad',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Profile avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutral200,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.neutral400,
                        size: 24,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // Stats cards
                _StatsRow(breakpoint: breakpoint),

                const SizedBox(height: AppSpacing.xl),

                // Earnings summary
                _EarningsSummary()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // Pending requests
                _PendingRequests()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.breakpoint});

  final Breakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final stats = [
      const _StatData('Trabajos hoy', '3', Icons.work_rounded, AppColors.primary),
      const _StatData('Pendientes', '5', Icons.pending_actions_rounded, AppColors.warning),
      const _StatData('Completados', '127', Icons.check_circle_rounded, AppColors.success),
      const _StatData('Rating', '4.8', Icons.star_rounded, AppColors.starFilled),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: breakpoint.isMobile ? 2 : 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: breakpoint.isMobile ? 1.6 : 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _StatCard(data: stats[index])
            .animate()
            .fadeIn(duration: 400.ms, delay: (100 * index).ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
            );
      },
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppTypography.headingMedium,
              ),
              Text(
                data.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF6B42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ganancias del mes',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textInverse.withValues(alpha: 0.8),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver detalle',
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$1,250.00',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: AppColors.textInverse,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '12% vs mes anterior',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Solicitudes pendientes', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'Ver todas',
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _RequestCard(
          clientName: 'Juan Perez',
          service: 'Reparacion electrica',
          location: 'Av. Libertador, Caracas',
          timeAgo: 'Hace 5 min',
          urgency: 'Urgente',
        ),
        const SizedBox(height: AppSpacing.xs),
        _RequestCard(
          clientName: 'Ana Martinez',
          service: 'Instalacion de tomacorriente',
          location: 'Las Mercedes, Caracas',
          timeAgo: 'Hace 15 min',
        ),
        const SizedBox(height: AppSpacing.xs),
        _RequestCard(
          clientName: 'Pedro Gomez',
          service: 'Revision de tablero electrico',
          location: 'Altamira, Caracas',
          timeAgo: 'Hace 30 min',
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.clientName,
    required this.service,
    required this.location,
    required this.timeAgo,
    this.urgency,
  });

  final String clientName;
  final String service;
  final String location;
  final String timeAgo;
  final String? urgency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral200,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.neutral400,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientName,
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (urgency != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          urgency!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  service,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
