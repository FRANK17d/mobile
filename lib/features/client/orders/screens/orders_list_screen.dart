import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/badges/notification_badge.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';
import '../../../auth/services/auth_store.dart';
import '../../home/widgets/client_menu_sheet.dart';
import '../../notifications/screens/client_notifications_screen.dart';
import '../../request_service/screens/order_review_screen.dart';
import '../../request_service/services/request_service.dart';
import '../../how_it_works/screens/how_it_works_screen.dart';
import 'public_requests_screen.dart';

/// Pantalla de pedidos del cliente.
///
/// Cuando el usuario no esta autenticado muestra un empty state
/// con barra de busqueda y CTA para iniciar sesion / conocer el flujo.
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSnapshot>(
      valueListenable: AuthStore.instance.notifier,
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const _AuthenticatedOrdersView();
        }
        return const _UnauthenticatedOrdersView();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header oscuro reutilizable (con y sin sesión)
// ─────────────────────────────────────────────────────────
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.title, required this.actions, required this.onSearch});

  final String title;
  final List<Widget> actions;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 14, left: 20, right: 20, bottom: 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24344B), Color(0xFF1D2939)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 18),
          _SearchPill(onTap: onSearch),
        ],
      ),
    );
  }
}

/// Barra de búsqueda ("explorar pedidos de otros clientes").
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
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3B4F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Explorar pedidos de otros clientes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.45),
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

/// Contenedor blanco redondeado que "monta" sobre el header.
class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista NO autenticada
// ─────────────────────────────────────────────────────────
class _UnauthenticatedOrdersView extends StatelessWidget {
  const _UnauthenticatedOrdersView();

  @override
  Widget build(BuildContext context) {
    void openPublic() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PublicRequestsScreen()),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _OrdersHeader(
              title: 'Mis Pedidos',
              onSearch: openPublic,
              actions: [
                _EntrarButton(onTap: () => context.push(AppRoutes.login)),
                const SizedBox(width: 10),
                _HeaderCircleButton(
                  icon: Icons.menu_rounded,
                  onTap: () => showAppMenuSheet(context),
                ),
              ],
            ),
            _SheetContainer(
              child: Center(
                child: _NoOrdersContent(
                  onComoFunciona: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HowItWorksScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "Entrar"
// ─────────────────────────────────────────────────────────
class _EntrarButton extends StatelessWidget {
  const _EntrarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Entrar',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "¿Como funciona?"
// ─────────────────────────────────────────────────────────
class _ComoFuncionaButton extends StatelessWidget {
  const _ComoFuncionaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          '¿Cómo funciona?',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista autenticada
// ─────────────────────────────────────────────────────────
enum _OrdersFilter { all, active, done }

class _AuthenticatedOrdersView extends StatefulWidget {
  const _AuthenticatedOrdersView();

  @override
  State<_AuthenticatedOrdersView> createState() =>
      _AuthenticatedOrdersViewState();
}

class _AuthenticatedOrdersViewState extends State<_AuthenticatedOrdersView> {
  final RequestService _service = RequestService();

  List<MyRequest> _requests = const [];
  bool _loading = true;
  _OrdersFilter _filter = _OrdersFilter.all;

  final List<VoidCallback> _rtUnsub = [];
  String? _clientChannel;

  static const _activeStatuses = {
    'pending_review',
    'open',
    'assigned',
    'in_progress',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  Future<void> _setupRealtime() async {
    final rt = RealtimeService.instance;
    await rt.connect();
    final uid = await InsForgeClient().getCurrentUserId();
    if (uid == null) return;
    _clientChannel = 'client:$uid';
    rt.subscribe(_clientChannel!);
    // Refresco silencioso (sin loader) ante cualquier evento de mis pedidos:
    // nueva postulación, cambio de estado o edición del pedido.
    void refresh(Map<String, dynamic> _) {
      if (mounted) _load(silent: true);
    }

    _rtUnsub.add(rt.on('new_application', refresh));
    _rtUnsub.add(rt.on('status_changed', refresh));
    _rtUnsub.add(rt.on('request_updated', refresh));
  }

  @override
  void dispose() {
    for (final off in _rtUnsub) {
      off();
    }
    if (_clientChannel != null) {
      RealtimeService.instance.unsubscribe(_clientChannel!);
    }
    super.dispose();
  }

  /// [silent] = true no muestra el loader (refrescos por realtime / pull).
  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final list = await _service.getMyRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  List<MyRequest> get _filtered {
    switch (_filter) {
      case _OrdersFilter.all:
        return _requests;
      case _OrdersFilter.active:
        return _requests
            .where((r) => _activeStatuses.contains(r.status))
            .toList();
      case _OrdersFilter.done:
        return _requests
            .where((r) => !_activeStatuses.contains(r.status))
            .toList();
    }
  }

  void _openPublic() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PublicRequestsScreen()),
    );
  }

  void _openHowItWorks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowItWorksScreen()),
    );
  }

  void _openNotifications() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const ClientNotificationsScreen()),
    );
  }

  void _openMenu() {
    showClientMenuSheet(context, profileData: AuthStore.instance.value.profile);
  }

  Future<void> _openDetail(MyRequest r) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderReviewScreen(requestId: r.id, initial: r),
      ),
    );
    if (changed == true) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final hasRequests = _requests.isNotEmpty;
    final filtered = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _OrdersHeader(
              title: 'Mis Pedidos',
              onSearch: _openPublic,
              actions: [
                NotificationBadge(
                  child: _HeaderCircleButton(
                    icon: Icons.notifications_outlined,
                    onTap: _openNotifications,
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderCircleButton(icon: Icons.menu_rounded, onTap: _openMenu),
              ],
            ),
            _SheetContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera + filtros: SOLO cuando ya cargó y hay pedidos
                  // (así no aparece sobre el loader ni sobre el empty state).
                  if (!_loading && hasRequests) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Historial de mis pedidos',
                              style: AppTypography.headingLarge.copyWith(
                                color: const Color(0xFF162033),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _CountPill(count: _requests.length),
                        ],
                      ),
                    ),
                    _FilterChips(
                      selected: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Expanded(
                    child: _loading
                        ? const _OrdersLoader()
                        : !hasRequests
                        ? _NoOrdersContent(onComoFunciona: _openHowItWorks)
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => _load(silent: true),
                            child: filtered.isEmpty
                                ? _EmptyForFilter(filter: _filter)
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final r = filtered[i];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: _FadeSlideIn(
                                          key: ValueKey('order-${r.id}'),
                                          delay: Duration(
                                            milliseconds: (i * 55).clamp(0, 330),
                                          ),
                                          child: _HistoryCard(
                                            request: r,
                                            onTap: () => _openDetail(r),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loader circular de marca, centrado, con texto.
class _OrdersLoader extends StatelessWidget {
  const _OrdersLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando tus pedidos...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla con el conteo total de pedidos.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Chips de filtro (Todos / Activos / Finalizados), scrolleables.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _OrdersFilter selected;
  final ValueChanged<_OrdersFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_OrdersFilter.all, 'Todos'),
      (_OrdersFilter.active, 'Activos'),
      (_OrdersFilter.done, 'Finalizados'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = items[i];
          final isSel = value == selected;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.neutral100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.neutral200,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSel ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Mensaje cuando el filtro activo no tiene resultados (pero sí hay pedidos).
class _EmptyForFilter extends StatelessWidget {
  const _EmptyForFilter({required this.filter});

  final _OrdersFilter filter;

  @override
  Widget build(BuildContext context) {
    final text = filter == _OrdersFilter.active
        ? 'No tienes pedidos activos por ahora.'
        : 'No tienes pedidos finalizados todavía.';
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 60, 36, 36),
      children: [
        Icon(
          Icons.filter_list_off_rounded,
          size: 44,
          color: AppColors.neutral300,
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

/// Etiqueta + color legibles para cada estado de pedido.
({String label, Color color, Color bg}) _statusBadge(String status) {
  switch (status) {
    case 'pending_review':
      return (label: 'En revisión', color: AppColors.primary, bg: const Color(0xFFFFF0ED));
    case 'open':
      return (label: 'Publicado', color: const Color(0xFF2563EB), bg: const Color(0xFFE7EEFD));
    case 'assigned':
      return (label: 'Asignado', color: const Color(0xFF1FA855), bg: const Color(0xFFE8F8EF));
    case 'in_progress':
      return (label: 'En curso', color: const Color(0xFF1FA855), bg: const Color(0xFFE8F8EF));
    case 'completed':
      return (label: 'Completado', color: const Color(0xFF1FA855), bg: const Color(0xFFE8F8EF));
    case 'cancelled':
      return (label: 'Cancelado', color: AppColors.neutral600, bg: AppColors.neutral200);
    case 'rejected':
      return (label: 'Rechazado', color: AppColors.neutral600, bg: AppColors.neutral200);
    default:
      return (label: status, color: AppColors.neutral600, bg: AppColors.neutral200);
  }
}

/// Botón circular del header oscuro (campana / menú).
class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

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
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(child: Icon(icon, size: 22, color: Colors.white)),
      ),
    );
  }
}

/// Estado vacío de pedidos (sin pedidos del todo).
class _NoOrdersContent extends StatelessWidget {
  const _NoOrdersContent({required this.onComoFunciona});

  final VoidCallback onComoFunciona;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin pedidos por ahora',
              textAlign: TextAlign.center,
              style: AppTypography.headingLarge.copyWith(
                color: const Color(0xFF162033),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Una vez que solicites un servicio, vas a poder seguir todo el '
              'proceso desde esta pantalla. Simple, rápido y transparente.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _ComoFuncionaButton(onTap: onComoFunciona),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta del historial de "mis pedidos" (con miniatura o emoji de categoría).
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.request, required this.onTap});

  final MyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(request.status);
    final title = request.title.isEmpty ? request.categoryName : request.title;
    final thumb = request.thumbnailUrl;
    final showApplicants = request.applicationsCount > 0 &&
        (request.status == 'open' ||
            request.status == 'assigned' ||
            request.status == 'in_progress');

    return Material(
      color: AppColors.neutral50,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Leading(thumb: thumb, emoji: request.categoryEmoji),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (request.orderNumber != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Nº ${formatOrderNumber(request.orderNumber)}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.neutral500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                request.districtName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ),
                            if (request.createdAt != null) ...[
                              _Dot(),
                              Text(
                                _relativeTime(request.createdAt!),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.neutral200),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatusBadgeView(badge: badge),
                  if (showApplicants) ...[
                    const SizedBox(width: 8),
                    _ApplicantsChip(count: request.applicationsCount),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura (foto) o círculo con el emoji de la categoría.
class _Leading extends StatelessWidget {
  const _Leading({required this.thumb, required this.emoji});

  final String? thumb;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    if (thumb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52,
          height: 52,
          child: CachedNetworkImage(
            imageUrl: thumb!,
            memCacheWidth: 140,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(
              color: AppColors.neutral200,
              child: Icon(Icons.image_outlined, color: AppColors.neutral400, size: 20),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emoji.isEmpty ? '🧰' : emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _StatusBadgeView extends StatelessWidget {
  const _StatusBadgeView({required this.badge});

  final ({String label, Color color, Color bg}) badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: badge.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: AppTypography.labelMedium.copyWith(
              color: badge.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantsChip extends StatelessWidget {
  const _ApplicantsChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.neutral400,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Tiempo relativo corto: "ahora", "hace 5m", "hace 2h", "ayer", "hace 3d", o fecha.
String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'hace ${diff.inHours}h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays}d';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Entrada animada (fade + leve slide) con retardo escalonado por índice.
/// Anima una sola vez gracias a la key estable de cada tarjeta.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.07),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
