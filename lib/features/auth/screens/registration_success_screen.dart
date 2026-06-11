import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Pantalla de exito tras registro completado.
/// Muestra un check verde con animacion y boton "Ir a inicio".
class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({super.key, this.role = 'client'});

  /// Tipo de cuenta registrada: 'client' o 'provider'
  final String role;

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Iniciar animacion tras breve delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Icono de exito animado ──
                AnimatedBuilder(
                  animation: _animController,
                  builder: (_, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: _SuccessCheckOrb(),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ── Texto de exito ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'Registro realizado\ncon éxito',
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Boton "Ir a inicio" ──
                _GradientPillButton(
                  label: 'Ir a inicio',
                  onTap: () async {
                    if (widget.role == 'provider') {
                      // Activar la guía de cuenta solo para el primer ingreso tras registro
                      await AppPreferences.setShouldShowProviderGuide(true);
                    }

                    if (!context.mounted) return;

                    if (widget.role == 'provider') {
                      context.go(AppRoutes.techHome);
                    } else {
                      context.go(AppRoutes.clientHome);
                    }
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Esfera verde brillante con check blanco
class _SuccessCheckOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Sombra difusa ──
          Positioned(
            bottom: 4,
            child: Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // ── Esfera con gradiente verde ──
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 0.85,
                colors: [
                  Color(0xFF7DDFB2),
                  Color(0xFF2ECC71),
                  Color(0xFF1FA855),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 72, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton pill con gradiente naranja (igual que en client_registration_screen)
class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEE7070), Color(0xFFE85555)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEE7070).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decoraciones curvas ──
            Positioned(left: 16, top: 14, child: _CurlDecor(isLeft: true)),
            Positioned(right: 16, bottom: 14, child: _CurlDecor(isLeft: false)),
            // ── Texto central ──
            Center(
              child: Text(
                label,
                style: AppTypography.buttonLarge.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurlDecor extends StatelessWidget {
  const _CurlDecor({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _CurlPainter(isLeft: isLeft),
    );
  }
}

class _CurlPainter extends CustomPainter {
  const _CurlPainter({required this.isLeft});

  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width * 0.7, 0);
      path.quadraticBezierTo(
        0,
        size.height * 0.3,
        size.width * 0.2,
        size.height,
      );
    } else {
      path.moveTo(size.width * 0.3, 0);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.7,
        size.width * 0.8,
        size.height,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
