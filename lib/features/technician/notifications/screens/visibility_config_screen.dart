import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import 'visibility_result_screen.dart';

/// Pantalla de configuración de visibilidad del perfil del técnico.
///
/// Explica que mientras el perfil sea visible seguirá recibiendo notificaciones
/// de pedidos. Permite alternar "¿Perfil visible?" y guardar; al guardar abre
/// [VisibilityResultScreen] con el estado final.
class VisibilityConfigScreen extends StatefulWidget {
  const VisibilityConfigScreen({
    super.key,
    required this.firstName,
    this.initialVisible = true,
  });

  /// Nombre del técnico para personalizar el título.
  final String firstName;

  /// Estado de visibilidad con el que llega la pantalla.
  final bool initialVisible;

  @override
  State<VisibilityConfigScreen> createState() => _VisibilityConfigScreenState();
}

class _VisibilityConfigScreenState extends State<VisibilityConfigScreen> {
  late bool _visible = widget.initialVisible;
  bool _saving = false;

  String get _title {
    final name = widget.firstName.trim().isEmpty
        ? 'Profesional'
        : widget.firstName.trim();
    return '$name, ${AppStrings.visibilityConfiguredOn}';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    // Persiste la preferencia. Ocultar el perfil también detiene la recepción
    // de pedidos (ver explicación en pantalla).
    await AppPreferences.setProfileVisible(_visible);
    await AppPreferences.setReceivingOrders(_visible);
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisibilityResultScreen(visible: _visible),
      ),
    );
    setState(() => _saving = false);
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
            _title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
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
                // ── Título completo ──
                Text(
                  _title,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Explicación ──
                Text(
                  AppStrings.visibilityExplanation,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Checkbox de visibilidad ──
                _VisibilityCheck(
                  value: _visible,
                  onChanged: (v) => setState(() => _visible = v),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Guardar cambios ──
                GradientPillButton(
                  label: AppStrings.saveChanges,
                  isLoading: _saving,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila con checkbox naranja redondeado + etiqueta "¿Perfil visible?".
class _VisibilityCheck extends StatelessWidget {
  const _VisibilityCheck({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
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
            const SizedBox(width: AppSpacing.md),
            Text(
              AppStrings.profileVisibleQuestion,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
