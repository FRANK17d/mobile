import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Modelo de un slot de tiempo disponible.
class TimeSlot {
  const TimeSlot({
    required this.label,
    required this.startHour,
    required this.startMinute,
  });

  final String label;
  final int startHour;
  final int startMinute;
}

/// Slots predeterminados del sistema de booking.
const List<TimeSlot> defaultTimeSlots = [
  TimeSlot(label: '8:00 - 10:00', startHour: 8, startMinute: 0),
  TimeSlot(label: '10:00 - 12:00', startHour: 10, startMinute: 0),
  TimeSlot(label: '12:00 - 14:00', startHour: 12, startMinute: 0),
  TimeSlot(label: '14:00 - 16:00', startHour: 14, startMinute: 0),
  TimeSlot(label: '16:00 - 18:00', startHour: 16, startMinute: 0),
  TimeSlot(label: '18:00 - 20:00', startHour: 18, startMinute: 0),
];

/// Widget que muestra los horarios disponibles como chips seleccionables.
class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.selectedIndex,
    required this.onSlotSelected,
  });

  final List<TimeSlot> slots;
  final int? selectedIndex;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(slots.length, (index) {
        final slot = slots[index];
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () => onSlotSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  slot.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
