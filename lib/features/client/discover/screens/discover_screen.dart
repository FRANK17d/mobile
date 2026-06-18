import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../auth/screens/provider_registration_screen.dart';
import '../../../auth/services/auth_store.dart';
import '../../home/widgets/social_media_section.dart';
import '../../home/widgets/success_stories_section.dart';
import '../../how_it_works/screens/how_it_works_screen.dart';
import '../../how_it_works/widgets/order_type_sheet.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';

/// Pantalla "Descubrir".
///
/// Una sola vista scrolleable, accesible desde la card "Descubrir" del Home.
/// Reúne métricas de la plataforma, motivos para elegir Toke+, captación de
/// prestadores, testimonios, pasos rápidos, casos de éxito, noticias y redes.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  Future<void> _openRequestFlow(BuildContext context) async {
    final type = await showOrderTypeSheet(context);
    if (type == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RequestServiceWizardScreen(),
      ),
    );
  }

  void _openHowItWorks(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HowItWorksScreen()));
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
            'Descubrir',
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
              // ── 1. Creciendo juntos ──
              const _GrowingTogetherSection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── 2. Soluciones con los mejores ──
              _SolutionsCard(
                onRequest: () => _openRequestFlow(context),
                onHowItWorks: () => _openHowItWorks(context),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 3. Ofrecé tus servicios y generá más ingresos ──
              const _BecomeProviderCard(),
              const SizedBox(height: AppSpacing.xxl),

              // ── 4. Testimonios ──
              const _TestimonialsSection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── 5. Publicá tu pedido en segundos ──
              _QuickStepsSection(
                onRequest: () => _openRequestFlow(context),
                onHowItWorks: () => _openHowItWorks(context),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 6. Casos de éxito recientes (reutilizado del Home) ──
              const SuccessStoriesSection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── 7. Noticias y novedades ──
              const _NewsSection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── 8. Nuestras redes sociales (reutilizado del Home) ──
              const SocialMediaSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 1. Creciendo juntos: métricas de la plataforma
// ─────────────────────────────────────────────────────────
class _GrowingTogetherSection extends StatelessWidget {
  const _GrowingTogetherSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.neutral200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Creciendo juntos',
                style: AppTypography.headingLarge.copyWith(
                  color: const Color(0xFF162033),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.neutral200)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _StatTile(
          emoji: '📣',
          value: '+3650',
          label: 'Pedidos realizados',
          showChevron: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StatTile(
          emoji: '🧰',
          value: '+2686',
          label: 'Prestadores de servicios',
          showChevron: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _StatTile(
          emoji: '👨‍👩‍👧',
          value: '+5458',
          label: 'Usuarios / Clientes',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
    this.showChevron = false,
  });

  final String emoji;
  final String value;
  final String label;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.displaySmall.copyWith(
                    color: const Color(0xFF162033),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: const Color(0xFF5F6678),
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral500,
              size: 26,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 2. Soluciones con los mejores
// ─────────────────────────────────────────────────────────
class _SolutionsCard extends StatelessWidget {
  const _SolutionsCard({required this.onRequest, required this.onHowItWorks});

  final VoidCallback onRequest;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soluciones con los mejores',
            style: AppTypography.displaySmall.copyWith(
              color: const Color(0xFF162033),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _BenefitRow(
            icon: Icons.verified_user_outlined,
            title: 'Postulantes verificados',
            body: 'Vos elegis con quien trabajar.',
          ),
          const _BenefitRow(
            icon: Icons.workspace_premium_outlined,
            title: 'Excelencia',
            body: 'Insignia que garantiza calidad.',
          ),
          const _BenefitRow(
            icon: Icons.shield_outlined,
            title: 'Confianza',
            body: 'Insignia otorgada a quienes son de confianza.',
          ),
          const _BenefitRow(
            icon: Icons.star_border_rounded,
            title: 'Valoraciones reales',
            body: 'Comentarios de clientes reales.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GradientPillButton(
                  label: 'Pedir servicio',
                  onTap: onRequest,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OutlinedPillButton(
                  label: '¿Cómo funciona?',
                  onTap: onHowItWorks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
// 3. Ofrecé tus servicios y generá más ingresos
// ─────────────────────────────────────────────────────────
class _BecomeProviderCard extends StatelessWidget {
  const _BecomeProviderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Ofrecé tus servicios y generá más ingresos',
                  style: AppTypography.displaySmall.copyWith(
                    color: const Color(0xFF162033),
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('🧰', style: TextStyle(fontSize: 48)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Con nuestra plataforma, podrás conectarte con nuevos clientes que '
            'están buscando profesionales en tu zona de cobertura.',
            style: AppTypography.bodyLarge.copyWith(
              color: const Color(0xFF5F6678),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _OutlinedPillButton(
            label: 'Gana dinero con Toke+',
            onTap: () {
              if (!AuthStore.instance.value.isAuthenticated) {
                context.push(AppRoutes.login);
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProviderRegistrationScreen(
                    convertToTechnician: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 4. Testimonios
// ─────────────────────────────────────────────────────────
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Testimonios',
            style: AppTypography.displaySmall.copyWith(
              color: const Color(0xFF162033),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 430,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _testimonials.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _TestimonialCard(data: _testimonials[index]),
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.data});

  final _TestimonialData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (placeholder hasta tener las fotos reales).
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 86,
                  height: 86,
                  color: AppColors.neutral100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.neutral400,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: AppTypography.headingMedium.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      data.location,
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF5F6678),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.starFilled,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${data.rating} (${data.reviews} valoraciones)',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF5F6678),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.profession,
            style: AppTypography.titleLarge.copyWith(
              color: const Color(0xFF162033),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF5F6678),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.neutral300, width: 3),
              ),
            ),
            child: Text(
              data.quote,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF7A8092),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // TODO: abrir el perfil del prestador.
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                'Ver perfil  →',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialData {
  const _TestimonialData({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.profession,
    required this.description,
    required this.quote,
  });

  final String name;
  final String location;
  final String rating;
  final int reviews;
  final String profession;
  final String description;
  final String quote;
}

const _testimonials = [
  _TestimonialData(
    name: 'Rubén',
    location: 'Mariano Roque Alonso',
    rating: '5',
    reviews: 3,
    profession: 'Contratista y Albañil',
    description:
        'Rubén con más de 20 años de experiencia en el rubro de la '
        'construcción y albañilería, se sumó a Toke+ para brindar y '
        'expandir aún más su alcance.',
    quote:
        'La posibilidad de ofrecer mis servicios y la oportunidad de acceder '
        'a más oportunidades de trabajo es algo que me tiene muy contento.',
  ),
  _TestimonialData(
    name: 'Leonardo',
    location: 'Lambaré',
    rating: '5',
    reviews: 24,
    profession: 'Electricista, Plomero y más...',
    description:
        'Leonardo dispuesto a servir en todo lo que esté a su alcance, con '
        'diversas habilidades que hacen su destaque. Su compromiso con la '
        'excelencia y trato con las personas es algo que se aplaude.',
    quote:
        'Gracias a Toke+ por confiar en mí. Estoy para servir y lo hago con '
        'excelencia y calidad. Para mí es importante siempre dar el 100%.',
  ),
];

// ─────────────────────────────────────────────────────────
// 5. Publicá tu pedido en segundos
// ─────────────────────────────────────────────────────────
class _QuickStepsSection extends StatelessWidget {
  const _QuickStepsSection({
    required this.onRequest,
    required this.onHowItWorks,
  });

  final VoidCallback onRequest;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publicá tu pedido en segundos',
          style: AppTypography.displayMedium.copyWith(
            color: const Color(0xFF162033),
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _NumberedStep(number: '1', text: 'Describe lo que necesitas'),
        const SizedBox(height: AppSpacing.md),
        const _NumberedStep(
          number: '2',
          text: 'Recibí interesados y elegí con quien trabajar',
        ),
        const SizedBox(height: AppSpacing.xl),
        GradientPillButton(label: 'Pedir servicio', onTap: onRequest),
        const SizedBox(height: AppSpacing.sm),
        _OutlinedPillButton(label: '¿Cómo funciona?', onTap: onHowItWorks),
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFDDE6F7),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.headingMedium.copyWith(
              color: const Color(0xFF5B7AB5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.headingSmall.copyWith(
              color: const Color(0xFF4A5163),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 7. Noticias y novedades
// ─────────────────────────────────────────────────────────
class _NewsSection extends StatelessWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Noticias y novedades',
          style: AppTypography.headingLarge.copyWith(
            color: const Color(0xFF162033),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toke+ ganadora de InnovandoPY 2025',
                      style: AppTypography.titleLarge.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Recibe capital semilla para impulsar Toke+ al '
                      'siguiente nivel.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF5F6678),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Imagen de la noticia (placeholder hasta tener el asset real).
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 120,
                  height: 90,
                  color: AppColors.neutral100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.neutral400,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Botón pill con borde (acción secundaria)
// ─────────────────────────────────────────────────────────
class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.neutral400),
        ),
        child: Text(
          label,
          style: AppTypography.buttonLarge.copyWith(
            color: const Color(0xFF162033),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
