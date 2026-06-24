import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../explore/services/explore_service.dart';
import '../../../technician/account/screens/technician_profile_preview_screen.dart';

/// Pantalla de búsqueda global para clientes.
///
/// Carga técnicos y pedidos públicos, y filtra localmente por texto.
/// Dos tabs: "Técnicos" y "Pedidos".
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final TabController _tabController;

  final ExploreService _exploreService = ExploreService();

  List<CategoryProvider> _allProviders = const [];
  List<PublicRequest> _allRequests = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    // Auto-focus el campo de búsqueda.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _exploreService.getAllProviders(),
      _exploreService.getPublicRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _allProviders = results[0] as List<CategoryProvider>;
      _allRequests = results[1] as List<PublicRequest>;
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
    });
  }

  /// Filtra técnicos por nombre, distrito.
  List<CategoryProvider> get _filteredProviders {
    if (_query.isEmpty) return _allProviders;
    return _allProviders.where((p) {
      final name = p.fullName.toLowerCase();
      final district = (p.districtName ?? '').toLowerCase();
      return name.contains(_query) || district.contains(_query);
    }).toList();
  }

  /// Filtra pedidos por título, categoría, distrito.
  List<PublicRequest> get _filteredRequests {
    if (_query.isEmpty) return _allRequests;
    return _allRequests.where((r) {
      final title = r.title.toLowerCase();
      final category = r.categoryName.toLowerCase();
      final district = (r.districtName ?? '').toLowerCase();
      return title.contains(_query) ||
          category.contains(_query) ||
          district.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header con barra de búsqueda ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.md,
                  AppSpacing.screenPaddingH,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: AppSpacing.inputHeight,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: AppSpacing.iconSize,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                onChanged: _onSearchChanged,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar técnicos o pedidos...',
                                  hintStyle: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    right: AppSpacing.sm,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textTertiary,
                                    size: AppSpacing.iconSizeSmall,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Cancelar',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tabs ──
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTypography.titleMedium,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Técnicos'),
                  Tab(text: 'Pedidos'),
                ],
              ),

              // ── Contenido ──
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _ProvidersTab(
                            providers: _filteredProviders,
                            query: _query,
                          ),
                          _RequestsTab(
                            requests: _filteredRequests,
                            query: _query,
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
// Tab de técnicos
// ─────────────────────────────────────────────────────────
class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab({required this.providers, required this.query});

  final List<CategoryProvider> providers;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return _EmptyState(
        icon: Icons.person_search_rounded,
        message: query.isEmpty
            ? 'No hay técnicos disponibles'
            : 'Sin resultados para "$query"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.md,
      ),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _ProviderCard(provider: provider);
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});

  final CategoryProvider provider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TechnicianPublicPreviewScreen(
                profileData: provider.toPublicProfileData(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: AppSpacing.avatarSmall / 2,
                backgroundColor: AppColors.backgroundTertiary,
                backgroundImage: provider.avatarUrl != null
                    ? NetworkImage(provider.avatarUrl!)
                    : null,
                child: provider.avatarUrl == null
                    ? Text(
                        provider.firstName.isNotEmpty
                            ? provider.firstName[0].toUpperCase()
                            : '?',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.fullName,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                    if (provider.districtName != null) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        provider.districtName!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Rating
              if (provider.avgRating != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.starFilled,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      provider.avgRating!.toStringAsFixed(1),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: AppSpacing.iconSizeSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tab de pedidos
// ─────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.requests, required this.query});

  final List<PublicRequest> requests;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_rounded,
        message: query.isEmpty
            ? 'No hay pedidos públicos'
            : 'Sin resultados para "$query"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.md,
      ),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(request: request);
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final PublicRequest request;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () {
          showAppToast(
            context,
            message: 'Próximamente: detalle del pedido',
            type: ToastType.info,
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Emoji categoria
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  request.categoryEmoji.isNotEmpty
                      ? request.categoryEmoji
                      : '📋',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    Row(
                      children: [
                        Text(
                          request.categoryName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (request.districtName != null) ...[
                          Text(
                            ' · ',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              request.districtName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Postulaciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${request.shortCode}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (request.applicationsCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${request.applicationsCount} postulaciones',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.neutral300),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
