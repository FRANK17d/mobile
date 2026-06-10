import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// Splash Flutter.
/// Mantiene la continuidad visual mientras Flutter inicia y comprueba la sesión persistente.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _setSystemUI();
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Redirección una vez termine la inicialización
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authState.isInitializing && mounted) {
        if (authState.status == AuthStatus.authenticated) {
          if (authState.viewMode == AppViewMode.technician) {
            context.go(AppRoutes.techHome);
          } else {
            context.go(AppRoutes.clientHome);
          }
        } else if (authState.hasCompletedOnboarding) {
          context.go(AppRoutes.login);
        } else {
          context.go(AppRoutes.onboarding);
        }
      }
    });

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
