import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Carrusel horizontal de "Casos de éxito recientes".
///
/// Componente compartido entre el Home del cliente y la pantalla Descubrir.
class SuccessStoriesSection extends StatelessWidget {
  const SuccessStoriesSection({super.key});

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
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _successStories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final story = _successStories[index];
              return _SuccessStoryCard(story: story);
            },
          ),
        ),
      ],
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  const _SuccessStoryCard({required this.story});

  final _SuccessStoryData story;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: story.colors,
              ),
            ),
            child: Center(
              child: Icon(
                story.icon,
                size: 44,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.name,
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
                      story.comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: const Color(0xFF272C3A),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
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
    );
  }
}

class _SuccessStoryData {
  const _SuccessStoryData({
    required this.name,
    required this.comment,
    required this.icon,
    required this.colors,
  });

  final String name;
  final String comment;
  final IconData icon;
  final List<Color> colors;
}

const _successStories = [
  _SuccessStoryData(
    name: 'Lorena F.',
    comment: 'Buen servicio, bien explicado y rápido',
    icon: Icons.local_laundry_service_rounded,
    colors: [Color(0xFFDCEBFF), Color(0xFFB6D2FF)],
  ),
  _SuccessStoryData(
    name: 'Sehila C.',
    comment: 'Muy responsables, buen trabajo, me gusta trabajar así',
    icon: Icons.fence_rounded,
    colors: [Color(0xFFD9C0A7), Color(0xFF7B4E35)],
  ),
  _SuccessStoryData(
    name: 'Carlos M.',
    comment: 'Llegaron a tiempo y resolvieron todo sin complicaciones',
    icon: Icons.plumbing_rounded,
    colors: [Color(0xFFD7F1FF), Color(0xFF6CB6DD)],
  ),
];
