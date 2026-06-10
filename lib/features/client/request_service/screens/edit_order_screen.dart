import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../widgets/request_widgets.dart';

/// Modo de fecha del pedido.
enum _DateMode { flexible, choose, urgent }

/// Edición de un pedido existente. Solo vista conectada (los campos llegan
/// precargados); "Guardar cambios" vuelve atrás. Aún sin lógica de backend.
class EditOrderScreen extends StatefulWidget {
  const EditOrderScreen({super.key});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _descriptionController = TextEditingController(text: 'Algún albañil');
  final _barrioController = TextEditingController();

  final String _city = 'Mariano Roque Alonso';
  _DateMode _dateMode = _DateMode.flexible;
  bool _needsInvoice = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
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
                    // ── Descripción ──
                    Row(
                      children: [
                        Expanded(child: _Label('Descripción del pedido')),
                        const HelpBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Describe tu pedido',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Ciudad ──
                    Row(
                      children: [
                        Expanded(child: _Label('Ciudad')),
                        const HelpBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FakeSelectField(value: _city, onTap: () {}),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Barrio ──
                    _Label('Barrio', optional: true),
                    const SizedBox(height: AppSpacing.xs),
                    _PlainInput(
                      controller: _barrioController,
                      hint: 'Ej: La concordia',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Fecha ──
                    _Label('¿Cuándo lo necesitas?', optional: true),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        SelectableChip(
                          label: 'Soy flexible',
                          selected: _dateMode == _DateMode.flexible,
                          onTap: () =>
                              setState(() => _dateMode = _DateMode.flexible),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SelectableChip(
                          label: 'Elegir fecha',
                          selected: _dateMode == _DateMode.choose,
                          onTap: () =>
                              setState(() => _dateMode = _DateMode.choose),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SelectableChip(
                          label: 'Urgente',
                          selected: _dateMode == _DateMode.urgent,
                          onTap: () =>
                              setState(() => _dateMode = _DateMode.urgent),
                        ),
                      ],
                    ),
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
                onTap: () => Navigator.of(context).maybePop(),
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
