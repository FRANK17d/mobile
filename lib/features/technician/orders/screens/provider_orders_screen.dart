import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/badges/notification_badge.dart';
import '../../../auth/services/auth_store.dart';
import '../../home/widgets/technician_menu_sheet.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../services/technician_feed_service.dart';
import 'technician_requests_list_screen.dart';

/// Tab "Pedidos" del técnico autenticado.
///
/// Muestra: hero oscuro con saludo + pedidos disponibles + CTAs,
/// barra de búsqueda que abre el listado completo, e historial de
/// pedidos propios (asignados/postulados).
class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({super.key});

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen> {
  final TechnicianFeedService _feedService = TechnicianFeedService();

  List<AvailableRequest> _available = const [];
  List<TechnicianOrder> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _feedService.getAvailableRequests(allCategories: true, allZones: true),
      _feedService.getMyOrders(),
    ]);
    if (!mounted) return;
    setState(() {
      _available = results[0] as List<AvailableRequest>;
      _history = results[1] as List<TechnicianOrder>;
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
    final profile = AuthStore.instance.value.profile;

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
              // ── Hero oscuro ──
              SliverToBoxAdapter(
                child: _HeroSection(
                  firstName: _firstName,
                  availableCount: _available.length,
                  loading: _loading,
                  onNotifications: () =>
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              NotificationsScreen(profileData: profile),
                        ),
                      ),
                  onMenu: () =>
                      showTechnicianMenuSheet(context, profileData: profile),
                  onViewAll: () => _openRequests(),
                  onRecommended: () =>
                      _openRequests(scope: TechnicianRequestsScope.recommended),
                ),
              ),

              // ── Búsqueda ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SearchBar(
                    onTap: () => _openRequests(focusSearch: true),
                  ),
                ),
              ),

              // ── Historial ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Text(
                    'Historial de mis pedidos',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_history.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyHistory(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(order: _history[i]),
                      ),
                      childCount: _history.length,
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

// ─────────────────────────────────────────────────────────
// Hero oscuro con saludo + conteo + CTAs
// ─────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.firstName,
    required this.availableCount,
    required this.loading,
    required this.onNotifications,
    required this.onMenu,
    required this.onViewAll,
    required this.onRecommended,
  });

  final String firstName;
  final int availableCount;
  final bool loading;
  final VoidCallback onNotifications;
  final VoidCallback onMenu;
  final VoidCallback onViewAll;
  final VoidCallback onRecommended;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24344B), Color(0xFF1D2939)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header icons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NotificationBadge(
                child: _HeaderIcon(
                  icon: Icons.notifications_outlined,
                  onTap: onNotifications,
                ),
              ),
              const SizedBox(width: 10),
              _HeaderIcon(icon: Icons.menu_rounded, onTap: onMenu),
            ],
          ),
          const SizedBox(height: 20),

          // ── Saludo ──
          Text(
            '¡Hola, $firstName!',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // ── Conteo ──
          Row(
            children: [
              Text(
                loading ? '—' : '$availableCount Pedidos disponibles',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '¿Listo para conectar? 📣',
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          // ── CTA: Ver todos ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onViewAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Ver todos y postularme',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── CTA: Recomendados ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onRecommended,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Recomendados para vos',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Barra de búsqueda
// ─────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Buscar por oficio, zona, y más...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.neutral500,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de pedido del historial
// ─────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final TechnicianOrder order;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(order.status);
    final number = order.orderNumber != null
        ? 'N° ${order.orderNumber.toString().padLeft(4, '0')}'
        : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                child: Text(
                  order.title.isNotEmpty ? order.title : order.categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (number.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  number,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
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
                  order.districtName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.clientShortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
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
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral400,
                size: 20,
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
        label: 'Disponible',
        color: const Color(0xFF2E9E6B),
        bg: const Color(0xFFE8F8EF),
      );
    case 'assigned':
      return (
        label: 'Asignado',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFE7EEFD),
      );
    case 'in_progress':
      return (
        label: 'En progreso',
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFE7EEFD),
      );
    case 'completed':
      return (
        label: 'Completado',
        color: const Color(0xFF2E9E6B),
        bg: const Color(0xFFE8F8EF),
      );
    case 'cancelled':
      return (
        label: 'Cancelado',
        color: const Color(0xFFDC3545),
        bg: const Color(0xFFFEECEE),
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
// Empty state
// ─────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: AppColors.neutral300),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes pedidos en tu historial',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Postúlate a pedidos disponibles para empezar.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header icon
// ─────────────────────────────────────────────────────────
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
