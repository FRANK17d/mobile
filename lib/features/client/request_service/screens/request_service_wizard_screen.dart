import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import 'request_result_screen.dart';
import '../widgets/request_widgets.dart';

/// Modo de fecha elegido en el paso 3.
enum _DateMode { flexible, choose, urgent }

/// Flujo "Pedir un servicio" en 4 pasos (descripción, ubicación, fecha,
/// resumen). Solo vistas conectadas: el estado se mantiene local y "Publicar"
/// abre la pantalla de resultado. Aún sin lógica de backend.
class RequestServiceWizardScreen extends StatefulWidget {
  const RequestServiceWizardScreen({super.key});

  @override
  State<RequestServiceWizardScreen> createState() =>
      _RequestServiceWizardScreenState();
}

class _RequestServiceWizardScreenState
    extends State<RequestServiceWizardScreen> {
  static const int _totalSteps = 4;
  int _step = 1; // 1..4

  final _descriptionController = TextEditingController();
  final _barrioController = TextEditingController();

  final String _city = 'Mariano Roque Alonso';
  _DateMode _dateMode = _DateMode.flexible;
  int _selectedDay = 0;
  bool _needsInvoice = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _onNext() {
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const RequestResultScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header: back + título + progreso ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.screenPaddingH,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: _onBack,
                    ),
                    Text(
                      'Pedir un servicio',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                  vertical: AppSpacing.sm,
                ),
                child: StepProgressBar(total: _totalSteps, current: _step),
              ),

              // ── Contenido del paso ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    AppSpacing.md,
                    AppSpacing.screenPaddingH,
                    AppSpacing.xxl,
                  ),
                  child: _buildStep(),
                ),
              ),

              // ── Botón inferior ──
              RequestBottomBar(
                child: GradientPillButton(
                  label: _step < _totalSteps ? 'Siguiente' : 'Publicar',
                  onTap: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _DescriptionStep(controller: _descriptionController);
      case 2:
        return _LocationStep(
          city: _city,
          barrioController: _barrioController,
          onCityTap: () {},
        );
      case 3:
        return _DateStep(
          mode: _dateMode,
          selectedDay: _selectedDay,
          needsInvoice: _needsInvoice,
          onModeChanged: (m) => setState(() => _dateMode = m),
          onDaySelected: (i) => setState(() => _selectedDay = i),
          onInvoiceChanged: (v) => setState(() => _needsInvoice = v),
        );
      default:
        return const _SummaryStep();
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 1 — Descripción
// ═══════════════════════════════════════════════════════════
class _DescriptionStep extends StatelessWidget {
  const _DescriptionStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedir un servicio',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                '¿Qué estás necesitando?',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const HelpBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Área de texto multilínea ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration.collapsed(
              hintText:
                  'ej: Algún albañil que termine mi casa...\n'
                  'Quiero pintar mi sala, 30 metros cuadrado',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Adjuntar fotos ──
        Row(
          children: [
            _PhotoButton(icon: Icons.photo_library_outlined, onTap: () {}),
            const SizedBox(width: AppSpacing.sm),
            _PhotoButton(icon: Icons.photo_camera_outlined, onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 26),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 2 — Ubicación
// ═══════════════════════════════════════════════════════════
class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.city,
    required this.barrioController,
    required this.onCityTap,
  });

  final String city;
  final TextEditingController barrioController;
  final VoidCallback onCityTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '¿Dónde se realizará el trabajo?.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Ciudad ──
        Row(
          children: [
            Expanded(child: _FieldLabel('Ciudad')),
            const HelpBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FakeSelectField(value: city, onTap: onCityTap),

        const SizedBox(height: AppSpacing.lg),

        // ── Barrio (opcional) ──
        _FieldLabel('Barrio', optional: true),
        const SizedBox(height: AppSpacing.xs),
        _PlainInput(
          controller: barrioController,
          hint: 'Ej: La concordia',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 3 — Fecha
// ═══════════════════════════════════════════════════════════
class _DateStep extends StatelessWidget {
  const _DateStep({
    required this.mode,
    required this.selectedDay,
    required this.needsInvoice,
    required this.onModeChanged,
    required this.onDaySelected,
    required this.onInvoiceChanged,
  });

  final _DateMode mode;
  final int selectedDay;
  final bool needsInvoice;
  final ValueChanged<_DateMode> onModeChanged;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<bool> onInvoiceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Indicá cuando necesitas que se realice o se empiece el trabajo.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Modos ──
        Row(
          children: [
            SelectableChip(
              label: 'Soy flexible',
              selected: mode == _DateMode.flexible,
              onTap: () => onModeChanged(_DateMode.flexible),
            ),
            const SizedBox(width: AppSpacing.sm),
            SelectableChip(
              label: 'Elegir fecha',
              selected: mode == _DateMode.choose,
              onTap: () => onModeChanged(_DateMode.choose),
            ),
            const SizedBox(width: AppSpacing.sm),
            SelectableChip(
              label: 'Urgente',
              selected: mode == _DateMode.urgent,
              onTap: () => onModeChanged(_DateMode.urgent),
            ),
          ],
        ),

        // ── Selector de días (solo en "Elegir fecha") ──
        if (mode == _DateMode.choose) ...[
          const SizedBox(height: AppSpacing.lg),
          _DayStrip(selected: selectedDay, onSelected: onDaySelected),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Factura legal ──
        CheckTile(
          value: needsInvoice,
          onChanged: onInvoiceChanged,
          label: 'Necesito factura legal',
          showHelp: true,
        ),
      ],
    );
  }
}

/// Tira horizontal de los próximos 5 días.
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const _months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(5, (i) => now.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: List.generate(days.length, (i) {
          final d = days[i];
          final isSel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdays[d.weekday - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _months[d.month - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 4 — Resumen
// ═══════════════════════════════════════════════════════════
class _SummaryStep extends StatelessWidget {
  const _SummaryStep();

  static const _items = [
    'Verificamos cada publicación antes de mostrarla.',
    'Recibirás hasta 5 prestadores interesados; algunos enviarán presupuesto, '
        'otros te contactarán directo, o si deseas, contáctalos vos mismo.',
    'Si no te convencen, pedís más opciones.',
    'Confirmá al prestador ideal con el botón "Confirmar".',
    'Pagá siempre directo al prestador, nunca por adelantado.',
    'Al finalizar, cerrá el pedido, calificá y compartí fotos del trabajo.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Te contamos que pasará:',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _NumberedItem(number: i + 1, text: _items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberedItem extends StatelessWidget {
  const _NumberedItem({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$number.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Helpers compartidos de campos
// ═══════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (optional)
            TextSpan(
              text: ' (opcional)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlainInput extends StatelessWidget {
  const _PlainInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
