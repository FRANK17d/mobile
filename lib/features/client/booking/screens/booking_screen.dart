import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../services/booking_service.dart';
import '../widgets/time_slot_picker.dart';

/// Pantalla de agendamiento de horario para un pedido de servicio.
///
/// Permite al cliente seleccionar fecha y franja horaria para la visita
/// del técnico confirmado.
class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.requestId,
    required this.technicianName,
    this.technicianId,
  });

  final String requestId;
  final String technicianName;
  final String? technicianId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int? _selectedSlotIndex;
  bool _isLoading = false;

  /// Fecha mínima: mañana.
  DateTime get _minDate =>
      DateTime.now().add(const Duration(days: 1));

  /// Fecha máxima: 30 días a futuro.
  DateTime get _maxDate =>
      DateTime.now().add(const Duration(days: 30));

  bool get _canConfirm => _selectedSlotIndex != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Agendar horario',
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                  vertical: AppSpacing.sectionGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Technician Info Card ──
                    _buildTechnicianCard(),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Date Selection ──
                    _buildSectionHeader(
                      icon: Icons.calendar_today_rounded,
                      title: 'Selecciona la fecha',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDateSelector(),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Time Slot Selection ──
                    _buildSectionHeader(
                      icon: Icons.schedule_rounded,
                      title: 'Selecciona el horario',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Elige la franja horaria que mejor te convenga.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TimeSlotPicker(
                      slots: defaultTimeSlots,
                      selectedIndex: _selectedSlotIndex,
                      onSlotSelected: (index) {
                        setState(() => _selectedSlotIndex = index);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Summary ──
                    if (_canConfirm) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),

            // ── Confirm Button ──
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTechnicianCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.technicianName,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Técnico confirmado',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final formattedDate = DateFormat(
      "EEEE d 'de' MMMM, yyyy",
      'es',
    ).format(_selectedDate);

    return GestureDetector(
      onTap: _openDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.event_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha seleccionada',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final slot = defaultTimeSlots[_selectedSlotIndex!];
    final formattedDate = DateFormat("d 'de' MMMM, yyyy", 'es')
        .format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Resumen de tu cita',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow(Icons.calendar_month_rounded, formattedDate),
          const SizedBox(height: AppSpacing.xs),
          _buildSummaryRow(Icons.access_time_rounded, slot.label),
          const SizedBox(height: AppSpacing.xs),
          _buildSummaryRow(Icons.person_rounded, widget.technicianName),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDark.withValues(alpha: 0.7)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
        AppSpacing.screenPaddingH,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: AppShadows.topBar,
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: ElevatedButton(
          onPressed: _canConfirm && !_isLoading ? _confirmBooking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.neutral300,
            foregroundColor: AppColors.textOnPrimary,
            disabledForegroundColor: AppColors.textTertiary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  'Confirmar horario',
                  style: AppTypography.buttonLarge.copyWith(
                    color: _canConfirm
                        ? AppColors.textOnPrimary
                        : AppColors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _minDate,
      lastDate: _maxDate,
      locale: const Locale('es', ''),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surfaceWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Resetear slot al cambiar fecha para evitar confusión.
        _selectedSlotIndex = null;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (!_canConfirm) return;

    final slot = defaultTimeSlots[_selectedSlotIndex!];
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      slot.startHour,
      slot.startMinute,
    );

    setState(() => _isLoading = true);

    final result = await _bookingService.updatePreferredDate(
      widget.requestId,
      bookingDateTime,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      showAppToast(
        context,
        message: result.message ?? 'Horario confirmado exitosamente.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo agendar. Intenta de nuevo.',
        type: ToastType.error,
      );
    }
  }
}
