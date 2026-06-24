import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../request_service/services/request_service.dart';
import 'categories_carousel.dart';

/// Burbuja hero del home con pregunta, buscador typewriter y categorias.
class HeroBubble extends StatelessWidget {
  const HeroBubble({
    super.key,
    this.onSearchTap,
    this.onCameraTap,
    this.title,
    this.myRequests = const [],
    this.loadingOrders = false,
    this.onOpenOrder,
    this.onSeeAllOrders,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onCameraTap;

  /// Título sobre el buscador. Si es null usa [AppStrings.homeQuestion].
  final String? title;

  /// Pedidos del cliente. Si hay, se muestran como carrusel "Tus pedidos" en
  /// lugar del título.
  final List<MyRequest> myRequests;

  /// Mientras es true muestra un skeleton animado en lugar del carrusel/saludo.
  final bool loadingOrders;
  final ValueChanged<MyRequest>? onOpenOrder;
  final VoidCallback? onSeeAllOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Burbuja blanca ──
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.only(top: 26, bottom: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: "Tus pedidos" (si hay) o el saludo. Sin skeleton:
              // al llegar los pedidos, la card se expande y aparecen suave.
              AnimatedSize(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  child: myRequests.isNotEmpty
                      ? _OrdersStrip(
                          key: const ValueKey('orders'),
                          requests: myRequests,
                          onOpenOrder: onOpenOrder,
                          onSeeAll: onSeeAllOrders,
                        )
                      : Padding(
                          key: const ValueKey('greeting'),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title ?? AppStrings.homeQuestion,
                              maxLines: 1,
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Buscador con typewriter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _PressableScale(
                  onTap: onSearchTap,
                  child: Container(
                    height: AppSpacing.inputHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TypewriterText(
                            phrases: const [
                              'Electricista cerca de mi...',
                              'Plomero para mi hogar...',
                              'Pintor profesional...',
                              'Servicio de limpieza...',
                              'Cerrajero urgente...',
                              'Tecnico de aire acondicionado...',
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PressableScale(
                          onTap: onCameraTap ?? onSearchTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Carrusel de categorias dentro de la tarjeta, debajo del buscador.
              const CategoriesCarousel(),
            ],
          ),
        ),

        // ── Cola de burbuja (triangulo) ──
        Align(
          alignment: const Alignment(0, 0),
          child: CustomPaint(
            size: const Size(28, 14),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }
}

// ─── "Tus pedidos": carrusel horizontal con snap dentro de la card ───
class _OrdersStrip extends StatefulWidget {
  const _OrdersStrip({
    super.key,
    required this.requests,
    this.onOpenOrder,
    this.onSeeAll,
  });

  final List<MyRequest> requests;
  final ValueChanged<MyRequest>? onOpenOrder;
  final VoidCallback? onSeeAll;

  @override
  State<_OrdersStrip> createState() => _OrdersStripState();
}

class _OrdersStripState extends State<_OrdersStrip> {
  // Una tarjeta por vista (sin asomar la siguiente) y con snap automático.
  final PageController _pc = PageController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Text(
                'Tus pedidos',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B7280),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 192,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.requests.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _HomeOrderCard(
                request: widget.requests[i],
                onTap: () => widget.onOpenOrder?.call(widget.requests[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta + colores del estado del pedido (versión compacta para el home).
({String label, Color color, Color bg}) _homeStatusBadge(String status) {
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
        label: 'No aprobado',
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

class _HomeOrderCard extends StatelessWidget {
  const _HomeOrderCard({required this.request, required this.onTap});

  final MyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _homeStatusBadge(request.status);
    final title = request.title.isEmpty ? request.categoryName : request.title;
    final thumb = request.thumbnailUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nº + estado ──
          Row(
            children: [
              if (request.orderNumber != null)
                Text(
                  'Nº ${formatOrderNumber(request.orderNumber)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 12),

          // ── Contenido + miniatura ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (request.categoryEmoji.isNotEmpty) ...[
                          Text(
                            request.categoryEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                        ],
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
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.districtName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (thumb != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CachedNetworkImage(
                      imageUrl: thumb,
                      memCacheWidth: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: AppColors.neutral200,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.neutral400,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Más información ──
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                'Más información',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white,
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

// ─── Escala al presionar (feedback táctil) ───
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── Typewriter animado ───
class _TypewriterText extends StatefulWidget {
  const _TypewriterText({required this.phrases});

  final List<String> phrases;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _phraseIndex = 0;
  String _displayText = '';
  Timer? _timer;

  static const _typeSpeed = Duration(milliseconds: 60);
  static const _deleteSpeed = Duration(milliseconds: 30);
  static const _pauseAfterType = Duration(milliseconds: 2000);
  static const _pauseAfterDelete = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    // Diferir inicio del typewriter para no competir con el primer frame
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startTyping();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    final target = widget.phrases[_phraseIndex];

    _timer = Timer.periodic(_typeSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_displayText.length < target.length) {
        setState(() {
          _displayText = target.substring(0, _displayText.length + 1);
        });
      } else {
        timer.cancel();
        // Pausa despues de escribir todo
        _timer = Timer(_pauseAfterType, _startDeleting);
      }
    });
  }

  void _startDeleting() {
    _timer = Timer.periodic(_deleteSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_displayText.isNotEmpty) {
        setState(() {
          _displayText = _displayText.substring(0, _displayText.length - 1);
        });
      } else {
        timer.cancel();
        _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        _timer = Timer(_pauseAfterDelete, _startTyping);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            _displayText,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Cursor parpadeante
        _BlinkingCursor(color: AppColors.primary),
      ],
    );
  }
}

// ─── Cursor parpadeante ───
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    // Diferir inicio para no bloquear primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 18,
            margin: const EdgeInsets.only(left: 1),
            color: widget.color,
          ),
        );
      },
    );
  }
}

// ─── Pintor de la cola de la burbuja ───
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
