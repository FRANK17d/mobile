import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../discover/services/discover_social_proof_service.dart';
import '../../discover/screens/social_proof_detail_screen.dart';

/// Carrusel horizontal de "Casos de éxito recientes".
///
/// Componente compartido entre el Home del cliente y la pantalla Descubrir.
class SuccessStoriesSection extends StatefulWidget {
  const SuccessStoriesSection({super.key});

  @override
  State<SuccessStoriesSection> createState() => _SuccessStoriesSectionState();
}

class _SuccessStoriesSectionState extends State<SuccessStoriesSection> {
  final DiscoverSocialProofService _service = DiscoverSocialProofService();
  late final Future<List<SocialProofItem>> _future = _service
      .getReviewBackedItems(maxItems: 6);

  void _openStoryDetail(SocialProofItem story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SocialProofDetailScreen(item: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Casos de éxito recientes',
          style: AppTypography.headingLarge.copyWith(
            color: const Color(0xFF162033),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clientes contentos que recibieron servicios.',
          style: AppTypography.bodyLarge.copyWith(
            color: const Color(0xFF5F6678),
            fontSize: 12,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<SocialProofItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _SuccessStoriesLoading();
            }

            final stories = snapshot.data ?? const <SocialProofItem>[];
            if (stories.isEmpty) return const _SuccessStoriesEmptyState();

            return SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: stories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return _SuccessStoryCard(
                    story: story,
                    onTap: () => _openStoryDetail(story),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SuccessStoriesLoading extends StatelessWidget {
  const _SuccessStoriesLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
              const _StorySkeletonLine(width: 130, height: 14),
              const SizedBox(height: 8),
              const _StorySkeletonLine(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              const _StorySkeletonLine(width: 160, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessStoriesEmptyState extends StatelessWidget {
  const _SuccessStoriesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Text(
        'Cuando haya reseñas reales de servicios completados, aparecerán aquí.',
        style: AppTypography.bodyLarge.copyWith(
          color: const Color(0xFF5F6678),
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}

class _StorySkeletonLine extends StatelessWidget {
  const _StorySkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  const _SuccessStoryCard({required this.story, required this.onTap});

  final SocialProofItem story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 220,
            height: 230,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 96,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _colorsForCategory(story.categoryName),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconForCategory(story.categoryName),
                      size: 42,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  story.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingSmall.copyWith(
                    color: const Color(0xFF162033),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  story.quote,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    color: const Color(0xFF272C3A),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${story.clientName} con ${story.providerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          color: const Color(0xFF5F6678),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF687083),
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
