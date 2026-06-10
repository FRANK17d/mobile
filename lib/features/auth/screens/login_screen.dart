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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

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
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false, // Permite que Spacer() funcione dentro del Column
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Logo & Brand Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'tk+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 16),
                              Text(
                                'Toke+',
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Servicios al instante en tu hogar',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        Text(
                          'Iniciar Sesión',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                        const SizedBox(height: AppSpacing.md),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.md),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

                        // Error Message
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ).animate().shake(),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Submit Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
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
                                  'Ingresar',
                                  style: GoogleFonts.nunito(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ).animate().fadeIn(delay: 300.ms).scaleY(begin: 0.9, end: 1),

                        const SizedBox(height: AppSpacing.lg),

                        // Google Login Option
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o ingresa con',
                                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ).animate().fadeIn(delay: 350.ms),

                        const SizedBox(height: AppSpacing.md),

                        OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  ref.read(authProvider.notifier).loginWithGoogle();
                                },
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 20),
                          ),
                          label: Text(
                            'Google',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const Spacer(),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes cuenta? ',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                'Regístrate aquí',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
