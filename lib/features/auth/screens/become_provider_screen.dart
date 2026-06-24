import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../../core/widgets/inputs/terms_acceptance.dart';
import '../services/auth_service.dart';
import '../services/auth_store.dart';

/// Conversión rápida de cliente a prestador de servicios.
///
/// El cliente ya tiene nombre, teléfono y distrito en su perfil; aquí solo pide
/// el DNI y una breve presentación. Las categorías y demás se configuran luego
/// en el panel del técnico.
class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final AuthService _auth = AuthService();
  final _dniCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _acceptTerms = false;
  bool _busy = false;

  @override
  void dispose() {
    _dniCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get _dniValid => _dniCtrl.text.trim().length == 8;
  bool get _bioValid => _bioCtrl.text.trim().length >= 20;
  bool get _valid => _dniValid && _bioValid && _acceptTerms && !_busy;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_valid) return;

    setState(() => _busy = true);
    final res = await _auth.convertToTechnician(
      dni: _dniCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    if (!mounted) return;

    if (!res.success) {
      setState(() => _busy = false);
      showAppToast(
        context,
        message: res.message ?? 'No se pudo completar la conversión.',
        type: ToastType.error,
      );
      return;
    }

    // Refresca el perfil (ya es técnico) y entra al panel de técnico.
    final profile = await _auth.getMyTechnicianProfile();
    if (!mounted) return;
    AuthStore.instance.setAuthenticated(profile);
    showAppToast(
      context,
      message: '¡Listo! Ahora eres prestador de servicios.',
      type: ToastType.success,
    );
    context.go(AppRoutes.techHome);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            title: Text(
              'Convertirme en prestador',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Empezar a brindar tus servicios',
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Con TOKE+ podrás conseguir más clientes. Usaremos los '
                          'datos de tu cuenta; solo necesitamos tu DNI y una '
                          'breve presentación.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // ── DNI ──
                        _Label('N° de DNI'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _dniCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          style: AppTypography.bodyMedium,
                          decoration: _inputDecoration('Ej: 12345678'),
                        ),
                        if (_dniCtrl.text.isNotEmpty && !_dniValid)
                          const _Hint('El DNI debe tener 8 dígitos'),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Presentación ──
                        _Label('Presentación'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _bioCtrl,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          style: AppTypography.bodyMedium,
                          decoration: _inputDecoration(
                            'Breve presentación: tus servicios y habilidades.',
                          ),
                        ),
                        if (_bioCtrl.text.isNotEmpty && !_bioValid)
                          const _Hint(
                            'La presentación debe tener al menos 20 caracteres',
                          ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Términos ──
                        TermsAcceptanceCheckbox(
                          value: _acceptTerms,
                          onChanged: (v) => setState(() => _acceptTerms = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    12,
                    AppSpacing.screenPaddingH,
                    20,
                  ),
                  child: _SubmitButton(
                    label: 'Convertirme en prestador',
                    enabled: _valid,
                    busy: _busy,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.neutral300),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      counterText: '',
      filled: true,
      fillColor: AppColors.neutral100,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : AppColors.neutral300,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: AppTypography.buttonLarge.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.secondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
