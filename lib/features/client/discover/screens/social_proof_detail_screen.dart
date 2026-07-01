import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../technician/account/screens/technician_profile_preview_screen.dart';
import '../services/discover_social_proof_service.dart';

/// Pantalla de detalle de un testimonio / caso de éxito.
///
/// Muestra la información completa del servicio completado: imágenes,
/// descripción, categoría, ubicación, fecha, reseña del cliente y
/// acceso al perfil del técnico.
class SocialProofDetailScreen extends StatelessWidget {
  const SocialProofDetailScreen({super.key, required this.item});

  final SocialProofItem item;

  @override
  Widget build(BuildContext context) {
    final review = item.review;
    final images = review.requestImageUrls;
    final hasImages = images.isNotEmpty;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasImages ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar con imagen hero ──
            _HeroAppBar(item: item, images: images),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.lg,
                  AppSpacing.screenPaddingH,
                  bottomPadding + AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Categoría + emoji ──
                    _CategoryBadge(item: item),
                    const SizedBox(height: AppSpacing.md),

                    // ── Título del pedido ──
                    Text(
                      review.requestTitle ?? item.categoryName,
                      style: AppTypography.headingLarge.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Meta: ubicación + fecha ──
                    _MetaRow(item: item),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Descripción del pedido ──
                    if (review.requestDescription != null &&
                        review.requestDescription!.trim().isNotEmpty) ...[
                      Text(
                        'Descripción del servicio',
                        style: AppTypography.titleLarge.copyWith(
                          color: const Color(0xFF162033),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        review.requestDescription!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: const Color(0xFF5F6678),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Galería adicional (si > 1 imagen) ──
                    if (images.length > 1) ...[
                      Text(
                        'Fotos del trabajo',
                        style: AppTypography.titleLarge.copyWith(
                          color: const Color(0xFF162033),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ImageGallery(images: images),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Reseña del cliente ──
                    _ClientReviewCard(item: item),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Prestador ──
                    _ProviderCard(item: item),
                    const SizedBox(height: AppSpacing.lg),

                    // ── CTA ──
                    GradientPillButton(
                      label: 'Ver perfil del prestador',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TechnicianPublicPreviewScreen(
                            profileData: item.toPublicProfileData(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero AppBar con imagen o gradiente
// ─────────────────────────────────────────────────────────
class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.item, required this.images});

  final SocialProofItem item;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final hasImage = images.isNotEmpty;
    final categoryName = item.review.categoryName ?? item.categoryName;

    return SliverAppBar(
      expandedHeight: hasImage ? 280 : 180,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.backgroundPrimary,
      surfaceTintColor: AppColors.backgroundPrimary,
      leading: _CircleBackButton(light: hasImage),
      flexibleSpace: FlexibleSpaceBar(
        background: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: images.first,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    errorWidget: (_, _, _) =>
                        _GradientHero(categoryName: categoryName),
                  ),
                  // Gradiente inferior para legibilidad
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x80000000)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _GradientHero(categoryName: categoryName),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          decoration: BoxDecoration(
            color: light
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.neutral100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_rounded,
            color: light ? Colors.white : AppColors.neutral800,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _GradientHero extends StatelessWidget {
  const _GradientHero({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForCategory(categoryName);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          _iconForCategory(categoryName),
          size: 64,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Badge de categoría
// ─────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.item});

  final SocialProofItem item;

  @override
  Widget build(BuildContext context) {
    final emoji = item.review.categoryEmoji ?? '';
    final name = item.categoryName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        emoji.isNotEmpty ? '$emoji  $name' : name,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Fila de metadata: ubicación + fecha
// ─────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final SocialProofItem item;

  @override
  Widget build(BuildContext context) {
    final district = item.review.districtName ?? item.location;
    final completedAt = item.review.requestCompletedAt ?? item.review.createdAt;
    final dateStr = completedAt != null
        ? DateFormat("d 'de' MMMM, yyyy", 'es').format(completedAt)
        : null;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (district.isNotEmpty)
          _MetaChip(icon: Icons.location_on_outlined, text: district),
        if (dateStr != null)
          _MetaChip(icon: Icons.calendar_today_outlined, text: dateStr),
        if (item.review.requestOrderNumber != null)
          _MetaChip(
            icon: Icons.tag_rounded,
            text: 'Pedido #${item.review.requestOrderNumber}',
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Galería horizontal de imágenes
// ─────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openFullImage(context, images[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: CachedNetworkImage(
                imageUrl: images[index],
                width: 200,
                height: 160,
                fit: BoxFit.cover,
                memCacheWidth: 500,
                errorWidget: (_, _, _) => Container(
                  width: 200,
                  height: 160,
                  color: AppColors.neutral100,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.neutral400,
                    size: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFullImage(BuildContext context, String url) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _FullImageViewer(url: url)));
  }
}

// ─────────────────────────────────────────────────────────
// Visor de imagen a pantalla completa
// ─────────────────────────────────────────────────────────
class _FullImageViewer extends StatelessWidget {
  const _FullImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card de reseña del cliente
// ─────────────────────────────────────────────────────────
class _ClientReviewCard extends StatelessWidget {
  const _ClientReviewCard({required this.item});

  final SocialProofItem item;

  @override
  Widget build(BuildContext context) {
    final review = item.review;
    final quote = item.quote;
    if (quote.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar del cliente
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child:
                      review.clientAvatarUrl != null &&
                          review.clientAvatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: review.clientAvatarUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.neutral200,
                            child: Icon(
                              Icons.person,
                              size: 22,
                              color: AppColors.neutral500,
                            ),
                          ),
                        )
                      : const ColoredBox(
                          color: AppColors.neutral200,
                          child: Icon(
                            Icons.person,
                            size: 22,
                            color: AppColors.neutral500,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName,
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          color: i < review.rating
                              ? AppColors.starFilled
                              : AppColors.neutral300,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Text(
              '"$quote"',
              style: AppTypography.bodyLarge.copyWith(
                color: const Color(0xFF4A5163),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card del prestador
// ─────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.item});

  final SocialProofItem item;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = item.provider.avatarUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              width: 56,
              height: 56,
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 140,
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: AppColors.neutral100,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.neutral400,
                          size: 28,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.neutral100,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.neutral400,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.providerName,
                  style: AppTypography.titleLarge.copyWith(
                    color: const Color(0xFF162033),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.categoryName}  ·  ${item.reviewCount} valoraciones',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF5F6678),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.neutral500,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Helpers de categoría (reutilizados de success_stories)
// ─────────────────────────────────────────────────────────
IconData _iconForCategory(String category) {
  final value = category.toLowerCase();
  if (value.contains('electric')) return Icons.electrical_services_rounded;
  if (value.contains('plomer') || value.contains('gasf')) {
    return Icons.plumbing_rounded;
  }
  if (value.contains('limp') || value.contains('lav')) {
    return Icons.cleaning_services_rounded;
  }
  if (value.contains('jardin') || value.contains('pint')) {
    return Icons.grass_rounded;
  }
  if (value.contains('constru') || value.contains('alba')) {
    return Icons.handyman_rounded;
  }
  return Icons.home_repair_service_rounded;
}

List<Color> _colorsForCategory(String category) {
  final value = category.toLowerCase();
  if (value.contains('electric')) {
    return const [Color(0xFFFFD56B), Color(0xFFE08C2B)];
  }
  if (value.contains('plomer') || value.contains('gasf')) {
    return const [Color(0xFFD7F1FF), Color(0xFF4F9FCA)];
  }
  if (value.contains('limp') || value.contains('lav')) {
    return const [Color(0xFFDCEBFF), Color(0xFF86B4F5)];
  }
  if (value.contains('jardin') || value.contains('pint')) {
    return const [Color(0xFFDDF4D2), Color(0xFF68A857)];
  }
  if (value.contains('constru') || value.contains('alba')) {
    return const [Color(0xFFE1C8AE), Color(0xFF8B5A3C)];
  }
  return const [Color(0xFFE9EDF7), Color(0xFF75839A)];
}
