import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../technician/account/screens/technician_profile_preview_screen.dart';
import '../services/explore_service.dart';

/// Lista global de prestadores de servicios verificados (se abre desde
/// "Descubrir" → "Prestadores de servicios").
class ProvidersListScreen extends StatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  final ExploreService _service = ExploreService();

  List<CategoryProvider> _providers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getAllProviders();
    if (!mounted) return;
    setState(() {
      _providers = list;
      _loading = false;
    });
  }

  void _openProfile(CategoryProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianPublicPreviewScreen(
          profileData: provider.toPublicProfileData(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cerrar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutral200,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Título + conteo ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.sm,
                  AppSpacing.screenPaddingH,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prestadores de servicios',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.neutral500,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _loading ? '—' : '${_providers.length}',
                      style: AppTypography.displayMedium.copyWith(
                        color: const Color(0xFF162033),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _providers.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPaddingH,
                            0,
                            AppSpacing.screenPaddingH,
                            AppSpacing.xxl,
                          ),
                          itemCount: _providers.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) => _ProviderCard(
                            provider: _providers[i],
                            onTap: () => _openProfile(_providers[i]),
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

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 56, color: AppColors.neutral300),
            const SizedBox(height: 12),
            Text(
              'Aún no hay prestadores verificados',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final CategoryProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = provider.fullName.isEmpty ? 'Técnico' : provider.fullName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox(
                width: 64,
                height: 64,
                child: provider.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: provider.avatarUrl!,
                        memCacheWidth: 160,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: AppColors.neutral200,
                          child: Icon(
                            Icons.person,
                            color: AppColors.neutral500,
                          ),
                        ),
                      )
                    : const ColoredBox(
                        color: AppColors.neutral200,
                        child: Icon(Icons.person, color: AppColors.neutral500),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (provider.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF2D9CDB),
                        ),
                      ],
                    ],
                  ),
                  if (provider.districtName != null &&
                      provider.districtName!.isNotEmpty)
                    Text(
                      provider.districtName!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (provider.bio != null &&
                      provider.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      provider.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
