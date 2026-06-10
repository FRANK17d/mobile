import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../../core/widgets/feedback/loading_mascot.dart';
import '../services/auth_service.dart';

/// Pantalla de procesamiento del registro.
/// Muestra la mascota con animacion de carga (3 puntos pulsando).
/// Intenta registrar via AuthService y continúa a verificación OTP.
class RegistrationProcessingScreen extends StatefulWidget {
  const RegistrationProcessingScreen({super.key, this.registrationData});

  final Map<String, dynamic>? registrationData;

  @override
  State<RegistrationProcessingScreen> createState() =>
      _RegistrationProcessingScreenState();
}

class _RegistrationProcessingScreenState
    extends State<RegistrationProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Ejecutar registro despues del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _performRegistration());
  }

  Future<void> _performRegistration() async {
    // Obtener datos de registration: primero del widget, luego del GoRouter extra
    final args =
        widget.registrationData ??
        (GoRouterState.of(context).extra as Map<String, dynamic>?);

    try {
      if (args != null) {
        final authService = AuthService();
        final role = args['role'] as String? ?? 'client';
        final email = args['email'] as String? ?? '';
        final password = args['password'] as String? ?? '';
        final name = '${args['name'] ?? ''} ${args['lastName'] ?? ''}'.trim();

        if (role == 'provider') {
          // ── Flujo técnico: solo crear usuario auth ──
          // Después navegará a OTP para verificar y completar perfil
          final success = await authService
              .register(email, password, name: name)
              .timeout(const Duration(seconds: 10), onTimeout: () => false);

          // Esperar mínimo para la animación
          await Future.delayed(const Duration(milliseconds: 2000));

          if (!mounted) return;

          if (success) {
            // Navegar a verificación OTP con los datos del registro
            context.go(
              '/register/otp',
              extra: {'email': email, 'registrationData': args},
            );
          } else {
            // Error al crear cuenta - mostrar error y volver
            _showErrorAndGoBack(
              'No se pudo crear la cuenta. Verifica que el correo no esté registrado.',
            );
          }
        } else {
          // ── Flujo cliente: crear usuario auth ──
          // Después navega a OTP para verificar y crear perfil client.
          final success = await authService
              .register(email, password, name: name)
              .timeout(const Duration(seconds: 8), onTimeout: () => false);

          await Future.delayed(const Duration(milliseconds: 2500));
          if (!mounted) return;

          if (success) {
            context.go(
              '/register/otp',
              extra: {'email': email, 'registrationData': args},
            );
          } else {
            _showErrorAndGoBack(
              'No se pudo crear la cuenta. Verifica que el correo no esté registrado.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      _showErrorAndGoBack('Error inesperado. Inténtalo de nuevo.');
    }
  }

  void _showErrorAndGoBack(String message) {
    showAppToast(
      context,
      message: message,
      type: ToastType.error,
      duration: const Duration(seconds: 4),
    );
    // Volver al formulario. Si no hay nada que desapilar (se llegó con go()),
    // volvemos al inicio del registro para no dejar la pantalla en negro.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.register);
    }
  }

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
              // ── Mascota animada (rebote + puntos) ──
              const LoadingMascot(),

              const SizedBox(height: 32),

              // ── Texto "Procesando..." ──
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
        ),
      ),
    );
  }
}
