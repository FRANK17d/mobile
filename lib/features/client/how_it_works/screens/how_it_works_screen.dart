import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';
import '../widgets/order_type_sheet.dart';

/// Pantalla "¿Cómo funciona Toke+?".
///
/// Una sola vista scrolleable que explica el flujo en 3 pasos, los motivos
/// para elegir Toke+ y un CTA "Pedir servicio" que abre el selector de tipo
/// de pedido (básico / exclusivo).
///
/// Se abre desde la card "¿Cómo funciona?" del Home.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  Future<void> _openOrderTypeSheet(BuildContext context) async {
    final type = await showOrderTypeSheet(context);
    if (type == null || !context.mounted) return;

    // Continúa al flujo "Pedir un servicio".
    // TODO: usar [type] (básico/exclusivo) cuando el wizard lo soporte.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RequestServiceWizardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          surfaceTintColor: AppColors.backgroundPrimary,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
          shadowColor: AppColors.neutral200,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Cómo funciona',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingH,
            AppSpacing.lg,
            AppSpacing.screenPaddingH,
            bottomPadding + AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título principal ──
              Text(
                '¿Cómo funciona\nToke+?',
                style: AppTypography.displayMedium.copyWith(
                  color: const Color(0xFF162033),
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Paso 1 ──
              const _HowItWorksImage(asset: AppImages.hiwStep1),
              const SizedBox(height: AppSpacing.lg),
              const _StepBlock(
                stepLabel: 'Paso 1:',
                title: 'Describe lo que necesitas',
                icon: Icons.chat_bubble_outline_rounded,
                itemTitle: 'Dilo simple y directo',
                itemBody:
                    'Ejemplo: Necesito alguien que me pueda limpiar mi '
                    'piscina, el agua esta verde y quiero recuperarla...',
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Paso 2 ──
              const _HowItWorksImage(asset: AppImages.hiwStep2),
              const SizedBox(height: AppSpacing.lg),
              const _StepBlock(
                stepLabel: 'Paso 2:',
                title: 'Recibe prestadores de servicios interesados',
                icon: Icons.verified_outlined,
                itemTitle: 'Elegí al mejor',
                itemBody:
                    'Analizá las propuestas recibidas considerando aspectos '
                    'como el presupuesto, el perfil profesional y las '
                    'valoraciones de otros clientes.',
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Paso 3 ──
              const _HowItWorksImage(asset: AppImages.hiwStep3),
              const SizedBox(height: AppSpacing.lg),
              const _StepBlock(
                stepLabel: 'Paso 3:',
                title: 'Al finalizar, calificas al prestador de servicio',
                icon: Icons.star_outline_rounded,
                itemTitle: 'Tu experiencia es clave',
                itemBody:
                    'Das tu calificación y un comentario sobre el servicio '
                    'recibido para ayudar a futuros clientes en su decisión.',
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Buscá soluciones con los mejores ──
              const _HowItWorksImage(
                asset: AppImages.hiwTrust,
                aspectRatio: 1.05,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Buscá soluciones con los mejores',
                style: AppTypography.displaySmall.copyWith(
                  color: const Color(0xFF162033),
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _Benefit(
                icon: Icons.verified_user_outlined,
                title: 'Prestadores de servicios verificados',
                body: 'Vos elegis con quien trabajar.',
              ),
              const _Benefit(
                icon: Icons.workspace_premium_outlined,
                title: 'Excelencia',
                body: 'Insignia que garantiza calidad.',
              ),
              const _Benefit(
                icon: Icons.shield_outlined,
                title: 'Confianza',
                body: 'Insignia otorgada a quienes son de confianza.',
              ),
              const _Benefit(
                icon: Icons.star_border_rounded,
                title: 'Valoraciones reales',
                body: 'Comentarios de clientes reales.',
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── CTA: Pedir servicio ──
              GradientPillButton(
                label: 'Pedir servicio',
                onTap: () => _openOrderTypeSheet(context),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Valoraciones y reseñas ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valoraciones y reseñas',
                      style: AppTypography.headingMedium.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Revisa la experiencia, habilidades y calidad de los '
                      'servicios que brinda cada profesional. La calificación '
                      'y los comentarios que recibió de anteriores trabajos. '
                      'Esto te permite asegurarte de que estás eligiendo a la '
                      'persona adecuada.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: const Color(0xFF3A3F4B),
                        height: 1.5,
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

// ─────────────────────────────────────────────────────────
// Bloque de paso: etiqueta "Paso N:" + título + item con ícono
// ─────────────────────────────────────────────────────────
class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.stepLabel,
    required this.title,
    required this.icon,
    required this.itemTitle,
    required this.itemBody,
  });

  final String stepLabel;
  final String title;
  final IconData icon;
  final String itemTitle;
  final String itemBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          title,
          style: AppTypography.displaySmall.copyWith(
            color: const Color(0xFF162033),
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.neutral700, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemTitle,
                    style: AppTypography.headingSmall.copyWith(
                      color: const Color(0xFF162033),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    itemBody,
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF5F6678),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Fila de beneficio: ícono + título + descripción
// ─────────────────────────────────────────────────────────
class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neutral700, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: const Color(0xFF162033),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF5F6678),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Imagen con placeholder: muestra un marcador si el asset
// real aún no fue agregado (errorBuilder).
// ─────────────────────────────────────────────────────────
class _HowItWorksImage extends StatelessWidget {
  const _HowItWorksImage({required this.asset, this.aspectRatio = 1.4});

  final String asset;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _ImagePlaceholder(asset: asset),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 40,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              asset.split('/').last,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
