import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/screens/logout_transition_screen.dart';
import '../../auth/services/auth_service.dart';

/// Baja de cuenta del usuario. Marca el perfil como inactivo (soft-delete) vía
/// RPC `deactivate_my_account`; no se borran pedidos históricos por integridad
/// referencial. Tras confirmar, se cierra la sesión.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AuthService _auth = AuthService();
  bool _confirmed = false;
  bool _busy = false;

  Future<void> _delete() async {
    if (!_confirmed || _busy) return;
    setState(() => _busy = true);
    final ok = await _auth.deactivateAccount();
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      showAppToast(
        context,
        message: 'No se pudo eliminar la cuenta. Intenta de nuevo.',
        type: ToastType.error,
      );
      return;
    }
    // Cierra sesión y vuelve al home no autenticado.
    showLogoutTransition(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'Eliminar mi cuenta',
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
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.heart_broken_outlined,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '¿Seguro que quieres irte?',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Al eliminar tu cuenta:',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _Consequence(
                        'Tu perfil dejará de ser visible y no podrás iniciar '
                        'sesión.',
                      ),
                      const _Consequence(
                        'Perderás acceso a tus pedidos y conversaciones.',
                      ),
                      const _Consequence(
                        'Esta acción no se puede deshacer desde la app.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // ── Confirmación explícita ──
                      InkWell(
                        onTap: () => setState(() => _confirmed = !_confirmed),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _confirmed,
                                onChanged: (v) =>
                                    setState(() => _confirmed = v ?? false),
                                activeColor: AppColors.error,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Entiendo las consecuencias y quiero '
                                    'eliminar mi cuenta.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  12,
                  AppSpacing.screenPaddingH,
                  16,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _confirmed && !_busy ? _delete : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.neutral300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Eliminar mi cuenta',
                                style: AppTypography.buttonLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Mejor no, volver',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(
              Icons.remove_circle_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
