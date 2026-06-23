import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/loading_mascot.dart';
import 'order_review_screen.dart';

/// Resultado de publicar un pedido: muestra "Procesando..." y luego
/// "Pedido creado con éxito". "Aceptar" lleva al detalle del pedido en revisión
/// (si se conoce su id) o vuelve al inicio.
class RequestResultScreen extends StatefulWidget {
  const RequestResultScreen({super.key, this.requestId});

  /// Id del pedido recién creado, para abrir su ficha al aceptar.
  final String? requestId;

  @override
  State<RequestResultScreen> createState() => _RequestResultScreenState();
}

enum _Phase { processing, success }

class _RequestResultScreenState extends State<RequestResultScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.processing;

  late final AnimationController _revealController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.success);
      _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _onAccept() {
    final id = widget.requestId;
    if (id == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => OrderReviewScreen(requestId: id)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _phase == _Phase.processing
                ? const _ProcessingView()
                : _SuccessView(
                    scaleAnim: _scaleAnim,
                    fadeAnim: _fadeAnim,
                    controller: _revealController,
                    onAccept: _onAccept,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingMascot(),
          const SizedBox(height: 32),
          Text(
            'Procesando...',
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Por favor espere',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.scaleAnim,
    required this.fadeAnim,
    required this.controller,
    required this.onAccept,
  });

  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final AnimationController controller;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: controller,
            builder: (_, _) => Transform.scale(
              scale: scaleAnim.value,
              child: const BlueClock(size: 120),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeTransition(
            opacity: fadeAnim,
            child: Text(
              'Pedido creado con éxito',
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeTransition(
            opacity: fadeAnim,
            child: Text(
              'Nuestro equipo revisará tu pedido, te avisaremos cuando se '
              'publique en la plataforma.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(flex: 1),
          FadeTransition(
            opacity: fadeAnim,
            child: GradientPillButton(label: 'Aceptar', onTap: onAccept),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Reloj plano azul de dos tonos (icono de "en revisión / pendiente").
class BlueClock extends StatelessWidget {
  const BlueClock({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BlueClockPainter()),
    );
  }
}

class _BlueClockPainter extends CustomPainter {
  static const _ring = Color(0xFF4FC3F7);
  static const _ringLight = Color(0xFFB3E5FC);
  static const _face = Color(0xFFF5FBFE);
  static const _hands = Color(0xFF12355B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Aro exterior bicolor.
    canvas.drawCircle(center, radius, Paint()..color = _ringLight);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°
      3.1416, // media vuelta
      true,
      Paint()..color = _ring,
    );

    // Esfera.
    canvas.drawCircle(center, radius * 0.82, Paint()..color = _face);

    // Marcas de horas.
    final tick = Paint()
      ..color = _ringLight
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final outer = center + _polar(a, radius * 0.7);
      final inner = center + _polar(a, radius * 0.62);
      canvas.drawLine(inner, outer, tick);
    }

    // Manecillas (≈ 10:10).
    final hand = Paint()
      ..color = _hands
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + _polar(-0.9, radius * 0.4), hand);
    canvas.drawLine(center, center + _polar(2.1, radius * 0.52), hand);
    canvas.drawCircle(center, 4, Paint()..color = _hands);
  }

  /// Punto a [distance] del centro en el ángulo [angle], con 0 apuntando arriba.
  Offset _polar(double angle, double distance) =>
      Offset(math.sin(angle) * distance, -math.cos(angle) * distance);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
