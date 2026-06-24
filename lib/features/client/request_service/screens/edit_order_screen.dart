import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../services/request_service.dart';
import '../widgets/request_widgets.dart';

/// Modo de fecha del pedido (igual que el wizard de creación).
enum _DateMode { flexible, choose, urgent }

/// Edición de campos simples de un pedido del cliente.
///
/// Solo permite cambiar descripción, fecha, factura y dirección. Categoría y
/// distrito se muestran como referencia (no editables). Guarda vía
/// [RequestService.updateRequest] y devuelve `true` al cerrarse con éxito.
class EditOrderScreen extends StatefulWidget {
  const EditOrderScreen({super.key, required this.detail});

  final RequestDetail detail;

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final RequestService _service = RequestService();

  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  late _DateMode _dateMode;
  int _selectedDay = 0;
  late bool _needsInvoice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _descriptionController = TextEditingController(text: d.description);
    _addressController = TextEditingController(text: d.address ?? '');
    _needsInvoice = d.needsInvoice;

    // Reconstruye el modo de fecha a partir de la fecha guardada.
    final pd = d.preferredDate;
    if (pd == null) {
      _dateMode = _DateMode.flexible;
    } else {
      _dateMode = _DateMode.choose;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final picked = DateTime(pd.year, pd.month, pd.day);
      _selectedDay = picked.difference(today).inDays.clamp(0, 4);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Traduce el modo de fecha a una fecha preferida (o null si es flexible).
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

  Future<void> _save() async {
    if (_saving) return;
    final desc = _descriptionController.text.trim();
    if (desc.length < 10) {
      showAppToast(
        context,
        message: 'Describe tu pedido (mínimo 10 caracteres).',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _saving = true);
    final address = _addressController.text.trim();
    final result = await _service.updateRequest(
      requestId: widget.detail.id,
      description: desc,
      preferredDate: _preferredDate(),
      needsInvoice: _needsInvoice,
      address: address.isEmpty ? null : address,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      showAppToast(
        context,
        message: result.message ?? 'Pedido actualizado.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo actualizar el pedido.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final descError =
        _descriptionController.text.isNotEmpty &&
        _descriptionController.text.trim().length < 10;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Editar mi pedido',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.lg,
                  AppSpacing.screenPaddingH,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Categoría (no editable) ──
                    _Label('Categoría'),
                    const SizedBox(height: AppSpacing.xs),
                    _ReadOnlyField(
                      value: d.categoryEmoji.isEmpty
                          ? d.categoryName
                          : '${d.categoryEmoji}  ${d.categoryName}',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Descripción ──
                    Row(
                      children: [
                        Expanded(child: _Label('Descripción del pedido')),
                        const HelpBadge(
                          message:
                              'Describe lo mejor posible tu necesidad, así los '
                              'trabajadores podrán enviarte un presupuesto más '
                              'preciso y detallado.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: descError ? AppColors.error : AppColors.border,
                          width: descError ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Describe tu pedido',
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topLeft,
                      child: descError
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mínimo 10 caracteres',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Distrito (no editable) ──
                    _Label('Distrito'),
                    const SizedBox(height: AppSpacing.xs),
                    _ReadOnlyField(value: d.districtName),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Dirección / referencia ──
                    _Label('Dirección o referencia', optional: true),
                    const SizedBox(height: AppSpacing.xs),
                    _PlainInput(
                      controller: _addressController,
                      hint: 'Ej: Av. España 123',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Fecha ──
                    _Label('¿Cuándo lo necesitas?', optional: true),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableChip(
                            expand: true,
                            label: 'Soy flexible',
                            selected: _dateMode == _DateMode.flexible,
                            onTap: () =>
                                setState(() => _dateMode = _DateMode.flexible),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SelectableChip(
                            expand: true,
                            label: 'Elegir fecha',
                            selected: _dateMode == _DateMode.choose,
                            onTap: () =>
                                setState(() => _dateMode = _DateMode.choose),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SelectableChip(
                            expand: true,
                            label: 'Urgente',
                            selected: _dateMode == _DateMode.urgent,
                            onTap: () =>
                                setState(() => _dateMode = _DateMode.urgent),
                          ),
                        ),
                      ],
                    ),
                    if (_dateMode == _DateMode.choose) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _DayStrip(
                        selected: _selectedDay,
                        onSelected: (i) => setState(() => _selectedDay = i),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // ── Factura legal ──
                    CheckTile(
                      value: _needsInvoice,
                      onChanged: (v) => setState(() => _needsInvoice = v),
                      label: 'Necesito factura legal',
                      showHelp: true,
                    ),
                  ],
                ),
              ),
            ),
            RequestBottomBar(
              child: GradientPillButton(
                label: 'Guardar cambios',
                isLoading: _saving,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label, {this.optional = false});

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

/// Campo de solo lectura (categoría / distrito): no editable en este flujo.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, size: 18, color: AppColors.neutral400),
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

/// Tira horizontal de días scrolleable (igual al wizard): empieza con 5 y, al
/// elegir el último día visible, aparece el siguiente (uno a uno).
class _DayStrip extends StatefulWidget {
  const _DayStrip({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  final ScrollController _controller = ScrollController();
  int _count = 5;

  static const double _itemWidth = 60;
  static const double _gap = AppSpacing.sm;

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
  void initState() {
    super.initState();
    if (widget.selected >= _count) _count = widget.selected + 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    widget.onSelected(i);
    if (i == _count - 1) {
      setState(() => _count += 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _count,
          separatorBuilder: (_, _) => const SizedBox(width: _gap),
          itemBuilder: (_, i) {
            final d = now.add(Duration(days: i));
            final isSel = i == widget.selected;
            return GestureDetector(
              onTap: () => _onTap(i),
              child: Container(
                width: _itemWidth,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            );
          },
        ),
      ),
    );
  }
}
