import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/screens/logout_transition_screen.dart';
import '../../auth/services/auth_service.dart';

/// Cambio de contraseña para el usuario autenticado.
///
/// InsForge no expone un endpoint de cambio directo (contraseña actual → nueva),
/// así que por seguridad se confirma la identidad con un código enviado al correo
/// del usuario (mismo mecanismo probado del flujo "olvidé mi contraseña"). Tras
/// cambiarla se cierra la sesión para iniciar con la nueva contraseña.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

enum _Phase { loading, intro, form, success }

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _auth = AuthService();

  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Phase _phase = _Phase.loading;
  String? _email;
  bool _busy = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final email = await _auth.getCurrentUserEmail();
    if (!mounted) return;
    setState(() {
      _email = email;
      _phase = _Phase.intro;
    });
  }

  String get _maskedEmail {
    final email = _email ?? '';
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final name = email.substring(0, at);
    final domain = email.substring(at);
    return name.length <= 3
        ? '${name[0]}***$domain'
        : '${name.substring(0, 3)}***$domain';
  }

  bool get _formValid =>
      _codeCtrl.text.trim().length == 6 &&
      _passCtrl.text.length >= 6 &&
      _passCtrl.text == _confirmCtrl.text;

  // ── Acciones ──

  Future<void> _sendCode() async {
    final email = _email;
    if (email == null || email.isEmpty || _busy) return;
    setState(() => _busy = true);
    final sent = await _auth.sendPasswordResetCode(email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!sent) {
      showAppToast(
        context,
        message: 'No pudimos enviar el código. Intenta de nuevo.',
        type: ToastType.error,
      );
      return;
    }
    setState(() {
      _error = null;
      _phase = _Phase.form;
    });
  }

  Future<void> _resendCode() async {
    final email = _email;
    if (email == null || email.isEmpty || _busy) return;
    final sent = await _auth.sendPasswordResetCode(email);
    if (!mounted) return;
    showAppToast(
      context,
      message: sent ? 'Código reenviado a tu correo' : 'No se pudo reenviar',
      type: sent ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    final email = _email;
    if (email == null || !_formValid || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    // 1) Canjea el código por un token de reset.
    final token = await _auth.exchangePasswordResetCode(
      email: email,
      code: _codeCtrl.text.trim(),
    );
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'Código incorrecto o vencido. Reenvía e intenta de nuevo.';
      });
      return;
    }

    // 2) Aplica la nueva contraseña.
    final ok = await _auth.resetPassword(
      resetToken: token,
      newPassword: _passCtrl.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'No pudimos actualizar la contraseña. Intenta de nuevo.';
      });
      return;
    }

    setState(() {
      _busy = false;
      _phase = _Phase.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _phase == _Phase.success
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  title: Text(
                    'Cambiar mi contraseña',
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          body: SafeArea(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.loading => const Center(child: CircularProgressIndicator()),
      _Phase.intro => _buildIntro(),
      _Phase.form => _buildForm(),
      _Phase.success => _buildSuccess(),
    };
  }

  // ── Fase 1: explicación + enviar código ──
  Widget _buildIntro() {
    final canSend = _email != null && _email!.isNotEmpty;
    return Column(
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Confirmemos que eres tú',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (canSend)
                  RichText(
                    text: TextSpan(
                      text:
                          'Por seguridad, enviaremos un código de 6 dígitos a ',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: _maskedEmail,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: ' para confirmar el cambio de contraseña.',
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'No pudimos obtener tu correo. Revisa tu conexión e '
                    'inténtalo de nuevo.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
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
          child: _PrimaryButton(
            label: _busy ? 'Enviando...' : 'Enviar código',
            onTap: canSend && !_busy ? _sendCode : null,
          ),
        ),
      ],
    );
  }

  // ── Fase 2: código + nueva contraseña ──
  Widget _buildForm() {
    return Column(
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
                Text(
                  'Ingresa el código y tu nueva contraseña',
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Revisa $_maskedEmail. El código vence en unos minutos.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _Label('Código de verificación'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() => _error = null),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    filled: true,
                    fillColor: AppColors.neutral100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _resendCode,
                    child: Text(
                      'Reenviar código',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),
                _Label('Nueva contraseña'),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _passCtrl,
                  hint: 'Nueva contraseña',
                  obscure: _obscurePass,
                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_passCtrl.text.isNotEmpty && _passCtrl.text.length < 6)
                  const _FieldHint('Mínimo 6 caracteres'),

                const SizedBox(height: AppSpacing.md),
                _Label('Confirmar nueva contraseña'),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _confirmCtrl,
                  hint: 'Confirmar nueva contraseña',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_confirmCtrl.text.isNotEmpty &&
                    _passCtrl.text != _confirmCtrl.text)
                  const _FieldHint('Las contraseñas no coinciden'),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FieldHint(_error!),
                ],
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
          child: _PrimaryButton(
            label: _busy ? 'Guardando...' : 'Cambiar contraseña',
            onTap: _formValid && !_busy ? _changePassword : null,
          ),
        ),
      ],
    );
  }

  // ── Fase 3: éxito ──
  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 72,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '¡Contraseña actualizada!',
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Por seguridad cerraremos tu sesión. Inicia de nuevo con tu nueva '
            'contraseña.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
          _PrimaryButton(
            label: 'Iniciar sesión',
            onTap: () => showLogoutTransition(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets locales ──

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

class _FieldHint extends StatelessWidget {
  const _FieldHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.neutral500,
            size: 22,
          ),
        ),
        filled: true,
        fillColor: AppColors.neutral100,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
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
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
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
