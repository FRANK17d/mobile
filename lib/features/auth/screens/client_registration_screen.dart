import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/inputs/terms_acceptance.dart';
import '../services/district_service.dart';
import 'district_selector_screen.dart';

/// Valida que [raw] sea un celular peruano (9 dígitos que empiezan en 9).
bool _isValidPeruPhone(String raw) {
  final digits = raw.replaceAll(' ', '');
  return digits.length == 9 && digits.startsWith('9');
}

/// Mensaje de error inline para el teléfono, o null si es válido / vacío.
String? _peruPhoneError(String raw) {
  final digits = raw.replaceAll(' ', '');
  if (digits.isEmpty) return null;
  if (!digits.startsWith('9')) return 'Los celulares en Perú empiezan con 9';
  if (digits.length != 9) return 'El número debe tener 9 dígitos';
  return null;
}

/// Registro de clientes - Flujo de 3 pasos:
/// Step 1: Nombre, Apellido, Distrito
/// Step 2: Telefono (+51, max 9 digitos), Correo
/// Step 3: Contrasena (min 6 chars con validacion visual) y terminos
class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  // ── Step 1 controllers ──
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  District? _selectedDistrict;

  // ── Step 2 controllers ──
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // ── Step 3 controllers ──
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Cierra el teclado antes de navegar
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _nextStep() {
    _dismissKeyboard();

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    _dismissKeyboard();

    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 3 &&
            _lastNameController.text.trim().length >= 3 &&
            _selectedDistrict != null;
      case 1:
        return _isValidPeruPhone(_phoneController.text) &&
            _emailController.text.trim().contains('@');
      case 2:
        return _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text &&
            _acceptTerms;
      default:
        return false;
    }
  }

  void _submitRegistration() {
    _dismissKeyboard();
    context.push(
      '/register/processing',
      extra: {
        'name': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'district': _selectedDistrict?.name,
        'districtId': _selectedDistrict?.id,
        'phone': _phoneController.text.replaceAll(' ', '').trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'client',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        // Cerrar teclado al tocar fuera de campos
        onTap: _dismissKeyboard,
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                // ── AppBar con flecha y titulo ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Volver al paso anterior',
                        child: IconButton(
                          onPressed: _previousStep,
                          tooltip: 'Volver',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        header: true,
                        child: Text(
                          'Registro de clientes',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Progress bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Semantics(
                    label: 'Paso ${_currentStep + 1} de $_totalSteps',
                    child: _StepProgressBar(
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Pages ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _Step1PersonalInfo(
                        nameController: _nameController,
                        lastNameController: _lastNameController,
                        selectedDistrict: _selectedDistrict,
                        onDistrictSelected: (district) {
                          setState(() => _selectedDistrict = district);
                        },
                        onChanged: () => setState(() {}),
                      ),
                      _Step2Contact(
                        phoneController: _phoneController,
                        emailController: _emailController,
                        onChanged: () => setState(() {}),
                      ),
                      _Step3Password(
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        acceptTerms: _acceptTerms,
                        onTogglePassword: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        onToggleConfirm: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        onToggleTerms: (val) {
                          setState(() => _acceptTerms = val ?? false);
                        },
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),

                // ── Boton Siguiente/Finalizar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    12,
                    AppSpacing.screenPaddingH,
                    20,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: _isCurrentStepValid,
                    label: _currentStep == _totalSteps - 1
                        ? 'Finalizar registro'
                        : 'Ir al siguiente paso',
                    child: _GradientPillButton(
                      label: _currentStep == _totalSteps - 1
                          ? 'Finalizar'
                          : 'Siguiente',
                      onTap: _isCurrentStepValid ? _nextStep : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Progress Bar de pasos
// ─────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted || isCurrent
                  ? const Color(0xFFEE7070)
                  : AppColors.neutral200,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 1: Nombre, Apellido, Distrito
// ─────────────────────────────────────────────────────────
class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo({
    required this.nameController,
    required this.lastNameController,
    required this.selectedDistrict,
    required this.onDistrictSelected,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final District? selectedDistrict;
  final ValueChanged<District> onDistrictSelected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final showNameError =
        nameController.text.isNotEmpty && nameController.text.trim().length < 3;
    final showLastNameError =
        lastNameController.text.isNotEmpty &&
        lastNameController.text.trim().length < 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nombre ──
          _FieldLabel(text: 'Nombre'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese su nombre',
            child: _FormField(
              controller: nameController,
              hint: 'Ej: Juan',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              hasError: showNameError,
              onChanged: (_) => onChanged(),
            ),
          ),
          _FieldErrorMessage(
            visible: showNameError,
            message: 'El nombre debe tener mínimo 3 caracteres',
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Apellido ──
          _FieldLabel(text: 'Apellido'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese su apellido',
            child: _FormField(
              controller: lastNameController,
              hint: 'Ej: González',
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              hasError: showLastNameError,
              onChanged: (_) => onChanged(),
            ),
          ),
          _FieldErrorMessage(
            visible: showLastNameError,
            message: 'El apellido debe tener mínimo 3 caracteres',
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Distrito ──
          _FieldLabel(text: '¿Qué distrito vivís?'),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: selectedDistrict != null
                ? 'Distrito seleccionado: ${selectedDistrict!.name}. Toque para cambiar'
                : 'Seleccionar distrito',
            child: GestureDetector(
              onTap: () async {
                FocusScope.of(context).unfocus();
                final result = await Navigator.of(context).push<District>(
                  MaterialPageRoute(
                    builder: (_) => DistrictSelectorScreen(
                      currentSelection: selectedDistrict,
                    ),
                  ),
                );
                if (result != null) {
                  onDistrictSelected(result);
                }
              },
              child: Container(
                width: double.infinity,
                height: AppSpacing.inputHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: selectedDistrict != null
                        ? AppColors.neutral400
                        : AppColors.neutral300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDistrict?.name ?? 'Seleccione su distrito',
                      style: AppTypography.bodyMedium.copyWith(
                        color: selectedDistrict != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 2: Telefono y Correo
// ─────────────────────────────────────────────────────────
class _Step2Contact extends StatelessWidget {
  const _Step2Contact({
    required this.phoneController,
    required this.emailController,
    required this.onChanged,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final phoneError = _peruPhoneError(phoneController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titulo ──
          Semantics(
            header: true,
            child: Text(
              'Vamos a crear tu cuenta',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Con estos datos podrás ingresar a tu cuenta.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Telefono ──
          _FieldLabel(text: 'Número de teléfono'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Número de teléfono peruano, 9 dígitos',
            child: _PhoneFieldPeru(
              controller: phoneController,
              hasError: phoneError != null,
              onChanged: (_) => onChanged(),
            ),
          ),
          _FieldErrorMessage(
            visible: phoneError != null,
            message: phoneError ?? '',
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Correo ──
          Semantics(
            label: 'Correo electrónico obligatorio',
            child: _FieldLabel(text: 'Correo electrónico'),
          ),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese correo electrónico',
            child: _FormField(
              controller: emailController,
              hint: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step 3: Contrasena y Terminos
// ─────────────────────────────────────────────────────────
class _Step3Password extends StatelessWidget {
  const _Step3Password({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.acceptTerms,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onToggleTerms,
    required this.onChanged,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool acceptTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final ValueChanged<bool?> onToggleTerms;
  final VoidCallback onChanged;

  bool get _showMinLengthError =>
      passwordController.text.isNotEmpty && passwordController.text.length < 6;

  bool get _showMismatchError =>
      confirmPasswordController.text.isNotEmpty &&
      passwordController.text != confirmPasswordController.text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titulo ──
          Semantics(
            header: true,
            child: Text(
              'Datos de acceso',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Con estos datos podrás ingresar a tu cuenta.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Contrasena label + icono ayuda ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel(text: 'Contraseña'),
              Semantics(
                button: true,
                label: 'Ayuda sobre requisitos de contraseña',
                child: GestureDetector(
                  onTap: () => _showPasswordHelp(context),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Campo contrasena ──
          Semantics(
            textField: true,
            label: 'Ingrese su contraseña',
            child: _PasswordFormField(
              controller: passwordController,
              hint: 'Escribe una clave que recordarás',
              obscure: obscurePassword,
              onToggle: onTogglePassword,
              onChanged: (_) => onChanged(),
              hasError: _showMinLengthError,
            ),
          ),

          // ── Mensaje validacion minimo 6 caracteres ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showMinLengthError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mínimo 6 caracteres',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Campo confirmar ──
          Semantics(
            textField: true,
            label: 'Repita su contraseña',
            child: _PasswordFormField(
              controller: confirmPasswordController,
              hint: 'Repetir la nueva clave',
              obscure: obscureConfirm,
              onToggle: onToggleConfirm,
              onChanged: (_) => onChanged(),
              hasError: _showMismatchError,
            ),
          ),

          // ── Mensaje si no coinciden ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showMismatchError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Las contraseñas no coinciden',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Terminos y condiciones (enlaces abren WebView) ──
          TermsAcceptanceCheckbox(
            value: acceptTerms,
            onChanged: onToggleTerms,
          ),
        ],
      ),
    );
  }

  void _showPasswordHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'Requisitos de contraseña',
          style: AppTypography.headingSmall,
        ),
        content: Text(
          '- Mínimo 6 caracteres\n- Se recomienda usar letras y números\n- Evitá datos personales',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Componentes reutilizables internos
// ─────────────────────────────────────────────────────────

/// Label de campo con estilo consistente
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.secondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Campo de formulario generico mejorado
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.neutral300,
        width: hasError ? 1.5 : 1,
      ),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: AppTypography.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        counterText: '',
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
    );
  }
}

/// Mensaje de error compacto para validaciones de campos.
class _FieldErrorMessage extends StatelessWidget {
  const _FieldErrorMessage({required this.visible, required this.message});

  final bool visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Campo de contrasena con toggle visibilidad y estado de error
class _PasswordFormField extends StatelessWidget {
  const _PasswordFormField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.neutral300,
        width: hasError ? 1.5 : 1,
      ),
    );

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyMedium,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        suffixIcon: Semantics(
          button: true,
          label: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          child: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.neutral500,
              size: 22,
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
    );
  }
}

/// Campo de telefono con bandera Peru +51, limitado a 9 digitos
class _PhoneFieldPeru extends StatelessWidget {
  const _PhoneFieldPeru({
    required this.controller,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.neutral300,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ── Bandera + codigo ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bandera de Peru (emoji)
                const Text(
                  '\u{1F1F5}\u{1F1EA}',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  '+ 51',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // ── Separador ──
          Container(width: 1, height: 28, color: AppColors.neutral300),
          // ── Campo numero (max 9 digitos + 2 espacios = 11 chars) ──
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyMedium,
              onChanged: onChanged,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                _PhoneSpaceFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '999 999 999',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                counterText: '', // Ocultar contador
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatea el numero de telefono como xxx xxx xxx mientras se escribe.
class _PhoneSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo digitos
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 9) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Boton pill con gradiente naranja estilo referencia
class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [Color(0xFFEE7070), Color(0xFFE85555)]
                : const [Color(0xFFCCCCCC), Color(0xFFBBBBBB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFEE7070).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // ── Decoraciones curvas en esquinas ──
            if (isEnabled) ...[
              Positioned(left: 16, top: 14, child: _CurlDecor(isLeft: true)),
              Positioned(
                right: 16,
                bottom: 14,
                child: _CurlDecor(isLeft: false),
              ),
            ],
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

/// Decoraciones tipo curl en los bordes del boton
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
