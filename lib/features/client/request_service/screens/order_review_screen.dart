import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/request_widgets.dart';
import 'cancel_order_screen.dart';
import 'edit_order_screen.dart';

/// Acciones del menú de 3 puntos del pedido.
enum _OrderMenuAction { details, edit, cancel }

/// Detalle de un pedido en estado "en revisión".
///
/// Cabecera con número de pedido + menú (detalles / editar / cancelar), reloj
/// rojo, mensaje y acceso a soporte. Más abajo, la ficha del pedido.
/// Solo vista conectada, aún sin lógica de backend.
class OrderReviewScreen extends StatelessWidget {
  const OrderReviewScreen({super.key, this.orderNumber = '4022'});

  final String orderNumber;

  void _onMenuSelected(BuildContext context, _OrderMenuAction action) {
    switch (action) {
      case _OrderMenuAction.details:
        break; // Detalles: la ficha ya está más abajo en la misma pantalla.
      case _OrderMenuAction.edit:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EditOrderScreen()),
        );
      case _OrderMenuAction.cancel:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CancelOrderScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Nº $orderNumber',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _OrderMenu(
                      onSelected: (a) => _onMenuSelected(context, a),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
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
                              'Pedido en revisión',
                              style: AppTypography.displaySmall.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const StepProgressBar(total: 4, current: 1),
                            const SizedBox(height: AppSpacing.xxl),

                            // ── Reloj rojo ──
                            const Center(child: _RedClock(size: 150)),
                            const SizedBox(height: AppSpacing.xl),

                            Text(
                              'Estamos revisando tu pedido. Uno de nuestros '
                              'gestores se va a contactar con vos en breve para '
                              'confirmar los últimos detalles antes de '
                              'publicarlo.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ── Contactar soporte ──
                            const Center(child: _SupportButton()),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),

                      // ── Ficha del pedido ──
                      const _OrderCard(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
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
          child: _MenuRow(icon: Icons.info_outline, label: 'Detalles del pedido'),
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
// Botón "Contactar con soporte"
// ─────────────────────────────────────────────────────────
class _SupportButton extends StatelessWidget {
  const _SupportButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Sin lógica todavía.
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
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Carrusel de imágenes (placeholder) ──
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.neutral200,
              child: const Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.neutral400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _CarouselDots(count: 6, active: 1),
            ),
          ],
        ),

        // ── Datos ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Algún albañil',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _IconLine(icon: Icons.person_outline, text: 'Ahdb H.', bold: true),
              const SizedBox(height: AppSpacing.xs),
              _IconLine(
                icon: Icons.location_on_outlined,
                text: 'Mariano Roque Alonso, Paraguay',
              ),
            ],
          ),
        ),
      ],
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
  const _IconLine({required this.icon, required this.text, this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTypography.bodyLarge.copyWith(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Reloj rojo
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
    canvas.drawCircle(center + Offset(-radius * 1.15, -radius * 0.5), 8, bubble);
    canvas.drawCircle(center + Offset(-radius * 1.25, -radius * 0.05), 5, bubble);
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
