import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/loading_mascot.dart';

/// Pantalla de carga que se muestra mientras se completa el inicio de sesión
/// con Google (intercambio OAuth + carga de perfil). Reutiliza la misma
/// animación de mascota que el registro, para que el usuario no se quede
/// unos segundos viendo el login mientras se procesa el callback.
class AuthProcessingScreen extends StatelessWidget {
  const AuthProcessingScreen({super.key, this.message = 'Iniciando sesión...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingMascot(),
              const SizedBox(height: 32),
              Text(
                message,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estamos preparando tu cuenta',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
