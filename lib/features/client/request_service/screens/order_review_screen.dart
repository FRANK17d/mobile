import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../client/reviews/screens/submit_review_screen.dart';
import '../../../support/screens/ai_support_screen.dart';
import '../services/request_service.dart';
import '../widgets/request_widgets.dart';
import 'cancel_order_screen.dart';
import 'edit_order_screen.dart';
import 'request_applicants_screen.dart';

/// Acciones del menú de 3 puntos del pedido.
enum _OrderMenuAction { details, edit, cancel }

/// Detalle de un pedido del cliente, conectado a datos reales.
///
/// Carga la ficha con [RequestService.getRequestDetail] y adapta cabecera,
/// menú (editar/cancelar solo antes de asignar) y acceso a postulaciones según
/// el estado. Se llega aquí desde "Mis Pedidos" o tras crear un pedido.
class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key, required this.requestId, this.initial});

  final String requestId;

  /// Datos ya conocidos del pedido (de la lista) para pintar al instante
  /// mientras llega la ficha completa. Opcional.
  final MyRequest? initial;

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  final RequestService _service = RequestService();

  RequestDetail? _detail;
  bool _loading = true;

  final List<VoidCallback> _rtUnsub = [];
  late final String _channel = 'request:${widget.requestId}';

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  Future<void> _setupRealtime() async {
    final rt = RealtimeService.instance;
    await rt.connect();
    rt.subscribe(_channel);
    void refresh(Map<String, dynamic> _) {
      if (mounted) _load();
    }

    // status_changed: aprobación/cancelación/asignación. request_updated: edición
    // de los campos del pedido (descripción, fecha, dirección, factura).
    _rtUnsub.add(rt.on('status_changed', refresh));
    _rtUnsub.add(rt.on('request_updated', refresh));
  }

  @override
  void dispose() {
    for (final off in _rtUnsub) {
      off();
    }
    RealtimeService.instance.unsubscribe(_channel);
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await _service.getRequestDetail(widget.requestId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _onMenuSelected(_OrderMenuAction action) async {
    final detail = _detail;
    if (detail == null) return;
    switch (action) {
      case _OrderMenuAction.details:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailScreen(detail: detail),
          ),
        );
      case _OrderMenuAction.edit:
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => EditOrderScreen(detail: detail),
          ),
        );
        if (changed == true) _load();
      case _OrderMenuAction.cancel:
        final cancelled = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CancelOrderScreen(requestId: detail.id),
          ),
        );
        if (cancelled == true && mounted) {
          showAppToast(
            context,
            message: 'Pedido cancelado.',
            type: ToastType.success,
          );
          Navigator.of(context).pop(true);
        }
    }
  }

  Future<void> _openApplicants() async {
    final detail = _detail;
    if (detail == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RequestApplicantsScreen(
          requestId: detail.id,
          requestTitle: detail.title,
        ),
      ),
    );
    if (changed == true) _load();
  }

  void _openDetail() {
    final detail = _detail;
    if (detail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(detail: detail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    // Número de pedido legible (secuencial) para la cabecera.
    final orderNum = detail?.orderNumber ?? widget.initial?.orderNumber;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: X + Nº + menú ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Nº ${formatOrderNumber(orderNum)}',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (detail != null && detail.canManage)
                      _OrderMenu(onSelected: _onMenuSelected),
                  ],
                ),
              ),

              Expanded(
                child: _loading && detail == null
                    ? const Center(child: CircularProgressIndicator())
                    : detail == null
                    ? _NotFound(onClose: () => Navigator.of(context).maybePop())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _Body(
                          detail: detail,
                          onOpenApplicants: _openApplicants,
                          onOpenDetail: _openDetail,
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
// Detalle completo del pedido (ficha + imágenes)
// ─────────────────────────────────────────────────────────
/// Se abre desde "Ver detalle de pedido" o el menú de 3 puntos. Muestra la
/// ficha completa (imágenes, categoría, descripción, ubicación, factura, fecha).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.detail});

  final RequestDetail detail;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Detalle · Nº ${formatOrderNumber(detail.orderNumber)}',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderCard(detail: detail),
              if (detail.preferredDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _IconLine(
                    icon: Icons.event_outlined,
                    text:
                        'Fecha preferida: ${_formatDate(detail.preferredDate!)}',
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Cuerpo según estado
// ─────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body({
    required this.detail,
    required this.onOpenApplicants,
    required this.onOpenDetail,
  });

  final RequestDetail detail;
  final VoidCallback onOpenApplicants;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final header = _statusHeader(detail.status);
    final step = _stepForStatus(detail.status);
    final showApplicants =
        detail.status == 'open' ||
        detail.status == 'assigned' ||
        detail.status == 'in_progress';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  header.big,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (step > 0) ...[
                  StepProgressBar(total: 4, current: step),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                if (header.clock) ...[
                  const Center(child: _RedClock(size: 150)),
                  const SizedBox(height: AppSpacing.xl),
                ],

                Text(
                  header.sub,
                  textAlign: header.clock ? TextAlign.center : TextAlign.start,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Motivo del rechazo (si el admin lo dejó) ──
                if (detail.status == 'rejected' &&
                    detail.rejectionReason != null &&
                    detail.rejectionReason!.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Motivo del rechazo',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail.rejectionReason!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (showApplicants) ...[
                  _ApplicantsButton(
                    count: detail.applicationsCount,
                    onTap: onOpenApplicants,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Calificar técnico ──
                if (detail.assignedTechnicianId != null &&
                    (detail.status == 'assigned' ||
                        detail.status == 'in_progress' ||
                        detail.status == 'completed')) ...[
                  _RateButton(
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => SubmitReviewScreen(
                              requestId: detail.id,
                              technicianName: 'tu técnico',
                              requestTitle: detail.title,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (detail.status == 'pending_review') ...[
                  Center(
                    child: _SupportButton(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AiSupportScreen(),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            ),
          ),

          // ── Ver detalle del pedido (la ficha completa se abre aparte) ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: _DetailButton(onTap: onOpenDetail),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// Botón "Ver detalle de pedido".
class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 22,
              color: AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ver detalle de pedido',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Texto de cabecera según el estado del pedido.
({String big, String sub, bool clock}) _statusHeader(String status) {
  switch (status) {
    case 'pending_review':
      return (
        big: 'Pedido en revisión',
        sub:
            'Estamos revisando tu pedido. Uno de nuestros gestores se va a '
            'contactar con vos en breve para confirmar los últimos detalles '
            'antes de publicarlo.',
        clock: true,
      );
    case 'open':
      return (
        big: 'Pedido publicado',
        sub:
            'Tu pedido ya es visible para los técnicos de tu zona. Te '
            'avisaremos cuando alguien se postule.',
        clock: false,
      );
    case 'assigned':
      return (
        big: 'Técnico asignado',
        sub:
            'Elegiste un técnico para este pedido. Coordina con él los '
            'detalles del trabajo desde el chat.',
        clock: false,
      );
    case 'in_progress':
      return (
        big: 'Trabajo en curso',
        sub: 'El trabajo está en marcha.',
        clock: false,
      );
    case 'completed':
      return (
        big: 'Pedido completado',
        sub: 'Este pedido se marcó como completado.',
        clock: false,
      );
    case 'cancelled':
      return (
        big: 'Pedido cancelado',
        sub: 'Cancelaste este pedido, ya no está disponible en la plataforma.',
        clock: false,
      );
    case 'rejected':
      return (
        big: 'Pedido no aprobado',
        sub: 'Este pedido no pasó la revisión. Puedes crear uno nuevo.',
        clock: false,
      );
    default:
      return (big: 'Pedido', sub: '', clock: false);
  }
}

/// Paso de la barra de progreso (0 = ocultar) según el estado.
int _stepForStatus(String status) => switch (status) {
  'pending_review' => 1,
  'open' => 2,
  'assigned' || 'in_progress' => 3,
  'completed' => 4,
  _ => 0, // cancelled / rejected: sin barra
};

// ─────────────────────────────────────────────────────────
// Menú de 3 puntos
// ─────────────────────────────────────────────────────────
class _OrderMenu extends StatelessWidget {
  const _OrderMenu({required this.onSelected});

  final ValueChanged<_OrderMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OrderMenuAction>(
      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _OrderMenuAction.details,
          child: _MenuRow(
            icon: Icons.info_outline,
            label: 'Detalles del pedido',
          ),
        ),
        PopupMenuItem(
          value: _OrderMenuAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Editar pedido'),
        ),
        PopupMenuItem(
          value: _OrderMenuAction.cancel,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Cancelar pedido',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Botón "Ver postulaciones"
// ─────────────────────────────────────────────────────────
class _ApplicantsButton extends StatelessWidget {
  const _ApplicantsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              count > 0 ? 'Ver postulaciones ($count)' : 'Ver postulaciones',
              style: AppTypography.buttonMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFC107),
          side: const BorderSide(color: Color(0xFFFFC107)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 20, color: Color(0xFFFFC107)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Calificar técnico',
              style: AppTypography.buttonMedium.copyWith(
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

// ─────────────────────────────────────────────────────────
// Botón "Contactar con soporte"
// ─────────────────────────────────────────────────────────
class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, size: 14, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Contactar con soporte',
              style: AppTypography.titleLarge.copyWith(
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
// Ficha del pedido
// ─────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final location = [
      detail.districtName,
      if (detail.address != null && detail.address!.isNotEmpty) detail.address!,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Carrusel de imágenes (reales o placeholder) ──
        _ImageCarousel(urls: detail.imageUrls),

        // ── Datos ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (detail.categoryEmoji.isNotEmpty) ...[
                    Text(
                      detail.categoryEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      detail.title.isEmpty ? detail.categoryName : detail.title,
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (detail.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.description,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (location.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _IconLine(icon: Icons.location_on_outlined, text: location),
              ],
              if (detail.needsInvoice) ...[
                const SizedBox(height: AppSpacing.xs),
                _IconLine(
                  icon: Icons.receipt_long_outlined,
                  text: 'Requiere factura legal',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Carrusel horizontal de imágenes del pedido; placeholder si no hay.
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final PageController _controller = PageController();
  int _active = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: AppColors.neutral200,
        child: const Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.neutral400,
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _active = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => _FullScreenImageViewer(
                    urls: widget.urls,
                    initialIndex: i,
                  ),
                ),
              ),
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.neutral200,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: AppColors.neutral400,
                  ),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.neutral200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
            ),
          ),
        ),
        // Indicador de "tocar para ampliar".
        const Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.fullscreen_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _CarouselDots(count: widget.urls.length, active: _active),
          ),
      ],
    );
  }
}

/// Visor de imágenes a pantalla completa, con zoom y botón de cerrar.
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({required this.urls, this.initialIndex = 0});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pc = PageController(
    initialPage: widget.initialIndex,
  );
  late int _active = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _active = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.urls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Botón cerrar.
            Positioned(
              top: topPad + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

            // Indicadores si hay varias.
            if (widget.urls.length > 1)
              Positioned(
                bottom: bottomPad + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _CarouselDots(
                    count: widget.urls.length,
                    active: _active,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final isActive = i == active;
          return Container(
            width: isActive ? 16 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.neutral300,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          );
        }),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar el pedido',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puede que ya no exista o no esté disponible.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onClose, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Reloj rojo (estado "en revisión")
// ─────────────────────────────────────────────────────────
class _RedClock extends StatelessWidget {
  const _RedClock({this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RedClockPainter()),
    );
  }
}

class _RedClockPainter extends CustomPainter {
  static const _ring = Color(0xFFE8516B);
  static const _face = Color(0xFFEFF3F6);
  static const _hands = Color(0xFF2B3A4B);
  static const _second = Color(0xFF7FD3F0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Burbujas grises alrededor.
    final bubble = Paint()..color = AppColors.neutral200;
    canvas.drawCircle(
      center + Offset(-radius * 1.15, -radius * 0.5),
      8,
      bubble,
    );
    canvas.drawCircle(
      center + Offset(-radius * 1.25, -radius * 0.05),
      5,
      bubble,
    );
    canvas.drawCircle(center + Offset(radius * 1.2, radius * 0.55), 7, bubble);
    canvas.drawCircle(center + Offset(radius * 1.35, radius * 0.25), 4, bubble);

    // Aro rojo + esfera.
    canvas.drawCircle(center, radius, Paint()..color = _ring);
    canvas.drawCircle(center, radius * 0.82, Paint()..color = _face);

    // Marcas.
    final tick = Paint()
      ..color = _hands
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        center + _polar(a, radius * 0.72),
        center + _polar(a, radius * 0.6),
        tick,
      );
    }

    // Manecillas.
    final hand = Paint()
      ..color = _hands
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + _polar(-0.6, radius * 0.42), hand);
    canvas.drawLine(center, center + _polar(0.9, radius * 0.52), hand);

    // Segundero celeste.
    canvas.drawLine(
      center,
      center + _polar(2.4, radius * 0.6),
      Paint()
        ..color = _second
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 5, Paint()..color = _ring);
  }

  Offset _polar(double angle, double distance) =>
      Offset(math.sin(angle) * distance, -math.cos(angle) * distance);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
