import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Sección "Nuestras redes sociales" con scroll horizontal de íconos.
///
/// Componente compartido entre el Home del cliente y la pantalla Descubrir.
class SocialMediaSection extends StatelessWidget {
  const SocialMediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nuestras redes sociales',
          style: AppTypography.headingLarge.copyWith(
            color: const Color(0xFF162033),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enterate primero. Seguinos y mantenete al día.',
          style: AppTypography.bodyLarge.copyWith(
            color: const Color(0xFF5F6678),
            fontSize: 12,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _socialLinks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final social = _socialLinks[index];
              return _SocialCard(social: social);
            },
          ),
        ),
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.social});

  final _SocialLinkData social;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              social.assetPath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              cacheWidth: 144,
              cacheHeight: 144,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            social.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: const Color(0xFF3A3F4B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkData {
  const _SocialLinkData({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

const _socialLinks = [
  _SocialLinkData(
    label: 'WhatsApp',
    assetPath: 'assets/images/icon-whatssap.png',
  ),
  _SocialLinkData(label: 'Instagram', assetPath: 'assets/images/icon-ig.png'),
  _SocialLinkData(
    label: 'YouTube',
    assetPath: 'assets/images/icon-youtube.png',
  ),
  _SocialLinkData(label: 'TikTok', assetPath: 'assets/images/icon-tiktok.png'),
  _SocialLinkData(
    label: 'Facebook',
    assetPath: 'assets/images/icon-facebook.png',
  ),
  _SocialLinkData(label: 'Web', assetPath: 'assets/images/icon-web.png'),
];
