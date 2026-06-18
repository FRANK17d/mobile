import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/district_selector_screen.dart';
import '../../../auth/services/district_service.dart';
import '../../home/services/category_service.dart';
import '../services/request_service.dart';
import 'request_result_screen.dart';
import '../widgets/request_widgets.dart';

/// Modo de fecha elegido en el paso 3.
enum _DateMode { flexible, choose, urgent }

/// Flujo "Pedir un servicio" en 4 pasos (descripción+categoría, ubicación,
/// fecha, resumen). Publica un pedido real (queda en revisión del admin).
class RequestServiceWizardScreen extends StatefulWidget {
  const RequestServiceWizardScreen({super.key, this.initialCategoryName});

  /// Nombre de categoría preseleccionada (p.ej. al entrar desde el carrusel del
  /// home). Se resuelve contra las categorías cargadas de la BD.
  final String? initialCategoryName;

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

  final CategoryService _categoryService = CategoryService();
  final RequestService _requestService = RequestService();
  final LocationService _locationService = LocationService();

  List<ServiceCategory> _categories = const [];
  ServiceCategory? _selectedCategory;
  District? _selectedDistrict;

  _DateMode _dateMode = _DateMode.flexible;
  int _selectedDay = 0;
  bool _needsInvoice = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryService.getActiveCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      // Resolver la categoría preseleccionada (por nombre) contra la lista real.
      final name = widget.initialCategoryName;
      if (name != null && _selectedCategory == null) {
        for (final c in cats) {
          if (c.name == name) {
            _selectedCategory = c;
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  /// Valida el paso actual antes de avanzar/publicar.
  bool _validateStep() {
    switch (_step) {
      case 1:
        if (_selectedCategory == null) {
          showAppToast(
            context,
            message: 'Elige una categoría.',
            type: ToastType.warning,
          );
          return false;
        }
        if (_descriptionController.text.trim().length < 10) {
          showAppToast(
            context,
            message: 'Describe tu pedido (mínimo 10 caracteres).',
            type: ToastType.warning,
          );
          return false;
        }
        return true;
      case 2:
        if (_selectedDistrict == null) {
          showAppToast(
            context,
            message: 'Elige tu distrito.',
            type: ToastType.warning,
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _onBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _onNext() {
    if (_publishing) return;
    if (!_validateStep()) return;
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  /// Convierte el modo de fecha en una fecha preferida (o null si es flexible).
  DateTime? _preferredDate() {
    switch (_dateMode) {
      case _DateMode.flexible:
        return null;
      case _DateMode.urgent:
        return DateTime.now();
      case _DateMode.choose:
        return DateTime.now().add(Duration(days: _selectedDay));
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);

    // GPS best-effort: si se niega, el pedido se publica igual (sin coords).
    final pos = await _locationService.getCurrentLatLng();

    final result = await _requestService.createRequest(
      categoryId: _selectedCategory!.id,
      districtId: _selectedDistrict!.id,
      title: _selectedCategory!.name,
      description: _descriptionController.text.trim(),
      preferredDate: _preferredDate(),
      needsInvoice: _needsInvoice,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      address: _barrioController.text.trim().isEmpty
          ? null
          : _barrioController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _publishing = false);

    if (result.success) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RequestResultScreen()),
      );
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo publicar el pedido.',
        type: ToastType.error,
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
                  label: _publishing
                      ? 'Publicando...'
                      : (_step < _totalSteps ? 'Siguiente' : 'Publicar'),
                  onTap: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Elige una categoría',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _categories
                    .map(
                      (c) => ListTile(
                        leading: Text(
                          c.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(c.name, style: AppTypography.bodyLarge),
                        trailing: _selectedCategory?.id == c.id
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedCategory = c);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDistrictPicker() async {
    final result = await Navigator.of(context).push<District>(
      MaterialPageRoute(
        builder: (_) =>
            DistrictSelectorScreen(currentSelection: _selectedDistrict),
      ),
    );
    if (result != null) {
      setState(() => _selectedDistrict = result);
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _DescriptionStep(
          controller: _descriptionController,
          selectedCategory: _selectedCategory,
          onPickCategory: _openCategoryPicker,
        );
      case 2:
        return _LocationStep(
          districtName: _selectedDistrict?.name,
          barrioController: _barrioController,
          onDistrictTap: _openDistrictPicker,
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
  const _DescriptionStep({
    required this.controller,
    required this.selectedCategory,
    required this.onPickCategory,
  });

  final TextEditingController controller;
  final ServiceCategory? selectedCategory;
  final VoidCallback onPickCategory;

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
        const SizedBox(height: AppSpacing.md),

        // ── Categoría ──
        _FieldLabel('Categoría'),
        const SizedBox(height: AppSpacing.xs),
        FakeSelectField(
          value: selectedCategory == null
              ? 'Elegir categoría'
              : '${selectedCategory!.emoji} ${selectedCategory!.name}',
          onTap: onPickCategory,
        ),

        const SizedBox(height: AppSpacing.lg),
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
    required this.districtName,
    required this.barrioController,
    required this.onDistrictTap,
  });

  final String? districtName;
  final TextEditingController barrioController;
  final VoidCallback onDistrictTap;

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

        // ── Distrito ──
        Row(
          children: [
            Expanded(child: _FieldLabel('Distrito')),
            const HelpBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FakeSelectField(
          value: districtName ?? 'Seleccione su distrito',
          onTap: onDistrictTap,
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Dirección/referencia (opcional) ──
        _FieldLabel('Dirección o referencia', optional: true),
        const SizedBox(height: AppSpacing.xs),
        _PlainInput(controller: barrioController, hint: 'Ej: Av. España 123'),
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
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
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
