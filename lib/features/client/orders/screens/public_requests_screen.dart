import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/account_prompt_screen.dart';
import '../../../auth/services/auth_store.dart';
import '../../explore/services/explore_service.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';

/// Vista pública "Pedidos": explora los pedidos de otros clientes (sin sesión).
/// Buscador + filtros por estado; el botón flotante (megáfono) y tocar un
/// pedido abren el prompt "¿Tenés una cuenta?".
class PublicRequestsScreen extends StatefulWidget {
  const PublicRequestsScreen({super.key});

  @override
  State<PublicRequestsScreen> createState() => _PublicRequestsScreenState();
}

enum _StatusFilter { todos, disponible, finalizado, progreso }

class _PublicRequestsScreenState extends State<PublicRequestsScreen> {
  final ExploreService _service = ExploreService();
  final TextEditingController _searchController = TextEditingController();

  List<PublicRequest> _all = const [];
  bool _loading = true;
  bool _showFilters = false;
  String _query = '';
  _StatusFilter _filter = _StatusFilter.todos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _service.getPublicRequests();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  void _promptAccount() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const AccountPromptScreen()),
    );
  }

  bool get _isAuthed => AuthStore.instance.value.isAuthenticated;

  /// Botón flotante: con sesión abre el wizard "Pedir servicio"; sin sesión,
  /// el prompt de cuenta.
  void _onFab() {
    if (_isAuthed) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const RequestServiceWizardScreen(),
        ),
      );
    } else {
      _promptAccount();
    }
  }

  void _onCardTap() {
    if (_isAuthed) {
      showAppToast(
        context,
        message: 'Pronto vas a poder ver más de este pedido.',
        type: ToastType.info,
      );
    } else {
      _promptAccount();
    }
  }

  bool _matchesStatus(PublicRequest r) {
    switch (_filter) {
      case _StatusFilter.todos:
        return true;
      case _StatusFilter.disponible:
        return r.status == 'open';
      case _StatusFilter.finalizado:
        return r.status == 'completed';
      case _StatusFilter.progreso:
        return r.status == 'assigned' || r.status == 'in_progress';
    }
  }

  List<PublicRequest> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((r) {
      if (!_matchesStatus(r)) return false;
      if (q.isEmpty) return true;
      return r.categoryName.toLowerCase().contains(q) ||
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
          shadowColor: AppColors.neutral200,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Text(
            'Pedidos',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onFab,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.campaign_rounded),
        ),
        body: Column(
          children: [
            // ── Buscador + filtros ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.md,
                AppSpacing.screenPaddingH,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.only(left: 16, right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              cursorColor: AppColors.primary,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Escribir para buscar...',
                                hintStyle: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Icon(
                        _showFilters ? Icons.close_rounded : Icons.tune_rounded,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Chips de filtro ──
            if (_showFilters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  0,
                  AppSpacing.screenPaddingH,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    for (final f in _StatusFilter.values) ...[
                      _FilterChip(
                        label: _filterLabel(f),
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),

            // ── Lista ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPaddingH,
                          AppSpacing.md,
                          AppSpacing.screenPaddingH,
                          100,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) => _PublicRequestCard(
                          request: items[i],
                          onTap: _onCardTap,
                        ),
                      ),
                    ),
            ),
          ],
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
            Icon(Icons.search_off_rounded, size: 56, color: AppColors.neutral300),
            const SizedBox(height: 12),
            Text(
              'No hay pedidos para mostrar',
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

String _filterLabel(_StatusFilter f) => switch (f) {
  _StatusFilter.todos => 'Todos',
  _StatusFilter.disponible => 'Disponible',
  _StatusFilter.finalizado => 'Finalizado',
  _StatusFilter.progreso => 'Progreso',
};

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PublicRequestCard extends StatelessWidget {
  const _PublicRequestCard({required this.request, required this.onTap});

  final PublicRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(request.status);
    final interested = request.applicationsCount == 0
        ? 'Todavía ningún interesado'
        : '${request.applicationsCount} interesado${request.applicationsCount == 1 ? '' : 's'}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.neutral200),
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
                        request.categoryName.isEmpty
                            ? request.title
                            : request.categoryName,
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        request.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${request.shortCode}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.categoryEmoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (request.districtName != null &&
                request.districtName!.isNotEmpty)
              _IconLine(
                icon: Icons.location_on_outlined,
                text: request.districtName!,
              ),
            const SizedBox(height: AppSpacing.xs),
            _IconLine(icon: Icons.groups_outlined, text: interested),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18,
                    color: AppColors.neutral500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.clientFirstName ?? 'Cliente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    badge.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: badge.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.neutral400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.neutral500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ),
      ],
    );
  }
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
      return (label: status, color: AppColors.neutral600, bg: AppColors.neutral200);
  }
}
