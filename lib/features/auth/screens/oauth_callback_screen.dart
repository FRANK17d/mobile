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

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  final String? code;

  const OAuthCallbackScreen({
    super.key,
    required this.code,
  });

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processExchange();
    });
  }

  Future<void> _processExchange() async {
    final code = widget.code;
    if (code == null || code.isEmpty) {
      setState(() {
        _errorMessage = 'Código de autorización de Google no encontrado o inválido.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).exchangeOAuthCode(code);

    if (mounted) {
      if (success) {
        // Redirigir directamente al home del cliente (ya autenticado)
        context.go(AppRoutes.clientHome);
      } else {
        // El error ya está en authProvider.errorMessage, pero usamos un fallback
        final authError = ref.read(authProvider).errorMessage;
        setState(() {
          _errorMessage = authError ?? 'Error al iniciar sesión con Google. Intente nuevamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primarySurface,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null) ...[
                    // Error state
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            '¡Ups! Algo salió mal',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, AppSpacing.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Volver a Iniciar Sesión',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Loading state
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Conectando con Google...',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Estamos configurando tu cuenta de forma segura. Un momento por favor.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
