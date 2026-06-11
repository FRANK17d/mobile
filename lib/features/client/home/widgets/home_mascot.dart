import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';

/// Mascota animada del home usando el SVG personalizado.
///
/// Animaciones:
/// - Rebote vertical (bounce)
/// - Giro continuo de la pelota
/// - Cejas blancas animadas
/// - Parpadeo periodico (blink con escala Y)
/// - Efecto de respiracion en sombra
class HomeMascot extends StatefulWidget {
  const HomeMascot({super.key, this.size = 120});

  final double size;

  @override
  State<HomeMascot> createState() => _HomeMascotState();
}

class _HomeMascotState extends State<HomeMascot> with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _spinController;
  late final AnimationController _blinkController;
  late final AnimationController _breatheController;

  late final Animation<double> _bounceY;
  late final Animation<double> _rotation;
  late final Animation<double> _blinkScale;
  late final Animation<double> _shadowScale;

  @override
  void initState() {
    super.initState();

    // ── Rebote vertical ──
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _bounceY = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ── Balanceo suave (rocking) ──
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _rotation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOut),
    );

    // ── Parpadeo (squish vertical rapido) ──
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _blinkScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
        );

    // ── Sombra que respira ──
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _shadowScale = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Diferir inicio de animaciones para no bloquear el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bounceController.repeat(reverse: true);
      _spinController.repeat(reverse: true);
      _breatheController.repeat(reverse: true);
      _scheduleNextBlink();
    });
  }

  void _scheduleNextBlink() {
    final delay = Duration(milliseconds: 2000 + (math.Random().nextInt(3000)));
    Future.delayed(delay, () {
      if (mounted) {
        _blinkController.forward(from: 0).then((_) {
          if (mounted) _scheduleNextBlink();
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _spinController.dispose();
    _blinkController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Sombra en el piso ──
          Positioned(
            bottom: 0,
            child: AnimatedBuilder(
              animation: _breatheController,
              builder: (_, _) {
                return Transform.scale(
                  scale: _shadowScale.value,
                  child: Container(
                    width: widget.size * 0.45,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.15),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Mascota SVG animada ──
          AnimatedBuilder(
            animation: Listenable.merge([
              _bounceController,
              _spinController,
              _blinkController,
            ]),
            builder: (_, child) {
              return Transform.translate(
                offset: Offset(0, _bounceY.value),
                child: Transform.rotate(
                  angle: _rotation.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      1.0,
                      _blinkScale.value,
                      1.0,
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: RepaintBoundary(
              child: SvgPicture.asset(
                AppImages.mascot,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
