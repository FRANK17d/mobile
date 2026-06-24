import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../services/work_posts_service.dart';

class TechnicianPublicPreviewScreen extends StatefulWidget {
  const TechnicianPublicPreviewScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<TechnicianPublicPreviewScreen> createState() =>
      _TechnicianPublicPreviewScreenState();
}

class _TechnicianPublicPreviewScreenState
    extends State<TechnicianPublicPreviewScreen> {
  final WorkPostsService _workPostsService = WorkPostsService();
  List<TechnicianWorkPost> _workPosts = const [];
  bool _loadingWorkPosts = true;

  @override
  void initState() {
    super.initState();
    final data = _TechnicianProfileViewData.from(widget.profileData);
    if (data.technicianId.isEmpty) {
      _loadingWorkPosts = false;
    } else {
      _loadWorkPosts(data.technicianId);
    }
  }

  Future<void> _loadWorkPosts(String technicianId) async {
    final posts = await _workPostsService.getPublicPosts(technicianId);
    if (!mounted) return;
    setState(() {
      _workPosts = posts;
      _loadingWorkPosts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _TechnicianProfileViewData.from(widget.profileData);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.secondaryDark,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _PublicProfileHero(data: data),
              _PublicProfileDetails(
                data: data,
                workPosts: _workPosts,
                loadingWorkPosts: _loadingWorkPosts,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 80),
                color: AppColors.secondaryDark,
                child: Text(
                  data.joinedLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
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

class TechnicianShareCardScreen extends StatefulWidget {
  const TechnicianShareCardScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<TechnicianShareCardScreen> createState() =>
      _TechnicianShareCardScreenState();
}

class _TechnicianShareCardScreenState extends State<TechnicianShareCardScreen> {
  bool _showBio = true;
  bool _showPhone = false;
  bool _showServices = true;
  bool _showCustomize = false;
  bool _isSharing = false;

  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 80),
      );

      if (imageBytes == null || !mounted) {
        setState(() => _isSharing = false);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/toke_ficha.png');
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Mi ficha de Toke+'),
      );
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          message: 'No se pudo compartir la imagen',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _TechnicianProfileViewData.from(widget.profileData);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShareTopBar(title: 'Compartir ficha'),
                const SizedBox(height: AppSpacing.xxxl),
                Screenshot(
                  controller: _screenshotController,
                  child: _SharePreviewCard(
                    data: data,
                    showBio: _showBio,
                    showPhone: _showPhone,
                    showServices: _showServices,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _ShareControlsPanel(
          showBio: _showBio,
          showPhone: _showPhone,
          showServices: _showServices,
          showCustomize: _showCustomize,
          isSharing: _isSharing,
          onBioChanged: (value) => setState(() => _showBio = value),
          onPhoneChanged: (value) => setState(() => _showPhone = value),
          onServicesChanged: (value) => setState(() => _showServices = value),
          onShare: _shareImage,
          onEdit: () => setState(() => _showCustomize = !_showCustomize),
        ),
      ),
    );
  }
}

class _PublicProfileHero extends StatelessWidget {
  const _PublicProfileHero({required this.data});

  final _TechnicianProfileViewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      decoration: const BoxDecoration(color: AppColors.secondaryDark),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconAction(
                  icon: Icons.arrow_back_rounded,
                  label: 'Volver',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _RoundIconAction(
                  icon: Icons.share_rounded,
                  label: 'Compartir ficha',
                  onTap: () => _pushAccountDetailScreen(
                    context,
                    TechnicianShareCardScreen(profileData: data.rawProfileData),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'toke+',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 86,
                    color: Colors.white.withValues(alpha: 0.035),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                  ),
                ),
                _ProfilePhoto(
                  avatarUrl: data.avatarUrl,
                  size: 110,
                  borderRadius: 24,
                  isVerified: data.isVerified,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              data.fullName,
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge.copyWith(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileDetails extends StatelessWidget {
  const _PublicProfileDetails({
    required this.data,
    required this.workPosts,
    required this.loadingWorkPosts,
  });

  final _TechnicianProfileViewData data;
  final List<TechnicianWorkPost> workPosts;
  final bool loadingWorkPosts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.bio,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.42,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('Servicios que brinda'),
          const SizedBox(height: AppSpacing.lg),
          ...data.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _PreviewServiceRow(service: service),
            ),
          ),
          if (loadingWorkPosts || workPosts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle('Trabajos publicados'),
            const SizedBox(height: AppSpacing.md),
            _PublicWorkPostsSection(
              posts: workPosts,
              loading: loadingWorkPosts,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('Zonas de cobertura'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.district,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Provincia de Trujillo - Perú',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTopBar extends StatelessWidget {
  const _ShareTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PlainIconAction(
          icon: Icons.arrow_back_rounded,
          label: 'Volver',
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            title,
            style: AppTypography.displaySmall.copyWith(
              fontSize: 22,
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SharePreviewCard extends StatelessWidget {
  const _SharePreviewCard({
    required this.data,
    required this.showBio,
    required this.showPhone,
    required this.showServices,
  });

  final _TechnicianProfileViewData data;
  final bool showBio;
  final bool showPhone;
  final bool showServices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.09),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                ..._shareCardGhosts(data.services),
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    'toke+',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfilePhoto(
                        avatarUrl: data.avatarUrl,
                        size: 100,
                        borderRadius: 20,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        data.fullName,
                        textAlign: TextAlign.center,
                        style: AppTypography.displaySmall.copyWith(
                          fontSize: 24,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            data.district,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            color: const Color(0xFFF4F6FA),
            child: Column(
              children: [
                if (showBio) ...[
                  Text(
                    data.bio,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      fontSize: 15,
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (showServices)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: data.services.map(_ShareServiceChip.new).toList(),
                  ),
                if (showPhone && data.phoneLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        data.phoneLabel,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareControlsPanel extends StatelessWidget {
  const _ShareControlsPanel({
    required this.showBio,
    required this.showPhone,
    required this.showServices,
    required this.showCustomize,
    required this.isSharing,
    required this.onBioChanged,
    required this.onPhoneChanged,
    required this.onServicesChanged,
    required this.onShare,
    required this.onEdit,
  });

  final bool showBio;
  final bool showPhone;
  final bool showServices;
  final bool showCustomize;
  final bool isSharing;
  final ValueChanged<bool> onBioChanged;
  final ValueChanged<bool> onPhoneChanged;
  final ValueChanged<bool> onServicesChanged;
  final VoidCallback onShare;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          border: Border.all(color: AppColors.borderLight),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onShare,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.26),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isSharing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Compartir imagen',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (showCustomize) ...[
              Text(
                'Personalizar contenido',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _ShareToggleRow(
                label: 'Texto de Presentación',
                value: showBio,
                onChanged: onBioChanged,
              ),
              _ShareToggleRow(
                label: 'Número de teléfono',
                value: showPhone,
                onChanged: onPhoneChanged,
              ),
              _ShareToggleRow(
                label: 'Lista de servicios',
                value: showServices,
                onChanged: onServicesChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareToggleRow extends StatelessWidget {
  const _ShareToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.82,
          child: Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.neutral400,
            onChanged: onChanged,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewServiceRow extends StatelessWidget {
  const _PreviewServiceRow({required this.service});

  final _ServiceViewData service;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(service.emoji, style: const TextStyle(fontSize: 28)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.title,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                service.description,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicWorkPostsSection extends StatelessWidget {
  const _PublicWorkPostsSection({required this.posts, required this.loading});

  final List<TechnicianWorkPost> posts;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 146,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) =>
            _PublicWorkPostCard(post: posts[index]),
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemCount: posts.length,
      ),
    );
  }
}

class _PublicWorkPostCard extends StatelessWidget {
  const _PublicWorkPostCard({required this.post});

  final TechnicianWorkPost post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const _WorkPostFallback(),
            )
          else
            const _WorkPostFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.secondaryDark.withValues(alpha: 0.74),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkPostFallback extends StatelessWidget {
  const _WorkPostFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.secondaryLight,
      child: Center(
        child: Icon(Icons.image_outlined, color: Colors.white70, size: 42),
      ),
    );
  }
}

class _ShareServiceChip extends StatelessWidget {
  const _ShareServiceChip(this.service);

  final _ServiceViewData service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(service.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            service.title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.avatarUrl,
    required this.size,
    required this.borderRadius,
    this.isVerified = false,
  });

  final String? avatarUrl;
  final double size;
  final double borderRadius;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarUrl;
    final photo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    _ProfilePhotoFallback(size: size),
              ),
            )
          : _ProfilePhotoFallback(size: size),
    );

    if (!isVerified) return photo;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        photo,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoFallback extends StatelessWidget {
  const _ProfilePhotoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_outline_rounded,
      color: Colors.white.withValues(alpha: 0.78),
      size: size * 0.48,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.displaySmall.copyWith(
        fontSize: 22,
        color: AppColors.secondaryDark,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
      ),
    );
  }
}

class _RoundIconAction extends StatelessWidget {
  const _RoundIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _PlainIconAction extends StatelessWidget {
  const _PlainIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.secondaryDark, size: 28),
        ),
      ),
    );
  }
}

List<Widget> _shareCardGhosts(List<_ServiceViewData> services) {
  final source = services.isEmpty
      ? const [
          _ServiceViewData(
            title: 'Servicio',
            emoji: '🔧',
            description: 'Servicio profesional.',
          ),
        ]
      : services;

  return [
    Positioned(
      left: 34,
      top: 24,
      child: _GhostEmoji(source.first.emoji, opacity: 0.09),
    ),
    Positioned(
      right: 52,
      top: 72,
      child: _GhostEmoji(
        source[source.length > 1 ? 1 : 0].emoji,
        opacity: 0.08,
      ),
    ),
    Positioned(
      left: 86,
      bottom: 52,
      child: _GhostEmoji(source.last.emoji, opacity: 0.07),
    ),
    const Positioned(
      right: 18,
      bottom: 38,
      child: _GhostEmoji('t+', opacity: 0.045, textSize: 40),
    ),
  ];
}

class _GhostEmoji extends StatelessWidget {
  const _GhostEmoji(this.text, {required this.opacity, this.textSize = 36});

  final String text;
  final double opacity;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Text(text, style: TextStyle(fontSize: textSize)),
    );
  }
}

void _pushAccountDetailScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _TechnicianProfileViewData {
  const _TechnicianProfileViewData({
    required this.rawProfileData,
    required this.technicianId,
    required this.firstName,
    required this.fullName,
    required this.bio,
    required this.district,
    required this.phoneLabel,
    required this.avatarUrl,
    required this.services,
    required this.joinedLabel,
    required this.isVerified,
  });

  final Map<String, dynamic>? rawProfileData;
  final String technicianId;
  final String firstName;
  final String fullName;
  final String bio;
  final String district;
  final String phoneLabel;
  final String? avatarUrl;
  final List<_ServiceViewData> services;
  final String joinedLabel;
  final bool isVerified;

  static String _joinedLabel(DateTime? d) {
    if (d == null) return 'Miembro de Toke+';
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return 'Se unió a Toke+ en ${months[d.month - 1]} de ${d.year}';
  }

  static _TechnicianProfileViewData from(Map<String, dynamic>? profileData) {
    final technician = _asMap(profileData?['technician']);
    final firstName = _firstString(
      [profileData, technician],
      ['first_name', 'firstName', 'name', 'nombre'],
    );
    final lastName = _firstString(
      [profileData, technician],
      ['last_name', 'lastName', 'surname', 'apellido'],
    );
    final fullName = '$firstName $lastName'.trim();

    final createdAtRaw = _firstValue(
      [profileData, technician],
      ['created_at', 'createdAt'],
    );
    final joinedAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    final status = _firstString(
      [technician, profileData],
      ['verification_status'],
    );

    return _TechnicianProfileViewData(
      rawProfileData: profileData,
      technicianId: _firstString(
        [profileData, technician],
        ['id', 'technician_id', 'technicianId', 'profile_id'],
      ),
      joinedLabel: _joinedLabel(joinedAt),
      isVerified: status == 'verified',
      firstName: firstName.isEmpty ? 'Técnico' : firstName,
      fullName: fullName.isEmpty ? 'Técnico Toke+' : fullName,
      bio: _firstString(
        [technician, profileData],
        ['bio', 'description', 'presentation', 'about'],
        fallback:
            'Prestador de servicios verificado en Toke+. Listo para atender pedidos de clientes cerca de tu zona.',
      ),
      district: _firstString(
        [technician, profileData],
        ['district', 'district_name', 'districtName', 'zone', 'location'],
        fallback: 'Trujillo',
      ),
      phoneLabel: _formatPhone(
        _firstString([technician, profileData], ['phone', 'phone_number']),
      ),
      avatarUrl: _firstString(
        [profileData, technician],
        ['avatar_url', 'avatarUrl', 'photo_url', 'photo'],
      ),
      services: _readServices(profileData, technician),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _firstString(
    List<Map<String, dynamic>?> sources,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final source in sources) {
      if (source == null) continue;
      for (final key in keys) {
        final value = source[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
    }
    return fallback;
  }

  static Object? _firstValue(
    List<Map<String, dynamic>?> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      if (source == null) continue;
      for (final key in keys) {
        final value = source[key];
        if (value != null) return value;
      }
    }
    return null;
  }

  static List<_ServiceViewData> _readServices(
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? technician,
  ) {
    final raw = _firstValue(
      [technician, profileData],
      ['categories', 'services', 'service_categories', 'specialties'],
    );

    final services = <_ServiceViewData>[];
    if (raw is List) {
      for (final item in raw) {
        final service = _serviceFromDynamic(item);
        if (service != null) services.add(service);
      }
    } else if (raw is String && raw.trim().isNotEmpty) {
      for (final item in raw.split(',')) {
        final service = _serviceFromName(item.trim());
        if (service != null) services.add(service);
      }
    }

    if (services.isNotEmpty) return services.take(4).toList();
    return const [
      _ServiceViewData(
        title: 'Servicios generales',
        emoji: '🔧',
        description: 'Atención profesional para pedidos del hogar.',
      ),
    ];
  }

  static _ServiceViewData? _serviceFromDynamic(Object? item) {
    if (item == null) return null;
    if (item is String) return _serviceFromName(item);
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final name = _firstString(
        [map],
        ['name', 'title', 'category', 'category_name', 'service_name'],
      );
      if (name.isEmpty) return null;
      return _serviceFromName(
        name,
        description: _firstString([map], ['description', 'subtitle']),
      );
    }
    return _serviceFromName(item.toString());
  }

  static _ServiceViewData? _serviceFromName(
    String name, {
    String? description,
  }) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return null;
    final fallbackDescription =
        _serviceDescriptions[cleaned] ??
        'Servicio profesional disponible en tu zona.';
    return _ServiceViewData(
      title: cleaned,
      emoji: _serviceEmojis[cleaned] ?? '🔧',
      description: description?.trim().isNotEmpty == true
          ? description!.trim()
          : fallbackDescription,
    );
  }

  static String _formatPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 9) {
      return '+51 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return '+$digits';
  }

  static const _serviceEmojis = {
    'Albañil': '🧱',
    'Electricista': '⚡',
    'Pintura': '🎨',
    'Plomero': '🔧',
    'Aire Acondicionado': '❄️',
    'Piscinas': '🏊',
    'Jardinería': '🌿',
    'Contratista/Construcción': '🏗️',
    'Flete/Mudanza': '🚚',
    'Seguridad': '🔒',
    'Azulejista': '🧩',
    'Pisos y baldosas': '🪨',
    'Diseño de Interiores': '🛋️',
    'Iluminación': '💡',
    'Herrero': '⚒️',
  };

  static const _serviceDescriptions = {
    'Albañil': 'Construcción, reparaciones y acabados.',
    'Electricista': 'Instalaciones y reparaciones eléctricas.',
    'Pintura': 'Pintura interior, exterior y retoques.',
    'Plomero': 'Plomería en general y emergencias.',
    'Aire Acondicionado': 'Instalación y mantenimiento de equipos.',
    'Piscinas': 'Trabajos, limpieza y mantenimiento de piscinas.',
    'Jardinería': 'Mantenimiento de jardines y áreas verdes.',
    'Contratista/Construcción': 'Obras, remodelaciones y construcción.',
    'Flete/Mudanza': 'Traslados, carga y mudanzas.',
    'Seguridad': 'Instalación y revisión de sistemas de seguridad.',
    'Azulejista': 'Instalación de cerámicos y acabados.',
    'Pisos y baldosas': 'Instalación y reparación de pisos.',
    'Diseño de Interiores': 'Diseño y mejora de espacios interiores.',
    'Iluminación': 'Instalación y diseño de iluminación.',
    'Herrero': 'Trabajos de herrería y estructuras metálicas.',
  };
}

class _ServiceViewData {
  const _ServiceViewData({
    required this.title,
    required this.emoji,
    required this.description,
  });

  final String title;
  final String emoji;
  final String description;
}
