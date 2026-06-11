import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/insforge_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../services/auth_service.dart';

/// Pantalla de verificación de email OTP para registro.
/// Después de verificar, completa el perfil app según el rol.
class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({
    super.key,
    required this.email,
    required this.registrationData,
  });

  final String email;
  final Map<String, dynamic> registrationData;

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final AuthService _authService = AuthService();
  final InsForgeClient _client = InsForgeClient();

  bool _isVerifying = false;
  bool _isCompletingProfile = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _timer;
  bool _isApplyingOtp = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

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
      _verifyAndComplete();
    }
  }

  void _handleOtpChanged(String value, int index) {
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
      _verifyAndComplete();
    }
  }

  KeyEventResult _handleOtpKeyEvent(KeyEvent event, int index) {
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

  Future<void> _verifyAndComplete() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Paso 1: Verificar email con OTP
    final userId = await _authService.verifyEmail(widget.email, _otpCode);

    if (userId == null) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Código incorrecto. Inténtalo de nuevo.';
      });
      return;
    }

    // Paso 2: Completar perfil de técnico
    setState(() {
      _isVerifying = false;
      _isCompletingProfile = true;
    });

    await _completeProfile(userId);
  }

  Future<void> _completeProfile(String userId) async {
    final data = widget.registrationData;
    final role = data['role'] as String? ?? 'provider';

    if (role == 'client') {
      final clientData = ClientRegistrationData(
        firstName: data['name'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        district: data['district'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        email: widget.email,
        password: data['password'] as String? ?? '',
      );

      final result = await _authService.completeClientProfile(
        userId: userId,
        data: clientData,
      );

      if (!mounted) return;

      if (result.success) {
        context.go('/register/success', extra: 'client');
      } else {
        setState(() {
          _isCompletingProfile = false;
          _errorMessage = result.message;
        });
      }
      return;
    }

    // Upload foto si existe
    String? avatarUrl;
    final photoPath = data['photo'] as String?;
    if (photoPath != null && photoPath.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = photoPath.split('.').last.toLowerCase();
      final objectKey = 'technicians/$userId/avatar-$timestamp.$ext';

      final uploadResult = await _client.uploadFile(
        bucket: 'avatars',
        filePath: photoPath,
        objectKey: objectKey,
      );

      if (uploadResult != null) {
        avatarUrl = uploadResult['url'];
      }
    }

    // Llamar RPC register_technician
    final techData = TechnicianRegistrationData(
      firstName: data['name'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      dni: data['dni'] as String? ?? '',
      district: data['district'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: widget.email,
      password: data['password'] as String? ?? '',
      avatarUrl: avatarUrl,
      categories: List<String>.from(data['categories'] ?? []),
    );

    final result = await _authService.completeTechnicianProfile(techData);

    if (!mounted) return;

    if (result.success) {
      context.go('/register/success', extra: 'provider');
    } else {
      setState(() {
        _isCompletingProfile = false;
        _errorMessage = result.message;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;

    final success = await _authService.resendOtp(widget.email);
    if (success) {
      _startCooldown();
      if (mounted) {
        showAppToast(
          context,
          message: 'Código reenviado a tu correo',
          type: ToastType.success,
          duration: const Duration(seconds: 2),
        );
      }
    }
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
            child: _isCompletingProfile
                ? _buildCompletingView()
                : _buildOtpView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Completando tu perfil...',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guardando tus datos y foto de perfil',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpView() {
    final maskedEmail = _maskEmail(widget.email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),

        // Flecha atrás
        Semantics(
          button: true,
          label: 'Volver atrás',
          child: GestureDetector(
            onTap: () {
              // Si no hay nada que desapilar (se llegó con go()), volvemos al
              // inicio del registro para no dejar la pantalla en negro.
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/register');
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Título
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

        // Subtítulo
        RichText(
          text: TextSpan(
            text: 'Ingresa el código de 6 dígitos que enviamos a ',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: maskedEmail,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        // Campos OTP
        Semantics(
          label: 'Código de verificación de 6 dígitos',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                height: 58,
                child: Semantics(
                  textField: true,
                  label: 'Dígito ${index + 1} de 6',
                  child: Focus(
                    onKeyEvent: (_, event) => _handleOtpKeyEvent(event, index),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == 5
                          ? TextInputAction.done
                          : TextInputAction.next,
                      cursorColor: AppColors.primary,
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _errorMessage != null
                            ? AppColors.error.withValues(alpha: 0.06)
                            : AppColors.neutral100,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? AppColors.error
                                : Colors.transparent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? AppColors.error
                                : Colors.transparent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? AppColors.error
                                : AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onTap: () => _placeCursorAtStart(index),
                      onChanged: (value) => _handleOtpChanged(value, index),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),

        // Reenviar código
        Center(
          child: GestureDetector(
            onTap: _resendCooldown == 0 ? _resendOtp : null,
            child: RichText(
              text: TextSpan(
                text: '¿No recibiste el código? ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: _resendCooldown > 0
                        ? 'Reenviar en ${_resendCooldown}s'
                        : 'Reenviar',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _resendCooldown > 0
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // Botón verificar (por si el auto-verify no funciona)
        if (_isVerifying)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isOtpComplete ? _verifyAndComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.neutral200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Verificar',
                  style: AppTypography.buttonLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 3) return email;
    return '${name.substring(0, 2)}${'*' * (name.length - 3)}${name[name.length - 1]}@${parts[1]}';
  }
}
