import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mascota de carga de Toke+: una esfera roja que rebota suavemente con 3
/// puntos blancos pulsando en secuencia.
///
/// Animación reutilizable para cualquier pantalla de "procesando…"
/// (registro, verificación de correo, inicio de sesión con Google, etc.).
class LoadingMascot extends StatefulWidget {
  const LoadingMascot({super.key, this.size = 160});

  /// Lado del área cuadrada que ocupa la mascota. La esfera y la sombra se
  /// escalan proporcionalmente.
  final double size;

  @override
  State<LoadingMascot> createState() => _LoadingMascotState();
}

class _LoadingMascotState extends State<LoadingMascot>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _dotsController;
  late final Animation<double> _bounceY;

  @override
  void initState() {
    super.initState();

    // ── Rebote vertical de la esfera ──
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0, end: -16).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ── Pulso de los 3 puntos ──
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ballSize = widget.size * 0.8125; // 130/160
    final shadowWidth = widget.size * 0.625; // 100/160

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _bounceY.value), child: child),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Sombra difusa debajo ──
            Positioned(
              bottom: 0,
              child: Container(
                width: shadowWidth,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8836B).withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // ── Esfera principal ──
            Container(
              width: ballSize,
              height: ballSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFFF4A09A),
                    Color(0xFFEE7070),
                    Color(0xFFD94F4F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEE7070).withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _dotsController,
                builder: (_, _) => CustomPaint(
                  painter: _ThreeDotsPainter(progress: _dotsController.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta 3 puntos blancos que pulsan secuencialmente dentro de la esfera.
class _ThreeDotsPainter extends CustomPainter {
  const _ThreeDotsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    final spacing = size.width * 0.18;
    const baseRadius = 10.0;

    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.25) % 1.0;
      final scale = 0.6 + 0.4 * _pulse(phase);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 + 0.15 * _pulse(phase))
        ..style = PaintingStyle.fill;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final x = size.width * 0.5 + (i - 1) * spacing;

      canvas.drawCircle(
        Offset(x, centerY + 2),
        baseRadius * scale,
        shadowPaint,
      );
      canvas.drawCircle(Offset(x, centerY), baseRadius * scale, paint);
    }
  }

  double _pulse(double t) => (1 + math.sin(t * 3.14159 * 2)) / 2;

  @override
  bool shouldRepaint(covariant _ThreeDotsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
