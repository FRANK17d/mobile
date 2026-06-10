import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../services/auth_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Widget 1: Modal de opciones de recuperacion
// ═════════════════════════════════════════════════════════════════════════════

/// Muestra un modal overlay transparente con opciones de recuperacion
/// de contraseña: email o soporte vía WhatsApp.
void showForgotPasswordModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar modal de recuperación',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      return const _ForgotPasswordModalContent();
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curvedAnim = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curvedAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: child,
        ),
      );
    },
  );
}

class _ForgotPasswordModalContent extends StatelessWidget {
  const _ForgotPasswordModalContent();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Modal de recuperación de contraseña',
      child: Material(
        color: const Color(0xFF1D2939).withValues(alpha: 0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.screenPaddingV,
            ),
            child: Column(
              children: [
                // ── Boton cerrar (X) top right ──
                Align(
                  alignment: Alignment.topRight,
                  child: Semantics(
                    button: true,
                    label: 'Cerrar modal',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Titulo ──
                Semantics(
                  header: true,
                  child: Text(
                    'Vamos a recuperar\nesa contraseña',
                    textAlign: TextAlign.center,
                    style: AppTypography.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Mascota SVG ──
                Semantics(
                  image: true,
                  label: 'Mascota Toke+',
                  child: SvgPicture.asset(
                    AppImages.mascot,
                    width: 120,
                    height: 120,
                  ),
                ),

                const Spacer(flex: 3),

                // ── Boton: Recuperar con correo electronico ──
                Semantics(
                  button: true,
                  label: 'Recuperar contraseña con correo electrónico',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/forgot-password');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Text(
                          'Recuperar con correo electrónico',
                          style: AppTypography.buttonMedium.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Boton: Contactar con soporte ──
                Semantics(
                  button: true,
                  label: 'Contactar con soporte vía WhatsApp',
                  child: GestureDetector(
                    onTap: () {
                      // TODO: abrir WhatsApp soporte
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble,
                            color: Color(0xFF25D366),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Contactar con soporte',
                            style: AppTypography.buttonMedium.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Widget 2: ForgotPasswordScreen - Ingreso de correo electronico
// ═════════════════════════════════════════════════════════════════════════════

/// Pantalla de ingreso de correo para recuperar contraseña.
/// Solicita a InsForge el OTP configurado para reset password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isSending = false;
  String? _errorMessage;

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _onRecuperarTap() async {
    _dismissKeyboard();
    if (!_isEmailValid || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final sent = await _authService.sendPasswordResetCode(email);

    if (!mounted) return;

    setState(() => _isSending = false);

    if (!sent) {
      setState(() {
        _errorMessage = 'No pudimos enviar el código. Verifica tu correo.';
      });
      return;
    }

    context.push('/forgot-password/otp', extra: email);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                // ── AppBar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Volver atrás',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Volver',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          'Recuperar mi contraseña',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Contenido scrollable ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),

                        // ── Titulo ──
                        Semantics(
                          header: true,
                          child: Text(
                            'Recuperar mi\ncontraseña',
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Descripcion ──
                        Text(
                          '¿Olvidaste tu contraseña? No te preocupes; ingresa el correo de tu cuenta y te enviaremos un código para crear una nueva contraseña.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // ── Label correo ──
                        Text(
                          'Correo electrónico',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Campo correo ──
                        Semantics(
                          textField: true,
                          label: 'Correo electrónico de la cuenta',
                          child: _EmailResetField(
                            controller: _emailController,
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            hasError: _errorMessage != null,
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _InlineMessage(
                                    message: _errorMessage!,
                                    type: _InlineMessageType.error,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Boton fijo en bottom ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    12,
                    AppSpacing.screenPaddingH,
                    24,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: _isEmailValid && !_isSending,
                    label: 'Enviar código de recuperación',
                    child: _GradientPillButton(
                      label: _isSending ? 'Enviando...' : 'Recuperar',
                      onTap: _isEmailValid && !_isSending
                          ? _onRecuperarTap
                          : null,
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

// ═════════════════════════════════════════════════════════════════════════════
// Widget 3: OtpVerificationScreen - Verificacion de codigo OTP
// ═════════════════════════════════════════════════════════════════════════════

/// Pantalla de verificacion de codigo OTP de 6 digitos.
/// Muestra 6 cajas individuales con auto-avance de foco.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _otpLength = 6;
  static const _resendSeconds = 30;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  final _authService = AuthService();

  Timer? _timer;
  int _secondsRemaining = _resendSeconds;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isApplyingOtp = false;
  String? _errorMessage;

  String get _maskedEmail {
    final email = widget.email;
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) return email;

    final name = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    if (name.length <= 3) {
      return '${name[0]}***$domain';
    }
    return '${name.substring(0, 3)}***$domain';
  }

  String get _otpValue {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete => _otpValue.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Solicitar foco en el primer campo tras build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = _resendSeconds;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isVerifying) return;

    final sent = await _authService.sendPasswordResetCode(widget.email);
    if (!mounted) return;

    if (!sent) {
      setState(() {
        _errorMessage = 'No pudimos reenviar el código. Inténtalo de nuevo.';
      });
      return;
    }

    setState(() => _errorMessage = null);
    _startTimer();
    showAppToast(
      context,
      message: 'Código reenviado a tu correo',
      type: ToastType.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _onVerificarTap() async {
    _dismissKeyboard();
    if (!_isOtpComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final resetToken = await _authService.exchangePasswordResetCode(
      email: widget.email,
      code: _otpValue,
    );

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (resetToken == null || resetToken.isEmpty) {
      setState(() {
        _errorMessage = 'Código incorrecto o vencido. Inténtalo nuevamente.';
      });
      return;
    }

    context.push(
      '/forgot-password/new-password',
      extra: {'resetToken': resetToken},
    );
  }

  void _setOtpDigit(int index, String value) {
    _controllers[index].value = TextEditingValue(
      text: value,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _placeCursorAtStart(int index) {
    _controllers[index].selection = const TextSelection.collapsed(offset: 0);
  }

  void _fillOtpFrom(int startIndex, String digits) {
    _isApplyingOtp = true;

    final normalizedDigits = digits.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < normalizedDigits.length; i++) {
      final targetIndex = startIndex + i;
      if (targetIndex >= _controllers.length) break;
      _setOtpDigit(targetIndex, normalizedDigits[i]);
    }

    _isApplyingOtp = false;

    final nextEmptyIndex = _controllers.indexWhere((controller) {
      return controller.text.isEmpty;
    });
    final focusIndex = nextEmptyIndex == -1
        ? _controllers.length - 1
        : nextEmptyIndex;
    _focusNodes[focusIndex].requestFocus();
    _placeCursorAtStart(focusIndex);

    setState(() => _errorMessage = null);

    if (_isOtpComplete && !_isVerifying) {
      _onVerificarTap();
    }
  }

  void _onOtpDigitChanged(String value, int index) {
    if (_isApplyingOtp) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (digits.isEmpty) {
      _setOtpDigit(index, '');
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        _placeCursorAtStart(index - 1);
      }
      setState(() {});
      return;
    }

    if (digits.length > 2) {
      _fillOtpFrom(index, digits);
      return;
    }

    _isApplyingOtp = true;
    _setOtpDigit(index, digits[0]);
    _isApplyingOtp = false;

    if (index < _controllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
      _placeCursorAtStart(index + 1);
    } else {
      _placeCursorAtStart(index);
    }

    setState(() {});

    if (_isOtpComplete && !_isVerifying) {
      _onVerificarTap();
    }
  }

  KeyEventResult _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        _controllers[index].text.isNotEmpty ||
        index == 0) {
      return KeyEventResult.ignored;
    }

    _setOtpDigit(index - 1, '');
    _focusNodes[index - 1].requestFocus();
    _placeCursorAtStart(index - 1);

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                // ── AppBar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Volver atrás',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Volver',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          'Verificación',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Contenido ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),

                        // ── Titulo ──
                        Semantics(
                          header: true,
                          child: Text(
                            'Verifica tu correo',
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // ── Subtitulo ──
                        RichText(
                          text: TextSpan(
                            text:
                                'Ingresa el código de 6 dígitos que enviamos a ',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: _maskedEmail,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        // ── 6 cajas OTP ──
                        Semantics(
                          label:
                              'Ingrese el código de verificación de 6 dígitos',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_otpLength, (index) {
                              return _OtpBox(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                hasError: _errorMessage != null,
                                semanticsLabel: 'Dígito ${index + 1} de 6',
                                onTap: () => _placeCursorAtStart(index),
                                onChanged: (value) =>
                                    _onOtpDigitChanged(value, index),
                                onKeyEvent: (event) =>
                                    _onOtpKeyEvent(index, event),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Timer / Reenviar ──
                        Center(
                          child: Semantics(
                            button: _canResend,
                            label: 'Reenviar código de verificación',
                            child: GestureDetector(
                              onTap: _canResend ? _resendCode : null,
                              child: RichText(
                                text: TextSpan(
                                  text: '¿No recibiste el código? ',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _canResend
                                          ? 'Reenviar'
                                          : 'Reenviar en ${_secondsRemaining}s',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: _canResend
                                            ? AppColors.primary
                                            : AppColors.textTertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _InlineMessage(
                                    message: _errorMessage!,
                                    type: _InlineMessageType.error,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Boton verificar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    12,
                    AppSpacing.screenPaddingH,
                    24,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: _isOtpComplete && !_isVerifying,
                    label: 'Verificar código ingresado',
                    child: _GradientPillButton(
                      label: _isVerifying ? 'Verificando...' : 'Verificar',
                      onTap: _isOtpComplete && !_isVerifying
                          ? _onVerificarTap
                          : null,
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

/// Caja individual para un digito OTP
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.semanticsLabel,
    required this.onTap,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final String semanticsLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 58,
      child: Semantics(
        textField: true,
        label: semanticsLabel,
        child: Focus(
          onKeyEvent: (_, event) => onKeyEvent(event),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            cursorColor: AppColors.primary,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: hasError
                  ? AppColors.error.withValues(alpha: 0.06)
                  : AppColors.neutral100,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onTap: onTap,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Widget 4: NewPasswordScreen - Crear nueva contraseña
// ═════════════════════════════════════════════════════════════════════════════

/// Pantalla para crear una nueva contraseña tras verificar el OTP.
/// Incluye validacion de minimo 6 caracteres y coincidencia.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _showMinLengthError =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text.length < 6;

  bool get _showMismatchError =>
      _confirmPasswordController.text.isNotEmpty &&
      _passwordController.text != _confirmPasswordController.text;

  bool get _isFormValid =>
      widget.resetToken.isNotEmpty &&
      !_isSaving &&
      _passwordController.text.length >= 6 &&
      _passwordController.text == _confirmPasswordController.text;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _onConfirmarTap() async {
    _dismissKeyboard();
    if (!_isFormValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await _authService.resetPassword(
      resetToken: widget.resetToken,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!success) {
      setState(() {
        _errorMessage =
            'No pudimos actualizar tu contraseña. Solicita un nuevo código.';
      });
      return;
    }

    context.push('/forgot-password/success');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                // ── AppBar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Volver atrás',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Volver',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          'Nueva contraseña',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Contenido ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),

                        // ── Titulo ──
                        Semantics(
                          header: true,
                          child: Text(
                            'Creá tu nueva\ncontraseña',
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // ── Subtitulo ──
                        Text(
                          'Tu nueva contraseña debe ser diferente a la anterior.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // ── Label nueva contraseña ──
                        Text(
                          'Nueva contraseña',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Campo nueva contraseña ──
                        Semantics(
                          textField: true,
                          label: 'Ingrese su nueva contraseña',
                          child: _PasswordFormField(
                            controller: _passwordController,
                            hint: 'Nueva contraseña',
                            obscure: _obscurePassword,
                            onToggle: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            hasError: _showMinLengthError,
                          ),
                        ),

                        // ── Validacion minimo 6 caracteres ──
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _showMinLengthError
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Mínimo 6 caracteres',
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

                        const SizedBox(height: AppSpacing.md),

                        // ── Label confirmar ──
                        Text(
                          'Confirmar nueva contraseña',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Campo confirmar contraseña ──
                        Semantics(
                          textField: true,
                          label: 'Confirme su nueva contraseña',
                          child: _PasswordFormField(
                            controller: _confirmPasswordController,
                            hint: 'Confirmar nueva contraseña',
                            obscure: _obscureConfirm,
                            onToggle: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                            onChanged: (_) => setState(() {
                              _errorMessage = null;
                            }),
                            hasError: _showMismatchError,
                          ),
                        ),

                        // ── Validacion coincidencia ──
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _showMismatchError
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Las contraseñas no coinciden',
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

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: _InlineMessage(
                                    message: _errorMessage!,
                                    type: _InlineMessageType.error,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Boton confirmar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    12,
                    AppSpacing.screenPaddingH,
                    24,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: _isFormValid,
                    label: 'Confirmar nueva contraseña',
                    child: _GradientPillButton(
                      label: _isSaving ? 'Guardando...' : 'Confirmar',
                      onTap: _isFormValid ? _onConfirmarTap : null,
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

// ═════════════════════════════════════════════════════════════════════════════
// Widget 5: PasswordResetSuccessScreen - Exito al cambiar contraseña
// ═════════════════════════════════════════════════════════════════════════════

/// Pantalla de éxito tras actualizar la contraseña.
/// Muestra check verde con animación elasticOut y botón para ir al login.
class PasswordResetSuccessScreen extends StatefulWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  State<PasswordResetSuccessScreen> createState() =>
      _PasswordResetSuccessScreenState();
}

class _PasswordResetSuccessScreenState extends State<PasswordResetSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Iniciar animacion tras breve delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Icono de exito animado ──
                AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: const _SuccessCheckOrb(),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ── Texto de exito ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          '¡Contraseña\nactualizada!',
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ya podés iniciar sesión con tu nueva contraseña.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Boton ir a login ──
                Semantics(
                  button: true,
                  label: 'Ir a iniciar sesión',
                  child: _GradientPillButton(
                    label: 'Ir a iniciar sesión',
                    onTap: () {
                      context.go(AppRoutes.login);
                    },
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Componentes compartidos internos
// ═════════════════════════════════════════════════════════════════════════════

enum _InlineMessageType { error, success, info }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.type});

  final String message;
  final _InlineMessageType type;

  Color get _color {
    return switch (type) {
      _InlineMessageType.error => AppColors.error,
      _InlineMessageType.success => AppColors.success,
      _InlineMessageType.info => AppColors.primary,
    };
  }

  IconData get _icon {
    return switch (type) {
      _InlineMessageType.error => Icons.error_outline_rounded,
      _InlineMessageType.success => Icons.check_circle_outline_rounded,
      _InlineMessageType.info => Icons.info_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_icon, size: 16, color: _color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Esfera verde brillante con check blanco (misma que RegistrationSuccessScreen)
class _SuccessCheckOrb extends StatelessWidget {
  const _SuccessCheckOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Sombra difusa ──
          Positioned(
            bottom: 4,
            child: Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // ── Esfera con gradiente verde ──
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 0.85,
                colors: [
                  Color(0xFF7DDFB2),
                  Color(0xFF2ECC71),
                  Color(0xFF1FA855),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 72, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton pill con gradiente rojo suave (0xFFEE7070 → 0xFFE85555)
/// Se deshabilita cuando onTap es null (gris).
class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [Color(0xFFEE7070), Color(0xFFE85555)]
                : const [Color(0xFFCCCCCC), Color(0xFFBBBBBB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFEE7070).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // ── Decoraciones curvas en esquinas ──
            if (isEnabled) ...[
              Positioned(left: 16, top: 14, child: _CurlDecor(isLeft: true)),
              Positioned(
                right: 16,
                bottom: 14,
                child: _CurlDecor(isLeft: false),
              ),
            ],
            // ── Texto central ──
            Center(
              child: Text(
                label,
                style: AppTypography.buttonLarge.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decoraciones tipo curl en los bordes del boton
class _CurlDecor extends StatelessWidget {
  const _CurlDecor({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _CurlPainter(isLeft: isLeft),
    );
  }
}

class _CurlPainter extends CustomPainter {
  const _CurlPainter({required this.isLeft});

  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width * 0.7, 0);
      path.quadraticBezierTo(
        0,
        size.height * 0.3,
        size.width * 0.2,
        size.height,
      );
    } else {
      path.moveTo(size.width * 0.3, 0);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.7,
        size.width * 0.8,
        size.height,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Campo de correo para solicitar recuperación de contraseña.
class _EmailResetField extends StatelessWidget {
  const _EmailResetField({
    required this.controller,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.neutral300,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.only(left: 12),
            color: AppColors.neutral300,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              style: AppTypography.bodyMedium,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'correo@ejemplo.com',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de contrasena con toggle visibilidad y estado de error
class _PasswordFormField extends StatelessWidget {
  const _PasswordFormField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.neutral300,
        width: hasError ? 1.5 : 1,
      ),
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
        suffixIcon: Semantics(
          button: true,
          label: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          child: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.neutral500,
              size: 22,
            ),
          ),
        ),
        filled: true,
        fillColor: AppColors.neutral100,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
