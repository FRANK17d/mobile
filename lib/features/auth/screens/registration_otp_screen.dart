import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/insforge_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../../core/widgets/inputs/otp_code_input.dart';
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
  final AuthService _authService = AuthService();
  final InsForgeClient _client = InsForgeClient();

  String _otp = '';
  bool _isVerifying = false;
  bool _isCompletingProfile = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
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

  void _onOtpChanged(String code) {
    _otp = code;
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_otp.length != 6 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Paso 1: Verificar email con OTP
    final userId = await _authService.verifyEmail(widget.email, _otp);

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Código incorrecto. Inténtalo de nuevo.';
      });
      return;
    }

    // Paso 2: Completar perfil
    if (!mounted) return;
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
        districtId: data['districtId'] as int?,
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
      districtId: data['districtId'] as int?,
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

        // Campos OTP (widget compartido y robusto).
        OtpCodeInput(
          hasError: _errorMessage != null,
          onChanged: _onOtpChanged,
          onCompleted: (code) {
            _otp = code;
            _verifyAndComplete();
          },
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
                onPressed: _otp.length == 6 ? _verifyAndComplete : null,
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
