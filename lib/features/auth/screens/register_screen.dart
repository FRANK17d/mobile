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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

    if (success && mounted) {
      context.push(AppRoutes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Crear Cuenta',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Regístrate para solicitar servicios en segundos',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 50.ms),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
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
                      return 'Por favor ingresa tu nombre completo';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Por favor ingresa nombre y apellido';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.md),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
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
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.md),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
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
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.md),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
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
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
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

                const SizedBox(height: AppSpacing.xl),

                // Register Button
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
                          'Registrarse',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ).animate().fadeIn(delay: 300.ms).scaleY(begin: 0.9, end: 1),

                const SizedBox(height: 30),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Inicia sesión',
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
    );
  }
}
