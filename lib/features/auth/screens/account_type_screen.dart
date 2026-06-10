import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Pantalla de seleccion de tipo de cuenta: Cliente o Prestador de servicio.
/// Se navega aqui desde "Registrate" en login.
class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),

                // ── Flecha atras ──
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Titulo ──
                Text(
                  'Crear tu cuenta',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Selecciona el tipo de cuenta a crear.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Card: Como cliente ──
                _AccountTypeCard(
                  emoji: '\u{1F64B}\u{200D}\u{2640}\u{FE0F}',
                  title: 'Como cliente',
                  description:
                      'Quiero encontrar profesionales calificados para trabajos puntuales.',
                  onTap: () {
                    context.push('/register/client');
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Card: Prestador de servicio ──
                _AccountTypeCard(
                  emoji: '\u{1F9D1}\u{200D}\u{1F527}',
                  title: 'Prestador de servicio',
                  description:
                      'Quiero ofrecer mis servicios de manera independiente',
                  onTap: () {
                    context.push('/register/provider');
                  },
                ),

                const Spacer(),

                // ── Divider ──
                Container(
                  height: 1,
                  color: AppColors.neutral200,
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Ya tenes cuenta? ──
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tenés una cuenta? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Iniciar sesión',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card para cada tipo de cuenta.
class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            // ── Emoji en contenedor ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // ── Texto ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
