import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/account_prompt_screen.dart';
import '../../../auth/services/auth_store.dart';
import '../../home/services/category_service.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';
import '../services/explore_service.dart';

/// Detalle de una categoría de servicio: hero con CTA, prestadores que la
/// ofrecen, pedidos recientes de clientes y categorías relacionadas.
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final ServiceCategory category;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ExploreService _service = ExploreService();
  final CategoryService _categoryService = CategoryService();

  List<CategoryProvider> _providers = const [];
  List<CategoryRequest> _requests = const [];
  List<ServiceCategory> _related = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.category.id;
    final results = await Future.wait([
      _service.getCategoryProviders(id),
      _service.getCategoryRecentRequests(id),
      _categoryService.getActiveCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _providers = results[0] as List<CategoryProvider>;
      _requests = results[1] as List<CategoryRequest>;
      _related = (results[2] as List<ServiceCategory>)
          .where((c) => c.id != id)
          .take(8)
          .toList();
      _loading = false;
    });
  }

  // ── Acciones ──
  void _pedirServicio() {
    if (!AuthStore.instance.value.isAuthenticated) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const AccountPromptScreen()),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestServiceWizardScreen(
          initialCategoryName: widget.category.name,
        ),
      ),
    );
  }

  void _ofrecerServicio() {
    // Cierra las rutas crudas hasta el shell y abre el registro de prestador.
    final nav = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    nav.popUntil((r) => r.isFirst);
    router.push('/register/provider');
  }

  void _openCategory(ServiceCategory c) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(category: c),
      ),
    );
  }

  void _soon() =>
      showAppToast(context, message: 'Próximamente', type: ToastType.info);

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
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
          titleSpacing: 0,
          title: Text(
            cat.name,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.neutral500,
              ),
              onPressed: _soon,
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          children: [
            _Hero(
              category: cat,
              onPedir: _pedirServicio,
              onOfrecer: _ofrecerServicio,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Prestadores ──
            _SectionHeader(
              emoji: '🧰',
              title: 'Algunos que brindan este servicio',
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const _SectionLoader()
            else if (_providers.isEmpty)
              const _EmptyHint(
                text: 'Todavía no hay prestadores en esta categoría.',
              )
            else
              SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  itemCount: _providers.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, i) =>
                      _ProviderCard(provider: _providers[i], onProfile: _soon),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── Pedidos recientes ──
            _SectionHeader(emoji: '📢', title: 'Últimos pedidos de clientes'),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const _SectionLoader()
            else if (_requests.isEmpty)
              const _EmptyHint(text: 'Aún no hay pedidos en esta categoría.')
            else
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  itemCount: _requests.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, i) => _RequestCard(request: _requests[i]),
                ),
              ),

            // ── Relacionadas ──
            if (_related.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(
                emoji: '🧰',
                title: 'Servicios que podrían interesarte',
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in _related)
                      _RelatedChip(category: c, onTap: () => _openCategory(c)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({
    required this.category,
    required this.onPedir,
    required this.onOfrecer,
  });

  final ServiceCategory category;
  final VoidCallback onPedir;
  final VoidCallback onOfrecer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Buscás un servicio de ${category.name}?',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        category.description,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(category.emoji, style: const TextStyle(fontSize: 52)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              GestureDetector(
                onTap: onPedir,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'Pedir servicio',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: onOfrecer,
                  child: Text(
                    'Ofrecer este servicio',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Encabezado de sección
// ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de prestador
// ─────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onProfile});

  final CategoryProvider provider;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final name = provider.fullName.isEmpty ? 'Técnico' : provider.fullName;
    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.neutral200,
                backgroundImage: provider.avatarUrl != null
                    ? CachedNetworkImageProvider(provider.avatarUrl!)
                    : null,
                child: provider.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 34,
                        color: AppColors.neutral500,
                      )
                    : null,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.verified,
                  size: 18,
                  color: Color(0xFF2D9CDB),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (provider.districtName != null &&
              provider.districtName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              provider.districtName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 2),
              Text(
                (provider.avgRating ?? 0).toStringAsFixed(1),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${provider.totalJobs ?? 0})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundTertiary,
                foregroundColor: AppColors.secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              child: Text(
                'Ver perfil',
                style: AppTypography.buttonSmall.copyWith(
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

// ─────────────────────────────────────────────────────────
// Tarjeta de pedido reciente
// ─────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final CategoryRequest request;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(request.status);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (request.districtName != null && request.districtName!.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.districtName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.clientFirstName ?? 'Cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  badge.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: badge.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

({String label, Color color, Color bg}) _statusBadge(String status) {
  switch (status) {
    case 'open':
      return (
        label: 'Publicado',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFE7EEFD),
      );
    case 'assigned':
      return (
        label: 'Asignado',
        color: const Color(0xFF2E9E6B),
        bg: const Color(0xFFE8F8EF),
      );
    case 'in_progress':
      return (
        label: 'En progreso',
        color: const Color(0xFF2E9E6B),
        bg: const Color(0xFFE8F8EF),
      );
    case 'completed':
      return (
        label: 'Completado',
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

// ─────────────────────────────────────────────────────────
// Chip de categoría relacionada
// ─────────────────────────────────────────────────────────
class _RelatedChip extends StatelessWidget {
  const _RelatedChip({required this.category, required this.onTap});

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Loader / vacío de sección
// ─────────────────────────────────────────────────────────
class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}
