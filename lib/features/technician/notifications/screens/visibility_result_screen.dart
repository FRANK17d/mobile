import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/loading_mascot.dart';

/// Pantalla de resultado del cambio de visibilidad del perfil.
///
/// Combina dos estados en una sola vista (tal como en los mockups):
///  1. **Procesando** — mascota animada + "Procesando... / Por favor espere".
///  2. **Éxito** — orbe (check verde si el perfil queda visible, ojos rojos si
///     queda oculto) + "Visibilidad actualizada con éxito" + "Ir a Inicio".
class VisibilityResultScreen extends StatefulWidget {
  const VisibilityResultScreen({super.key, required this.visible});

  /// Estado final del perfil tras guardar: visible (`true`) u oculto (`false`).
  final bool visible;

  @override
  State<VisibilityResultScreen> createState() => _VisibilityResultScreenState();
}

enum _Phase { processing, success }

class _VisibilityResultScreenState extends State<VisibilityResultScreen>
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

    // Simula el guardado y revela el estado de éxito.
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
                    visible: widget.visible,
                    scaleAnim: _scaleAnim,
                    fadeAnim: _fadeAnim,
                    controller: _revealController,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Estado: Procesando
// ─────────────────────────────────────────────────────────
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
            AppStrings.processing,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.pleaseWait,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Estado: Éxito
// ─────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.visible,
    required this.scaleAnim,
    required this.fadeAnim,
    required this.controller,
  });

  final bool visible;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final AnimationController controller;

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

          // ── Orbe de resultado (check verde / ojos rojos) ──
          AnimatedBuilder(
            animation: controller,
            builder: (_, _) => Transform.scale(
              scale: scaleAnim.value,
              child: visible ? const _SuccessCheckOrb() : const _HiddenEyesOrb(),
            ),
          ),

          const SizedBox(height: 40),

          // ── Texto de éxito ──
          FadeTransition(
            opacity: fadeAnim,
            child: Text(
              AppStrings.visibilityUpdated,
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // ── Botón "Ir a Inicio" ──
          FadeTransition(
            opacity: fadeAnim,
            child: GradientPillButton(
              label: AppStrings.goToHome,
              onTap: () => context.go(AppRoutes.techHome),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Orbes
// ─────────────────────────────────────────────────────────

/// Esfera verde brillante con check blanco (perfil visible).
class _SuccessCheckOrb extends StatelessWidget {
  const _SuccessCheckOrb();

  @override
  Widget build(BuildContext context) {
    return _OrbBase(
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.85,
        colors: [Color(0xFF7DDFB2), AppColors.success, Color(0xFF1FA855)],
        stops: [0.0, 0.5, 1.0],
      ),
      glowColor: AppColors.success,
      child: const Center(
        child: Icon(Icons.check_rounded, size: 72, color: Colors.white),
      ),
    );
  }
}

/// Esfera roja con dos "ojos" blancos (perfil oculto).
class _HiddenEyesOrb extends StatelessWidget {
  const _HiddenEyesOrb();

  @override
  Widget build(BuildContext context) {
    return _OrbBase(
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
        stops: [0.0, 0.5, 1.0],
      ),
      glowColor: AppColors.primary,
      child: CustomPaint(size: const Size(140, 140), painter: _EyesPainter()),
    );
  }
}

/// Base compartida de los orbes: tamaño, sombra difusa y glow.
class _OrbBase extends StatelessWidget {
  const _OrbBase({
    required this.gradient,
    required this.glowColor,
    required this.child,
  });

  final Gradient gradient;
  final Color glowColor;
  final Widget child;

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
                    color: glowColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // ── Esfera con gradiente ──
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Pinta dos ojos blancos con una leve sombra superior dentro del orbe rojo.
class _EyesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.52;
    final spacing = size.width * 0.2;
    final eyeRadius = size.width * 0.17;

    for (int i = 0; i < 2; i++) {
      final x = size.width * 0.5 + (i == 0 ? -spacing : spacing);
      final center = Offset(x, centerY);

      // Sombra superior sutil para dar volumen al ojo.
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center.translate(0, -3), eyeRadius, shadow);

      final eye = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, eyeRadius, eye);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
