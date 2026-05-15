import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/responsive/responsive_grid.dart';

/// Pantalla de trabajos del tecnico.
/// Tabs: Activos e Historial.
class TechJobsScreen extends StatelessWidget {
  const TechJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trabajos'),
        centerTitle: false,
      ),
      body: ContentContainer(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTypography.labelLarge,
                tabs: const [
                  Tab(text: 'Activos'),
                  Tab(text: 'Historial'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: TabBarView(
                  children: [
                    _ActiveJobsList(),
                    _JobHistoryList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveJobsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: const [
        _JobCard(
          clientName: 'Juan Perez',
          service: 'Reparacion electrica',
          address: 'Av. Libertador, Caracas',
          status: 'En progreso',
          statusColor: AppColors.info,
          time: 'Iniciado hace 30 min',
          step: 2,
          totalSteps: 4,
        ),
        SizedBox(height: AppSpacing.xs),
        _JobCard(
          clientName: 'Maria Gonzalez',
          service: 'Instalacion de grifo',
          address: 'Las Mercedes, Caracas',
          status: 'En camino',
          statusColor: AppColors.warning,
          time: 'Programado: Hoy 2:00 PM',
          step: 1,
          totalSteps: 4,
        ),
      ],
    );
  }
}

class _JobHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: const [
        _JobCard(
          clientName: 'Pedro Sanchez',
          service: 'Cambio de breaker',
          address: 'Altamira, Caracas',
          status: 'Completado',
          statusColor: AppColors.success,
          time: '12 May 2026',
          price: '\$45',
        ),
        SizedBox(height: AppSpacing.xs),
        _JobCard(
          clientName: 'Laura Diaz',
          service: 'Cableado de oficina',
          address: 'Chacao, Caracas',
          status: 'Completado',
          statusColor: AppColors.success,
          time: '10 May 2026',
          price: '\$180',
        ),
        SizedBox(height: AppSpacing.xs),
        _JobCard(
          clientName: 'Carlos Ruiz',
          service: 'Instalacion de lampara',
          address: 'El Paraiso, Caracas',
          status: 'Completado',
          statusColor: AppColors.success,
          time: '8 May 2026',
          price: '\$25',
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.clientName,
    required this.service,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.time,
    this.price,
    this.step,
    this.totalSteps,
  });

  final String clientName;
  final String service;
  final String address;
  final String status;
  final Color statusColor;
  final String time;
  final String? price;
  final int? step;
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(service, style: AppTypography.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  status,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                clientName,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Progress bar or price
          if (step != null && totalSteps != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: step! / totalSteps!,
                backgroundColor: AppColors.neutral200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paso $step de $totalSteps - $time',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
                if (price != null)
                  Text(
                    price!,
                    style: AppTypography.titleSmall
                        .copyWith(color: AppColors.primary),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
