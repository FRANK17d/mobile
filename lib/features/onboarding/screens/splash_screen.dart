import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/auth/services/auth_store.dart';

/// Splash personalizado de Toke+.
///
/// Muestra logo + tagline con animaciones de entrada sutiles.
/// Mientras se muestra, pre-cachea assets pesados del Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();
    _setSystemUI();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo: escala de 0.8 → 1.0 con bounce
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Texto: aparece con fade + slide desde abajo
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
          ),
        );

    // Loader: aparece al final
    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });

    _navigateAfterReady();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundPrimary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _navigateAfterReady() async {
    await WidgetsBinding.instance.endOfFrame;

    // Ejecutar en paralelo: preferencias + precache + pausa visual + check sesión
    final authService = AuthService();
    final results = await Future.wait([
      AppPreferences.isOnboardingCompleted(),
      _precacheHomeAssets(),
      Future.delayed(const Duration(milliseconds: 2400)),
      authService.hasActiveSession(),
    ]);

    if (!mounted) return;

    final onboardingDone = results[0] as bool;
    final hasSession = results[3] as bool;

    if (hasSession) {
      // Sesión activa: determinar rol y navegar al home correspondiente.
      // Guardamos el resultado en AuthStore para que el home pinte el estado
      // autenticado desde el primer frame (sin parpadeo).
      final profile = await authService.getMyTechnicianProfile();
      if (!mounted) return;

      AuthStore.instance.setAuthenticated(profile);

      if (profile != null && profile['role'] == 'technician') {
        context.go(AppRoutes.techHome);
      } else {
        context.go(AppRoutes.clientHome);
      }
    } else if (onboardingDone) {
      // Sin sesión pero ya pasó el onboarding: vamos al home como usuario NO
      // autenticado (el login se alcanza desde el botón "Entrar"). Así, tras
      // cerrar sesión y reabrir la app, no aparece el login.
      AuthStore.instance.setUnauthenticated();
      context.go(AppRoutes.clientHome);
    } else {
      AuthStore.instance.setUnauthenticated();
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _precacheHomeAssets() async {
    try {
      await Future.wait([
        _precacheSvg(AppImages.mascot),
        _precacheSvg(AppImages.logoTextSvg),
        precacheImage(
          const AssetImage('assets/images/explorar-section.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/icon-whatssap.png'),
          context,
        ),
        precacheImage(const AssetImage('assets/images/icon-ig.png'), context),
      ]);
    } catch (_) {}
  }

  Future<void> _precacheSvg(String assetPath) async {
    final loader = SvgAssetLoader(assetPath);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo con escala animada ──
                Transform.scale(
                  scale: _logoScale.value,
                  child: Image.asset(
                    AppImages.logo,
                    width: 124,
                    height: 124,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tagline con fade + slide ──
                SlideTransition(
                  position: _textSlide,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          AppStrings.appTagline,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Indicador de carga sutil ──
                Opacity(
                  opacity: _loaderOpacity.value,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
