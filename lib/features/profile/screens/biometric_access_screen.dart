import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/insforge_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/services/auth_service.dart';

/// Vista 1 — Acceso biométrico: muestra el estado (activado/desactivado) con un
/// switch. Al activar, lleva a la vista de confirmación de contraseña.
class BiometricAccessScreen extends StatefulWidget {
  const BiometricAccessScreen({super.key});

  @override
  State<BiometricAccessScreen> createState() => _BiometricAccessScreenState();
}

class _BiometricAccessScreenState extends State<BiometricAccessScreen> {
  final BiometricService _bio = BiometricService.instance;
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _supported = false;
  bool _isPasswordUser = true;
  bool _enabled = false;
  bool _working = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deviceOk = await _bio.isDeviceSupported();
    final hasPassword = await _auth.currentUserHasPassword();
    final email = await _auth.getCurrentUserEmail();
    final currentUid = await InsForgeClient().getCurrentUserId();
    final enabledUid = await _bio.enabledUserId();
    final isOn = await _bio.isEnabled();
    if (!mounted) return;
    setState(() {
      _isPasswordUser = hasPassword;
      // Disponible solo si el equipo tiene biometría Y la cuenta usa contraseña
      // (las cuentas de Google no pueden usar biometría).
      _supported = deviceOk && hasPassword;
      // "Activado" solo si la biometría guardada pertenece a este usuario.
      _enabled = isOn && enabledUid != null && enabledUid == currentUid;
      _email = email;
      _loading = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (_working) return;

    if (!_supported) {
      showAppToast(
        context,
        message: 'Tu dispositivo no tiene biometría configurada.',
        type: ToastType.warning,
      );
      return;
    }

    if (value) {
      // Activar → confirmar contraseña en la vista 2.
      final email = _email;
      if (email == null || email.isEmpty) {
        showAppToast(
          context,
          message: 'No pudimos obtener tu correo. Intenta de nuevo.',
          type: ToastType.error,
        );
        return;
      }
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _BiometricConfirmScreen(email: email),
        ),
      );
      if (ok == true && mounted) {
        setState(() => _enabled = true);
        showAppToast(
          context,
          message: 'Acceso biométrico activado.',
          type: ToastType.success,
        );
      }
    } else {
      // Desactivar.
      setState(() => _working = true);
      await _bio.disable();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _working = false;
      });
      showAppToast(context, message: 'Acceso biométrico desactivado.');
    }
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
            'Acceso biométrico',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.primary,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Inicia sesión más rápido',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Usa tu huella o rostro para entrar a TOKE+ sin escribir '
                        'tu contraseña cada vez.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Tarjeta con el switch ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Acceso biométrico',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_working)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Switch(
                                value: _enabled,
                                onChanged: _supported ? _onToggle : null,
                                activeThumbColor: AppColors.primary,
                              ),
                          ],
                        ),
                      ),

                      if (!_supported) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _isPasswordUser
                                    ? 'Tu dispositivo no tiene huella o rostro '
                                          'configurado. Actívalo en los ajustes '
                                          'del teléfono para usar esta opción.'
                                    : 'El acceso biométrico no está disponible '
                                          'para cuentas de Google.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Vista 2 — Confirmar contraseña para activar la biometría.
class _BiometricConfirmScreen extends StatefulWidget {
  const _BiometricConfirmScreen({required this.email});

  final String email;

  @override
  State<_BiometricConfirmScreen> createState() =>
      _BiometricConfirmScreenState();
}

class _BiometricConfirmScreenState extends State<_BiometricConfirmScreen> {
  final AuthService _auth = AuthService();
  final BiometricService _bio = BiometricService.instance;
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    if (_passCtrl.text.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    // 1) Verifica que la contraseña sea correcta.
    final userId = await _auth.login(widget.email, _passCtrl.text);
    if (!mounted) return;
    if (userId == null) {
      setState(() {
        _busy = false;
        _error = 'Contraseña incorrecta. Intenta de nuevo.';
      });
      return;
    }

    // 2) Pide la verificación biométrica y guarda las credenciales.
    final enabled = await _bio.enable(
      email: widget.email,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!enabled) {
      setState(() {
        _error = 'No se pudo activar. Verifica tu huella e intenta de nuevo.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            title: Text(
              'Confirma tu contraseña',
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
                        Text(
                          'Por seguridad, ingresa tu contraseña para activar el '
                          'acceso biométrico.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Contraseña',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: AppTypography.bodyMedium,
                          onChanged: (_) => setState(() => _error = null),
                          onSubmitted: (_) => _confirm(),
                          decoration: InputDecoration(
                            hintText: 'Tu contraseña',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.neutral100,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.neutral500,
                                size: 22,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _busy ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                              'Activar acceso biométrico',
                              style: AppTypography.buttonLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
