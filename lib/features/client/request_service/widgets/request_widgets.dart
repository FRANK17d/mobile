import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Color de los segmentos de progreso aún no completados.
const Color _kProgressEmpty = Color(0xFFD9E2EC);

/// Barra de progreso por pasos del flujo "Pedir un servicio".
///
/// Dibuja [total] segmentos redondeados; los primeros [current] van en color
/// primario (completados/actual) y el resto en gris-azulado.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.total,
    required this.current,
  });

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < current;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : AppSpacing.xs),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : _kProgressEmpty,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
        );
      }),
    );
  }
}

/// Pequeño signo de interrogación a la derecha de los títulos (ayuda).
///
/// Al tocarlo despliega un "avisito" (tooltip) animado con [message], anclado
/// debajo del ícono. Se cierra al tocar fuera.
class HelpBadge extends StatefulWidget {
  const HelpBadge({super.key, this.message});

  /// Texto del avisito de ayuda. Si es null usa un texto genérico.
  final String? message;

  @override
  State<HelpBadge> createState() => _HelpBadgeState();
}

class _HelpBadgeState extends State<HelpBadge>
    with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _removeNow();
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() => _entry == null ? _show() : _hide();

  void _show() {
    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Barrera para cerrar al tocar fuera.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hide,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(6, 8),
            child: FadeTransition(
              opacity: _ctrl,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.topRight,
                child: _TooltipBubble(
                  message: widget.message ?? 'Información de ayuda.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    _ctrl.forward(from: 0);
  }

  void _hide() {
    if (_entry == null) return;
    _ctrl.reverse().whenComplete(_removeNow);
  }

  void _removeNow() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            '?',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Burbuja del avisito de ayuda.
class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D2939),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip seleccionable (single o multi-select) con estilo Toke+.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Cuando es true se adapta a ocupar el ancho disponible (para usarse dentro
  /// de un [Expanded] en una fila de varios chips), con texto centrado y
  /// padding horizontal compacto.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: expand ? AppSpacing.sm : AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: expand ? TextAlign.center : TextAlign.start,
          style: AppTypography.titleMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Fila con checkbox cuadrado redondeado + etiqueta (+ ayuda opcional).
class CheckTile extends StatelessWidget {
  const CheckTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.showHelp = false,
    this.helpMessage,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool showHelp;
  final String? helpMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: value ? AppColors.primarySurface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showHelp) HelpBadge(message: helpMessage),
      ],
    );
  }
}

/// Barra inferior fija con el botón de acción principal del flujo.
class RequestBottomBar extends StatelessWidget {
  const RequestBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Campo con estilo de "select" (no editable) que muestra un valor y un chevron.
/// Sin lógica de selección todavía: solo presentación.
class FakeSelectField extends StatelessWidget {
  const FakeSelectField({super.key, required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSpacing.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
