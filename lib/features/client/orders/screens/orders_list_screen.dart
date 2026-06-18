import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';
import '../../../auth/services/auth_store.dart';
import '../../request_service/screens/request_applicants_screen.dart';
import '../../request_service/services/request_service.dart';

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
// Vista NO autenticada (empty state estilo referencia)
// ─────────────────────────────────────────────────────────
class _UnauthenticatedOrdersView extends StatelessWidget {
  const _UnauthenticatedOrdersView();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // ── Header oscuro ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: 20,
                right: 20,
                bottom: 28,
              ),
              decoration: const BoxDecoration(color: Color(0xFF1D2939)),
              child: Column(
                children: [
                  // ── Top bar: titulo + boton Entrar + menu ──
                  Row(
                    children: [
                      Text(
                        'Mis Pedidos',
                        style: AppTypography.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _EntrarButton(
                        onTap: () {
                          context.push(AppRoutes.login);
                        },
                      ),
                      const SizedBox(width: 10),
                      _HeaderMenuButton(
                        onTap: () {
                          showAppMenuSheet(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Barra de busqueda ──
                  Container(
                    width: double.infinity,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3B4F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Explorar pedidos de otros clientes',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido blanco con bordes redondeados arriba ──
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                            'Una vez que solicites un servicio, vas a poder '
                            'seguir todo el proceso desde esta pantalla. '
                            'Simple, rápido y transparente.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ComoFuncionaButton(
                            onTap: () {
                              // TODO: navegar a pantalla como funciona
                            },
                          ),
                        ],
                      ),
                    ),
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
// Boton menu hamburguesa (mismo estilo que home)
// ─────────────────────────────────────────────────────────
class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({required this.onTap});

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
        child: const Center(
          child: Icon(Icons.menu_rounded, size: 22, color: Colors.white),
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
// Vista autenticada (con tabs de pedidos)
// ─────────────────────────────────────────────────────────
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

  final List<VoidCallback> _rtUnsub = [];
  String? _clientChannel;

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
    void refresh(Map<String, dynamic> _) {
      if (mounted) _load();
    }

    _rtUnsub.add(rt.on('new_application', refresh));
    _rtUnsub.add(rt.on('status_changed', refresh));
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

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getMyRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  List<MyRequest> _filter(Set<String> statuses) =>
      _requests.where((r) => statuses.contains(r.status)).toList();

  Future<void> _openApplicants(MyRequest r) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RequestApplicantsScreen(
          requestId: r.id,
          requestTitle: r.title,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos'), centerTitle: false),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.labelLarge,
              unselectedLabelStyle: AppTypography.labelMedium,
              tabs: const [
                Tab(text: 'Activos'),
                Tab(text: 'Completados'),
                Tab(text: 'Cancelados'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _OrdersTab(
                          requests: _filter(
                              {'pending_review', 'open', 'assigned', 'in_progress'}),
                          onRefresh: _load,
                          onTap: _openApplicants,
                        ),
                        _OrdersTab(
                          requests: _filter({'completed'}),
                          onRefresh: _load,
                          onTap: _openApplicants,
                        ),
                        _OrdersTab(
                          requests: _filter({'cancelled', 'rejected'}),
                          onRefresh: _load,
                          onTap: _openApplicants,
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

/// Etiqueta + color legibles para cada estado de pedido.
({String label, Color color, Color bg}) _statusBadge(String status) {
  switch (status) {
    case 'pending_review':
      return (label: 'En revisión', color: AppColors.primary, bg: const Color(0xFFFFF0ED));
    case 'open':
      return (label: 'Publicado', color: const Color(0xFF2563EB), bg: const Color(0xFFE7EEFD));
    case 'assigned':
      return (label: 'Asignado', color: const Color(0xFF2ECC71), bg: const Color(0xFFE8F8EF));
    case 'in_progress':
      return (label: 'En curso', color: const Color(0xFF2ECC71), bg: const Color(0xFFE8F8EF));
    case 'completed':
      return (label: 'Completado', color: const Color(0xFF2ECC71), bg: const Color(0xFFE8F8EF));
    case 'cancelled':
      return (label: 'Cancelado', color: AppColors.neutral600, bg: AppColors.neutral200);
    case 'rejected':
      return (label: 'Rechazado', color: AppColors.neutral600, bg: AppColors.neutral200);
    default:
      return (label: status, color: AppColors.neutral600, bg: AppColors.neutral200);
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.requests,
    required this.onRefresh,
    required this.onTap,
  });

  final List<MyRequest> requests;
  final Future<void> Function() onRefresh;
  final void Function(MyRequest) onTap;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyOrdersPlaceholder(onRefresh: onRefresh);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _MyRequestCard(
          request: requests[i],
          onTap: () => onTap(requests[i]),
        ),
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.request, required this.onTap});

  final MyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(request.status);
    // Solo tiene sentido ver postulantes si el pedido está publicado/asignado.
    final canViewApplicants =
        request.status == 'open' || request.status == 'assigned';

    return GestureDetector(
      onTap: canViewApplicants ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(request.categoryEmoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.title,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 6),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.neutral500),
                const SizedBox(width: 4),
                Text(
                  request.districtName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const Spacer(),
                if (canViewApplicants) ...[
                  Icon(Icons.group_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${request.applicationsCount} postul.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersPlaceholder extends StatelessWidget {
  const _EmptyOrdersPlaceholder({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: AppColors.neutral300,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay pedidos',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
