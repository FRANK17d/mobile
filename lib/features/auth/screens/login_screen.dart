import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../services/auth_store.dart';

/// Pantalla de inicio de sesion.
/// Header oscuro con logo toke+ animado,
/// formulario con correo electronico y contraseña, boton "Ingresar".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  // Errores de validación inline (null = sin error). Pintan el borde rojo y un
  // mensaje accesible bajo cada campo.
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  /// Si el usuario activó el acceso biométrico, lanza el prompt de huella
  /// automáticamente al abrir el login (sin botón).
  Future<void> _checkBiometric() async {
    if (!await BiometricService.instance.isEnabled()) return;
    if (!mounted) return;
    _handleBiometricLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Ingresá tu correo electrónico';
    final emailRegex = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Ingresá un correo válido';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Ingresá tu contraseña';
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF1D2939),
          body: Column(
            children: [
              // ── Header oscuro con logo animado ──
              _HeaderSection(topPadding: topPadding),

              // ── Formulario blanco con bordes redondeados ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Correo electrónico ──
                        Text(
                          'Correo electrónico',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _EmailField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),

                        const SizedBox(height: 24),

                        // ── Contraseña ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contraseña',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Semantics(
                              label: 'Olvidé mi contraseña',
                              button: true,
                              child: GestureDetector(
                                onTap: () => _showForgotPasswordModal(context),
                                child: Text(
                                  'Olvidé mi contraseña',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PasswordField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscure: _obscurePassword,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          onSubmitted: (_) => _handleLogin(),
                          onToggle: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        // ── Boton Ingresar ──
                        _LoginButton(
                          onTap: _isLoggingIn ? null : _handleLogin,
                          isLoading: _isLoggingIn,
                        ),

                        const SizedBox(height: 20),

                        // ── Separador "o" ──
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.neutral300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'o',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.neutral300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Boton Google ──
                        _GoogleSignInButton(onTap: _handleGoogleLogin),

                        const SizedBox(height: 28),

                        // ── Divider ──
                        Container(height: 1, color: AppColors.neutral200),

                        const SizedBox(height: 24),

                        // ── Registrate ──
                        Center(
                          child: Semantics(
                            label: '¿No tenés una cuenta? Registrate',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                context.push(AppRoutes.register);
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: '¿No tenés una cuenta? ',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Registrate',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validación inline: borde rojo + mensaje bajo el campo. Enfocamos el
    // primer campo con error para facilitar la corrección.
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _isLoggingIn = true);

    final authService = AuthService();
    final userId = await authService.login(email, password);

    if (!mounted) return;

    if (userId == null) {
      setState(() {
        _isLoggingIn = false;
        _passwordError = 'Correo o contraseña incorrectos';
      });
      showAppToast(
        context,
        message: 'Correo o contraseña incorrectos',
        type: ToastType.error,
      );
      return;
    }

    await _completeLogin(email, password, userId: userId);
  }

  /// Carga el perfil, persiste la sesión y navega al home correspondiente.
  /// Al reloguear con contraseña ofrece activar la biometría.
  Future<void> _completeLogin(
    String email,
    String password, {
    String? userId,
    bool fromBiometric = false,
  }) async {
    final profile = await AuthService().getMyTechnicianProfile();
    if (!mounted) return;

    if (!fromBiometric) {
      await _maybeOfferBiometric(email, password, userId);
      if (!mounted) return;
    }

    setState(() => _isLoggingIn = false);

    // Persistimos la sesión en memoria para que el home no re-chequee por red.
    AuthStore.instance.setAuthenticated(profile);

    if (profile != null && profile['role'] == 'technician') {
      context.go(AppRoutes.techHome);
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

  /// Si el equipo soporta biometría y aún no está activada para ESTE usuario,
  /// pregunta si quiere activarla con las credenciales que acaba de usar.
  Future<void> _maybeOfferBiometric(
    String email,
    String password,
    String? userId,
  ) async {
    final bio = BiometricService.instance;
    // Ya activada para este mismo usuario: no volver a preguntar.
    if (await bio.isEnabled() && await bio.enabledUserId() == userId) return;
    if (!await bio.isDeviceSupported()) return;
    if (!mounted) return;

    final wants = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.fingerprint_rounded,
          color: AppColors.primary,
          size: 44,
        ),
        title: Text(
          'Activar acceso con huella',
          textAlign: TextAlign.center,
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'La próxima vez podrás entrar con tu huella o rostro, sin escribir tu '
          'contraseña.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Ahora no',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (wants != true || !mounted) return;
    final ok = await bio.enable(
      email: email,
      password: password,
      userId: userId,
    );
    if (!mounted) return;
    if (ok) {
      showAppToast(
        context,
        message: 'Acceso biométrico activado.',
        type: ToastType.success,
      );
    }
  }

  /// Inicia sesión con las credenciales guardadas tras verificación biométrica.
  Future<void> _handleBiometricLogin() async {
    if (_isLoggingIn) return;
    final creds = await BiometricService.instance.getCredentials();
    if (!mounted || creds == null) return;

    setState(() => _isLoggingIn = true);
    final result = await AuthService().loginDetailed(
      creds.email,
      creds.password,
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isLoggingIn = false);
      if (result.invalidCredentials) {
        await BiometricService.instance.disable();
        if (!mounted) return;
        showAppToast(
          context,
          message: 'El acceso biométrico venció. Ingresá con tu contraseña.',
          type: ToastType.error,
        );
        return;
      }

      showAppToast(
        context,
        message: 'No pudimos iniciar con biometría. Usa tu contraseña.',
        type: ToastType.error,
      );
      return;
    }
    await _completeLogin(
      creds.email,
      creds.password,
      userId: result.userId,
      fromBiometric: true,
    );
  }

  void _showForgotPasswordModal(BuildContext context) {
    showForgotPasswordModal(context);
  }

  Future<void> _handleGoogleLogin() async {
    final launched = await AuthService().loginWithGoogle();

    if (!mounted) return;

    if (!launched) {
      showAppToast(
        context,
        message: 'No se pudo abrir Google. Inténtalo de nuevo.',
        type: ToastType.error,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────
// Header con logo toke+ animado
// ─────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          // ── AppBar: flecha atras + titulo ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Semantics(
                  label: 'Volver',
                  button: true,
                  child: IconButton(
                    onPressed: () {
                      // Login se alcanza con context.go() (es la raíz, sin pila
                      // debajo). Un Navigator.pop() vaciaría el Navigator y dejaría
                      // la pantalla en negro. Si no hay nada que desapilar, salimos
                      // de la app limpiamente.
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        SystemNavigator.pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Iniciar sesión',
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Logo SVG toke+ animado ──
          const SizedBox(height: 24),
          _AnimatedLogo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Logo animado con shimmer
// ─────────────────────────────────────────────────────────
class _AnimatedLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
          AppImages.logoTextSvg,
          height: 64,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideX(begin: -0.05, end: 0, duration: 800.ms)
        .then(delay: 2000.ms)
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}

// ─────────────────────────────────────────────────────────
// Campo de email
// ─────────────────────────────────────────────────────────
class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    this.focusNode,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.neutral300,
        width: hasError ? 1.5 : 1,
      ),
    );

    return _FieldShell(
      errorText: errorText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        autocorrect: false,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'tu@email.com',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppColors.neutral500,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.neutral100,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Contenedor de campo: borde (rojo si hay error) + mensaje de error accesible
// ─────────────────────────────────────────────────────────
class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child, this.errorText});

  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 15,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    errorText!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Campo de contraseña
// ─────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.focusNode,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.neutral300,
        width: hasError ? 1.5 : 1,
      ),
    );

    return _FieldShell(
      errorText: errorText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.neutral500,
            size: 20,
          ),
          suffixIcon: Semantics(
            label: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
            button: true,
            child: IconButton(
              onPressed: onToggle,
              tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.neutral500,
                size: 20,
              ),
            ),
          ),
          filled: true,
          fillColor: AppColors.neutral100,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "Ingresar" con gradient rojo suave y CurlDecor
// ─────────────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ingresar',
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEE7070), Color(0xFFE85555)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEE7070).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Decoraciones curvas en esquinas ──
              const Positioned(
                left: 16,
                top: 14,
                child: _CurlDecor(isLeft: true),
              ),
              const Positioned(
                right: 16,
                bottom: 14,
                child: _CurlDecor(isLeft: false),
              ),
              // ── Texto central ──
              Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Ingresar',
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "Iniciar sesion con Google"
// ─────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Iniciar sesión con Google',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icono de Google oficial (SVG) ──
              SvgPicture.asset(
                'assets/icons/google_g.svg',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Iniciar sesión con Google',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.neutral800,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Decoraciones tipo curl en los bordes del boton
// ─────────────────────────────────────────────────────────
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
  bool shouldRepaint(covariant _CurlPainter oldDelegate) =>
      isLeft != oldDelegate.isLeft;
}
