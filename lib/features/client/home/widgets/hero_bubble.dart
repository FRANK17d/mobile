import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'categories_carousel.dart';

/// Burbuja hero del home con pregunta, buscador typewriter y categorias.
class HeroBubble extends StatelessWidget {
  const HeroBubble({super.key, this.onSearchTap, this.onCameraTap});

  final VoidCallback? onSearchTap;
  final VoidCallback? onCameraTap;

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
                  // Titulo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      AppStrings.homeQuestion,
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buscador con typewriter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: GestureDetector(
                      onTap: onSearchTap,
                      child: Container(
                        height: AppSpacing.inputHeight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neutral50,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
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
                            GestureDetector(
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
            )
            ,

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
