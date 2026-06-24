import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Paso individual del timeline.
class _TrackingStep {
  const _TrackingStep({
    required this.key,
    required this.label,
    required this.icon,
    this.timestamp,
  });

  final String key;
  final String label;
  final IconData icon;
  final DateTime? timestamp;
}

/// Pantalla de seguimiento visual (timeline vertical) de un pedido.
///
/// Recibe el [requestId] y el [currentStatus] del pedido. No hace llamadas
/// a backend — simplemente mapea el status al paso correspondiente.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    required this.requestId,
    required this.currentStatus,
    this.timestamps,
  });

  /// UUID del pedido (para titulo / referencia).
  final String requestId;

  /// Status actual del pedido (slug).
  final String currentStatus;

  /// Timestamps opcionales por slug del paso.
  /// Ej: {'open': DateTime(...), 'in_review': DateTime(...)}
  final Map<String, DateTime>? timestamps;

  // ── Definicion de pasos del flujo normal ──
  static const List<_StepDef> _normalFlow = [
    _StepDef(key: 'open', label: 'Publicado', icon: Icons.publish_rounded),
    _StepDef(
      key: 'in_review',
      label: 'En revisión',
      icon: Icons.hourglass_top_rounded,
    ),
    _StepDef(
      key: 'approved',
      label: 'Aprobado',
      icon: Icons.check_circle_outline_rounded,
    ),
    _StepDef(
      key: 'assigned',
      label: 'Técnico asignado',
      icon: Icons.person_add_alt_1_rounded,
    ),
    _StepDef(
      key: 'in_progress',
      label: 'En progreso',
      icon: Icons.build_rounded,
    ),
    _StepDef(
      key: 'completed',
      label: 'Completado',
      icon: Icons.task_alt_rounded,
    ),
  ];

  // Pasos terminales negativos.
  static const _StepDef _cancelledStep = _StepDef(
    key: 'cancelled',
    label: 'Cancelado',
    icon: Icons.cancel_rounded,
  );
  static const _StepDef _rejectedStep = _StepDef(
    key: 'rejected',
    label: 'Rechazado',
    icon: Icons.block_rounded,
  );

  /// Construye la lista de pasos en base al status actual.
  List<_TrackingStep> _buildSteps() {
    final isNegativeEnd =
        currentStatus == 'cancelled' || currentStatus == 'rejected';

    // Indice del paso actual en el flujo normal.
    int currentIndex = _normalFlow.indexWhere((s) => s.key == currentStatus);

    // Si es un estado negativo, mostramos hasta el ultimo paso alcanzado
    // y agregamos el paso negativo al final.
    if (isNegativeEnd) {
      // Encontramos cuantos pasos se alcanzaron antes de la cancelacion.
      // Si no podemos determinarlo, asumimos que el ultimo es 'open'.
      currentIndex = 0; // al menos se publicó
      // Buscar en timestamps el paso más avanzado.
      if (timestamps != null) {
        for (int i = _normalFlow.length - 1; i >= 0; i--) {
          if (timestamps!.containsKey(_normalFlow[i].key)) {
            currentIndex = i;
            break;
          }
        }
      }
    } else if (currentIndex < 0) {
      // Status desconocido: mostrar todo como pendiente.
      currentIndex = -1;
    }

    final steps = <_TrackingStep>[];
    for (int i = 0; i < _normalFlow.length; i++) {
      final def = _normalFlow[i];
      // Si hay un final negativo, solo mostramos hasta el paso alcanzado.
      if (isNegativeEnd && i > currentIndex) break;
      steps.add(
        _TrackingStep(
          key: def.key,
          label: def.label,
          icon: def.icon,
          timestamp: timestamps?[def.key],
        ),
      );
    }

    // Agregar paso negativo.
    if (isNegativeEnd) {
      final negDef = currentStatus == 'cancelled'
          ? _cancelledStep
          : _rejectedStep;
      steps.add(
        _TrackingStep(
          key: negDef.key,
          label: negDef.label,
          icon: negDef.icon,
          timestamp: timestamps?[negDef.key],
        ),
      );
    }

    return steps;
  }

  /// Determina el indice del paso activo.
  int _activeIndex(List<_TrackingStep> steps) {
    final idx = steps.indexWhere((s) => s.key == currentStatus);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final activeIdx = _activeIndex(steps);
    final isNegativeEnd =
        currentStatus == 'cancelled' || currentStatus == 'rejected';
    final shortId = requestId.replaceAll('-', '').substring(0, 6).toUpperCase();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Seguimiento',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado con referencia ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #$shortId',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _statusLabel(currentStatus),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isNegativeEnd
                            ? AppColors.error
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Timeline ──
              ...List.generate(steps.length, (i) {
                final step = steps[i];
                final isActive = i == activeIdx;
                final isPast = i < activeIdx;
                final isFuture = i > activeIdx;
                final isLast = i == steps.length - 1;
                final isNegStep =
                    step.key == 'cancelled' || step.key == 'rejected';

                return _TimelineItem(
                  step: step,
                  isActive: isActive,
                  isPast: isPast,
                  isFuture: isFuture,
                  isLast: isLast,
                  isNegative: isNegStep,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'open' => 'Publicado',
      'in_review' => 'En revisión',
      'approved' => 'Aprobado',
      'assigned' => 'Técnico asignado',
      'in_progress' => 'En progreso',
      'completed' => 'Completado',
      'cancelled' => 'Cancelado',
      'rejected' => 'Rechazado',
      _ => status,
    };
  }
}

// ─────────────────────────────────────────────────────────
// Definición interna de paso (constante)
// ─────────────────────────────────────────────────────────
class _StepDef {
  const _StepDef({required this.key, required this.label, required this.icon});

  final String key;
  final String label;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────
// Widget de un ítem del timeline
// ─────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.step,
    required this.isActive,
    required this.isPast,
    required this.isFuture,
    required this.isLast,
    required this.isNegative,
  });

  final _TrackingStep step;
  final bool isActive;
  final bool isPast;
  final bool isFuture;
  final bool isLast;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    // Colores segun estado
    final Color dotColor;
    final Color lineColor;
    final Color iconColor;
    final Color labelColor;
    final FontWeight labelWeight;

    if (isNegative) {
      dotColor = AppColors.error;
      lineColor = AppColors.error.withValues(alpha: 0.3);
      iconColor = AppColors.textInverse;
      labelColor = AppColors.error;
      labelWeight = FontWeight.w700;
    } else if (isActive) {
      dotColor = AppColors.primary;
      lineColor = AppColors.primary.withValues(alpha: 0.3);
      iconColor = AppColors.textInverse;
      labelColor = AppColors.primary;
      labelWeight = FontWeight.w700;
    } else if (isPast) {
      dotColor = AppColors.success;
      lineColor = AppColors.success.withValues(alpha: 0.5);
      iconColor = AppColors.textInverse;
      labelColor = AppColors.textPrimary;
      labelWeight = FontWeight.w500;
    } else {
      // Futuro
      dotColor = AppColors.neutral300;
      lineColor = AppColors.neutral300;
      iconColor = AppColors.neutral500;
      labelColor = AppColors.textTertiary;
      labelWeight = FontWeight.w400;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linea + punto ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: isActive || isNegative ? 36 : 30,
                  height: isActive || isNegative ? 36 : 30,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: isActive || isNegative
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    step.icon,
                    size: isActive || isNegative ? 18 : 16,
                    color: iconColor,
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Label + timestamp ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.lg,
                top: (isActive || isNegative) ? 6 : 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTypography.titleLarge.copyWith(
                      color: labelColor,
                      fontWeight: labelWeight,
                    ),
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      _formatTimestamp(step.timestamp!),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }
}
