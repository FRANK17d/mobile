import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final int _codeLength = 6;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    if (code.length != _codeLength) return;

    // Evitar peticiones duplicadas en paralelo si ya se está verificando
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticating) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(code);
    if (success && mounted) {
      context.go(AppRoutes.clientHome);
    }
  }

  Future<void> _resendCode() async {
    final authState = ref.read(authProvider);
    final email = authState.emailToVerify;
    if (email == null) return;

    setState(() => _isResending = true);
    final success = await AuthService().resendOtp(email);
    setState(() => _isResending = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código reenviado con éxito a tu correo.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al reenviar el código. Intenta de nuevo.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final email = authState.emailToVerify ?? 'tu correo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral800),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Verifica tu correo',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Hemos enviado un código de verificación de 6 dígitos a '),
                    TextSpan(
                      text: email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 48),

              // OTP Input Field Stack (Hidden TextField + custom grid UI)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Hidden TextField
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: _codeLength,
                      enabled: !isLoading,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (value) {
                        setState(() {});
                        if (value.length == _codeLength) {
                          _submit(value);
                        }
                      },
                    ),
                  ),

                  // Visible Digit Boxes
                  GestureDetector(
                    onTap: () {
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_codeLength, (index) {
                        final codeText = _otpController.text;
                        String char = "";
                        if (codeText.length > index) {
                          char = codeText[index];
                        }

                        final isFocused = _focusNode.hasFocus && codeText.length == index;
                        final hasValue = codeText.length > index;

                        return Container(
                          width: 46,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isFocused
                                  ? AppColors.primary
                                  : (hasValue ? AppColors.primaryLight : AppColors.border),
                              width: isFocused ? 2 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ),
                        )
                            .animate(target: isFocused ? 1 : 0)
                            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 150.ms);
                      }),
                    ),
                  ),
                ],
              ),

              // Error Message
              if (authState.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ).animate().shake(),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading || _otpController.text.length != _codeLength
                    ? null
                    : () => _submit(_otpController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Verificar Código',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              // Resend Area
              Center(
                child: Column(
                  children: [
                    Text(
                      '¿No recibiste el código?',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 6),
                    _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : TextButton(
                            onPressed: _resendCode,
                            child: Text(
                              'Reenviar código de verificación',
                              style: AppTypography.buttonSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
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
