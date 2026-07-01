import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../explore/services/explore_service.dart';

/// Detalle público de un pedido mostrado desde Descubrir > Pedidos.
///
/// No expone dirección exacta: solo categoría, descripción, distrito,
/// presupuesto, fechas, imágenes y estado general.
class PublicRequestDetailScreen extends StatelessWidget {
  const PublicRequestDetailScreen({super.key, required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasImages = request.imageUrls.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasImages ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _RequestHero(request: request),
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
                    _Header(request: request),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoGrid(request: request),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('Descripción del servicio'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.description.trim().isEmpty
                          ? 'El cliente no agregó una descripción adicional.'
                          : request.description.trim(),
                      style: AppTypography.bodyLarge.copyWith(
                        color: const Color(0xFF5F6678),
                        height: 1.5,
                      ),
                    ),
                    if (request.imageUrls.length > 1) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Fotos del pedido'),
                      const SizedBox(height: AppSpacing.sm),
                      _ImageGallery(images: request.imageUrls),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _StatusCard(request: request),
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

class _RequestHero extends StatelessWidget {
  const _RequestHero({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final hasImage = request.imageUrls.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasImage ? 280 : 180,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.backgroundPrimary,
      surfaceTintColor: AppColors.backgroundPrimary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.black.withValues(alpha: 0.35)
                  : AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_rounded,
              color: hasImage ? Colors.white : AppColors.neutral800,
              size: 22,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: request.imageUrls.first,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    errorWidget: (_, _, _) => _FallbackHero(request: request),
                  ),
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
            : _FallbackHero(request: request),
      ),
    );
  }
}

class _FallbackHero extends StatelessWidget {
  const _FallbackHero({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForCategory(request.categoryName);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          request.categoryEmoji.isEmpty ? '🧰' : request.categoryEmoji,
          style: const TextStyle(fontSize: 76),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(request.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${request.categoryEmoji}  ${request.categoryName}'.trim(),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badge.bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                badge.label,
                style: AppTypography.labelLarge.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          request.title.trim().isEmpty ? request.categoryName : request.title,
          style: AppTypography.headingLarge.copyWith(
            color: const Color(0xFF162033),
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pedido #${request.orderNumber ?? request.shortCode}',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final preferred = request.preferredDate;
    final completed = request.completedAt;
    final created = request.createdAt;
    final date = switch (request.status) {
      'completed' when completed != null => _formatDate(completed),
      _ when preferred != null => _formatDate(preferred),
      _ when created != null => _formatDate(created),
      _ => 'Sin fecha indicada',
    };
    final dateLabel = request.status == 'completed'
        ? 'Finalizado'
        : preferred != null
        ? 'Fecha preferida'
        : 'Publicado';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.35,
      children: [
        _InfoTile(
          icon: Icons.location_on_outlined,
          label: 'Zona',
          value: request.districtName ?? 'Sin distrito',
        ),
        _InfoTile(
          icon: Icons.payments_outlined,
          label: 'Presupuesto',
          value: _formatBudget(request),
        ),
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          label: dateLabel,
          value: date,
        ),
        _InfoTile(
          icon: Icons.groups_outlined,
          label: 'Interesados',
          value: request.applicationsCount == 0
              ? 'Ninguno aún'
              : '${request.applicationsCount}',
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const Spacer(),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: const Color(0xFF162033),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
      style: AppTypography.titleLarge.copyWith(
        color: const Color(0xFF162033),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _FullImageViewer(url: images[index]),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: CachedNetworkImage(
                imageUrl: images[index],
                width: 190,
                height: 150,
                fit: BoxFit.cover,
                memCacheWidth: 500,
                errorWidget: (_, _, _) => Container(
                  width: 190,
                  height: 150,
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
}

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
          maxScale: 4,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    final text = switch (request.status) {
      'open' =>
        'Este pedido está disponible y puede recibir postulantes verificados.',
      'assigned' ||
      'in_progress' => 'Este pedido ya está siendo atendido por un prestador.',
      'completed' =>
        'Este pedido fue completado. Si el cliente dejó reseña, aparecerá en los casos de éxito.',
      _ => 'Estado actual del pedido: ${request.status}.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF7A3D3D),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat("d 'de' MMM", 'es').format(date);
}

String _formatBudget(PublicRequest request) {
  final min = request.budgetMin;
  final max = request.budgetMax;
  if (min == null && max == null) return 'A convenir';
  final formatter = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 0,
  );
  if (min != null && max != null && min != max) {
    return '${formatter.format(min)} - ${formatter.format(max)}';
  }
  return formatter.format(max ?? min);
}

({String label, Color color, Color bg}) _statusBadge(String status) {
  switch (status) {
    case 'open':
      return (
        label: 'Disponible',
        color: const Color(0xFF2E9E6B),
        bg: const Color(0xFFE3F4EC),
      );
    case 'assigned':
    case 'in_progress':
      return (
        label: 'Progreso',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFE7EEFD),
      );
    case 'completed':
      return (
        label: 'Finalizado',
        color: AppColors.neutral600,
        bg: AppColors.neutral200,
      );
    default:
      return (
        label: status,
        color: AppColors.neutral600,
        bg: AppColors.neutral200,
      );
  }
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
