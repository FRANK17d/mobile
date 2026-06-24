import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/badges/notification_badge.dart';
import '../../../auth/services/auth_store.dart';
import '../../account/services/credit_service.dart';
import '../../home/widgets/technician_menu_sheet.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../services/technician_feed_service.dart';
import 'technician_requests_list_screen.dart';

/// Entrada de pedidos del técnico autenticado.
///
/// Muestra el resumen tipo historial y deriva al listado reutilizable para
/// buscar, ver recomendados o postularse a cualquier pedido disponible.
class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({super.key});

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen> {
  final TechnicianFeedService _feedService = TechnicianFeedService();
  final CreditService _creditService = CreditService();

  List<AvailableRequest> _recommended = const [];
  int _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _feedService.getAvailableRequests(),
      _creditService.getBalance(),
    ]);
    if (!mounted) return;
    setState(() {
      _recommended = results[0] as List<AvailableRequest>;
      _balance = results[1] as int;
      _loading = false;
    });
  }

  void _openRequests({
    TechnicianRequestsScope scope = TechnicianRequestsScope.all,
    bool focusSearch = false,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => TechnicianRequestsListScreen(
          initialScope: scope,
          focusSearch: focusSearch,
        ),
      ),
    );
  }

  String get _firstName {
    final profile = AuthStore.instance.value.profile;
    final first = profile?['first_name'] as String?;
    if (first != null && first.trim().isNotEmpty) return first.trim();
    final fullName = profile?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(RegExp(r'\s+')).first;
    }
    return 'Técnico';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HistoryHeader(
                  firstName: _firstName,
                  balance: _balance,
                  onSearch: () => _openRequests(focusSearch: true),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _RecommendedCard(
                      loading: _loading,
                      requests: _recommended,
                      onOpenRecommended: () => _openRequests(
                        scope: TechnicianRequestsScope.recommended,
                      ),
                      onOpenAll: () => _openRequests(),
                    ),
                    const SizedBox(height: 14),
                    _ApplyAllCard(onTap: () => _openRequests()),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.firstName,
    required this.balance,
    required this.onSearch,
  });

  final String firstName;
  final int balance;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final profile = AuthStore.instance.value.profile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24344B), Color(0xFF1D2939)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Historial de pedidos',
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              NotificationBadge(
                child: _HeaderIcon(
                  icon: Icons.notifications_outlined,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationsScreen(profileData: profile),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _HeaderIcon(
                icon: Icons.menu_rounded,
                onTap: () =>
                    showTechnicianMenuSheet(context, profileData: profile),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Hola, $firstName',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$balance créditos disponibles para postularte',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _SearchPill(onTap: onSearch),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3B4F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.52),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Escribir para buscar pedidos...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.loading,
    required this.requests,
    required this.onOpenRecommended,
    required this.onOpenAll,
  });

  final bool loading;
  final List<AvailableRequest> requests;
  final VoidCallback onOpenRecommended;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final preview = requests.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recomendado para vos',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onOpenAll, child: const Text('Ver todos')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Según tus categorías, servicios y zona configurada.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (preview.isEmpty)
            _NoRecommended(onTap: onOpenAll)
          else ...[
            for (final request in preview) ...[
              _MiniRequestTile(request: request),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onOpenRecommended,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
                child: Text(
                  'Ver recomendados',
                  style: AppTypography.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRequestTile extends StatelessWidget {
  const _MiniRequestTile({required this.request});

  final AvailableRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Text(request.categoryEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title.isEmpty ? request.categoryName : request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.districtName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRecommended extends StatelessWidget {
  const _NoRecommended({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No hay recomendados por ahora.',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Puedes revisar todos los pedidos disponibles sin filtro.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onTap, child: const Text('Ver todos')),
        ],
      ),
    );
  }
}

class _ApplyAllCard extends StatelessWidget {
  const _ApplyAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Busca nuevos pedidos',
            style: AppTypography.headingSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explora todos los pedidos publicados y postulate al que quieras.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D2939),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Postularme',
                style: AppTypography.buttonMedium.copyWith(
                  color: const Color(0xFF1D2939),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
