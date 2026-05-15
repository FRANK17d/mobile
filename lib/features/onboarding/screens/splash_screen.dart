import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// Splash Flutter mínimo.
///
/// El splash visual lo maneja Android/iOS de forma nativa. Esta pantalla solo
/// mantiene continuidad visual mientras Flutter entrega el primer frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _setSystemUI();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToNextRoute());
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

  void _goToNextRoute() {
    if (!mounted) return;

    // TODO: Verificar si es primera vez o si ya está autenticado.
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Image.asset(
          AppImages.logo,
          width: 124,
          height: 124,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
