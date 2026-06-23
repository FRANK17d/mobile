import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../how_it_works/screens/how_it_works_screen.dart';
import '../../request_service/screens/order_review_screen.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';
import '../../request_service/services/request_service.dart';

/// "Mis pedidos realizados": lista los pedidos que el cliente ya publicó.
///
/// Se abre desde el menú del cliente autenticado → "Mis pedidos". Cuando no hay
/// pedidos, muestra el bloque "Publicá tu pedido en segundos" con los CTAs.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
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

  /// [silent] = true no muestra el loader (refrescos por realtime / al volver).
  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final list = await _service.getMyRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loading = false;
    });
  }

  void _openWizard() {
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const RequestServiceWizardScreen(),
          ),
        )
        .then((_) => _load(silent: true));
  }

  void _openHowItWorks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowItWorksScreen()),
    );
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header: volver + título + megáfono ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Mis pedidos realizados',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pedir servicio',
                      onPressed: _openWizard,
                      icon: const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.neutral200),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                    ? _EmptyMyRequests(
                        onPedir: _openWizard,
                        onComoFunciona: _openHowItWorks,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
                          itemCount: _requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _RequestCard(
                            request: _requests[i],
                            onTap: () => _openDetail(_requests[i]),
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
}

// ─────────────────────────────────────────────────────────
// Empty state estilo referencia ("Publicá tu pedido en segundos")
// ─────────────────────────────────────────────────────────
class _EmptyMyRequests extends StatelessWidget {
  const _EmptyMyRequests({required this.onPedir, required this.onComoFunciona});

  final VoidCallback onPedir;
  final VoidCallback onComoFunciona;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        24,
        AppSpacing.screenPaddingH,
        32,
      ),
      children: [
        // ── Ilustración vacía ──
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.neutral400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No se encuentra ninguna publicación',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 40),

        // ── Bloque "Publicá tu pedido en segundos" ──
        Text(
          'Publicá tu pedido en segundos',
          style: AppTypography.displaySmall.copyWith(
            color: const Color(0xFF162033),
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _StepRow(number: 1, text: 'Describí lo que necesitás'),
        const SizedBox(height: AppSpacing.md),
        const _StepRow(
          number: 2,
          text: 'Recibí interesados y elegí con quién trabajar',
        ),

        const SizedBox(height: AppSpacing.xxl),

        _PrimaryPillButton(label: 'Pedir servicio', onTap: onPedir),
        const SizedBox(height: 12),
        _OutlinePillButton(label: '¿Cómo funciona?', onTap: onComoFunciona),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE7EEFD),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTypography.headingMedium.copyWith(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: AppTypography.buttonLarge.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          label,
          style: AppTypography.buttonLarge.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de pedido propio
// ─────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final MyRequest request;
  final VoidCallback onTap;

  ({String label, Color color, Color bg}) _badge(String status) {
    switch (status) {
      case 'pending_review':
        return (
          label: 'En revisión',
          color: AppColors.primary,
          bg: const Color(0xFFFFF0ED),
        );
      case 'open':
        return (
          label: 'Publicado',
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFE7EEFD),
        );
      case 'assigned':
        return (
          label: 'Asignado',
          color: const Color(0xFF2ECC71),
          bg: const Color(0xFFE8F8EF),
        );
      case 'in_progress':
        return (
          label: 'En curso',
          color: const Color(0xFF2ECC71),
          bg: const Color(0xFFE8F8EF),
        );
      case 'completed':
        return (
          label: 'Completado',
          color: const Color(0xFF2ECC71),
          bg: const Color(0xFFE8F8EF),
        );
      case 'cancelled':
        return (
          label: 'Cancelado',
          color: AppColors.neutral600,
          bg: AppColors.neutral200,
        );
      case 'rejected':
        return (
          label: 'Rechazado',
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

  @override
  Widget build(BuildContext context) {
    final badge = _badge(request.status);

    return GestureDetector(
      onTap: onTap,
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
                Text(request.categoryEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 4),
                Text(
                  request.districtName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.neutral400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
