import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import 'district_selector_screen.dart';

/// Registro de prestadores de servicio - Flujo de 5 pasos:
/// Step 1: Nombre, Apellido, DNI, Distrito
/// Step 2: Foto (opcional), Presentación/Biografía
/// Step 3: Teléfono, Correo (opcional), Contraseña
/// Step 4: Categorías de servicio (max 2)
/// Step 5: Aceptar términos y finalizar
class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 5;

  // ── Step 1 controllers ──
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  String? _selectedDistrict;

  // ── Step 2 controllers ──
  final _bioController = TextEditingController();
  // Photo path would be stored here after picking
  String? _photoPath;

  // ── Step 3 controllers ──
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Step 4 controllers ──
  final List<String> _selectedCategories = [];

  // ── Step 5 controllers ──
  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _bioController.dispose();
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
            _dniController.text.trim().length == 8 &&
            _selectedDistrict != null;
      case 1:
        return _bioController.text.trim().length >= 20;
      case 2:
        return _emailController.text.trim().isNotEmpty &&
            _emailController.text.contains('@') &&
            _phoneController.text.replaceAll(' ', '').length == 9 &&
            _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text;
      case 3:
        return _selectedCategories.isNotEmpty;
      case 4:
        return _acceptTerms;
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
        'dni': _dniController.text.trim(),
        'district': _selectedDistrict,
        'photo': _photoPath,
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.replaceAll(' ', '').trim(),
        'password': _passwordController.text,
        'categories': _selectedCategories,
        'role': 'provider',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
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
                          'Registro de trabajadores',
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
                      _Step1BasicData(
                        nameController: _nameController,
                        lastNameController: _lastNameController,
                        dniController: _dniController,
                        selectedDistrict: _selectedDistrict,
                        onDistrictSelected: (district) {
                          setState(() => _selectedDistrict = district);
                        },
                        onChanged: () => setState(() {}),
                      ),
                      _Step2Presentation(
                        bioController: _bioController,
                        photoPath: _photoPath,
                        onPhotoSelected: (path) {
                          setState(() => _photoPath = path);
                        },
                        onChanged: () => setState(() {}),
                      ),
                      _Step3Contact(
                        emailController: _emailController,
                        phoneController: _phoneController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        onTogglePassword: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        onToggleConfirm: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        onChanged: () => setState(() {}),
                      ),
                      _Step4Categories(
                        selectedCategories: _selectedCategories,
                        onCategoryToggled: (category) {
                          setState(() {
                            if (_selectedCategories.contains(category)) {
                              _selectedCategories.remove(category);
                            } else {
                              if (_selectedCategories.length >= 2) {
                                showAppToast(
                                  context,
                                  message: 'Máximo 2 categorías permitidas',
                                  type: ToastType.warning,
                                  duration: const Duration(seconds: 2),
                                );
                              } else {
                                _selectedCategories.add(category);
                              }
                            }
                          });
                        },
                      ),
                      _Step5Terms(
                        acceptTerms: _acceptTerms,
                        onToggleTerms: (val) {
                          setState(() => _acceptTerms = val ?? false);
                        },
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
// Step 1: Tus datos básicos
// ─────────────────────────────────────────────────────────
class _Step1BasicData extends StatelessWidget {
  const _Step1BasicData({
    required this.nameController,
    required this.lastNameController,
    required this.dniController,
    required this.selectedDistrict,
    required this.onDistrictSelected,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController dniController;
  final String? selectedDistrict;
  final ValueChanged<String> onDistrictSelected;
  final VoidCallback onChanged;

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
              'Tus datos básicos',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Nombre ──
          _FieldLabel(text: 'Tu nombre'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese su nombre',
            child: _FormField(
              controller: nameController,
              hint: 'Ej: Juan',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged(),
              hasError:
                  nameController.text.isNotEmpty &&
                  nameController.text.trim().length < 3,
            ),
          ),
          if (nameController.text.isNotEmpty &&
              nameController.text.trim().length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Mínimo 3 caracteres',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // ── Apellido ──
          _FieldLabel(text: 'Tu apellido'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese su apellido',
            child: _FormField(
              controller: lastNameController,
              hint: 'Ej: González',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged(),
              hasError:
                  lastNameController.text.isNotEmpty &&
                  lastNameController.text.trim().length < 3,
            ),
          ),
          if (lastNameController.text.isNotEmpty &&
              lastNameController.text.trim().length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Mínimo 3 caracteres',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // ── DNI ──
          Row(
            children: [
              _FieldLabel(text: 'N° de DNI'),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Ayuda sobre número de DNI',
                child: GestureDetector(
                  onTap: () => _showDniHelp(context),
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
          Semantics(
            textField: true,
            label: 'Ingrese su número de DNI, 8 dígitos',
            child: _FormField(
              controller: dniController,
              hint: 'Ej: 12345678',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (_) => onChanged(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Distrito ──
          _FieldLabel(text: '¿Qué distrito vivís?'),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: selectedDistrict != null
                ? 'Distrito seleccionado: $selectedDistrict. Toque para cambiar'
                : 'Seleccionar distrito',
            child: GestureDetector(
              onTap: () async {
                FocusScope.of(context).unfocus();
                final result = await Navigator.of(context).push<String>(
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
                      selectedDistrict ?? 'Seleccione su distrito',
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

  void _showDniHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Número de DNI', style: AppTypography.headingSmall),
        content: Text(
          'Ingresá tu Documento Nacional de Identidad.\nDebe tener exactamente 8 dígitos numéricos.',
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
// Step 2: Presentación
// ─────────────────────────────────────────────────────────
class _Step2Presentation extends StatelessWidget {
  const _Step2Presentation({
    required this.bioController,
    required this.photoPath,
    required this.onPhotoSelected,
    required this.onChanged,
  });

  final TextEditingController bioController;
  final String? photoPath;
  final ValueChanged<String?> onPhotoSelected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasBioError =
        bioController.text.isNotEmpty && bioController.text.trim().length < 20;
    final bioBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: hasBioError ? AppColors.error : AppColors.neutral300,
        width: hasBioError ? 1.5 : 1,
      ),
    );

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
              'Presentación',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Foto label ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Una foto tuya o Logo (opcional)',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Ayuda sobre foto de perfil',
                child: GestureDetector(
                  onTap: () => _showPhotoHelp(context),
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

          // ── Photo placeholder / preview ──
          Semantics(
            label: 'Zona para subir foto de perfil o logo',
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Preview circular si hay foto ──
                  if (photoPath != null && photoPath!.isNotEmpty)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: DecorationImage(
                          image: FileImage(File(photoPath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),

                  const SizedBox(height: 16),

                  // ── Botones galería/cámara ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            onPhotoSelected(image.path);
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Camera button
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            onPhotoSelected(image.path);
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Presentación label ──
          Row(
            children: [
              _FieldLabel(text: 'Presentación'),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Ayuda sobre presentación',
                child: GestureDetector(
                  onTap: () => _showBioHelp(context),
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

          // ── Bio text field ──
          Semantics(
            textField: true,
            label: 'Ingrese su presentación o biografía',
            child: TextField(
              controller: bioController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText:
                    'Breve biografía como prestador de servicio.\nTus servicios y habilidades',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.neutral100,
                border: bioBorder,
                enabledBorder: bioBorder,
                focusedBorder: bioBorder,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Validación bio min 20 chars
          if (bioController.text.isNotEmpty &&
              bioController.text.trim().length < 20)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'La presentación debe tener al menos 20 caracteres',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhotoHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Foto de perfil', style: AppTypography.headingSmall),
        content: Text(
          'Una foto tuya o el logo de tu negocio ayuda a generar confianza con los clientes. Este campo es opcional.',
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

  void _showBioHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Presentación', style: AppTypography.headingSmall),
        content: Text(
          'Escribe una breve descripción de quién eres y qué servicios ofreces. Esto será visible para tus clientes potenciales.',
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
// Step 3: Datos de contacto y acceso
// ─────────────────────────────────────────────────────────
class _Step3Contact extends StatelessWidget {
  const _Step3Contact({
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onChanged,
  });

  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onChanged;

  bool get _showMinLengthError =>
      passwordController.text.isNotEmpty && passwordController.text.length < 6;

  bool get _showMismatchError =>
      confirmPasswordController.text.isNotEmpty &&
      passwordController.text != confirmPasswordController.text;

  bool get _showEmailError =>
      emailController.text.isNotEmpty && !emailController.text.contains('@');

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

          // ── Correo electrónico (obligatorio - credencial de login) ──
          _FieldLabel(text: 'Correo electrónico'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Ingrese su correo electrónico para iniciar sesión',
            child: _FormField(
              controller: emailController,
              hint: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged(),
              hasError: _showEmailError,
            ),
          ),

          // ── Mensaje validacion email ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showEmailError
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
                          'Ingresa un correo válido',
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

          // ── Telefono (dato de contacto, no para login) ──
          _FieldLabel(text: 'Número de teléfono'),
          const SizedBox(height: 10),
          Semantics(
            textField: true,
            label: 'Número de teléfono de contacto, 9 dígitos',
            child: _PhoneFieldPeru(
              controller: phoneController,
              onChanged: (_) => onChanged(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

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
// Step 4: Categorías de servicio
// ─────────────────────────────────────────────────────────
class _Step4Categories extends StatelessWidget {
  const _Step4Categories({
    required this.selectedCategories,
    required this.onCategoryToggled,
  });

  final List<String> selectedCategories;
  final ValueChanged<String> onCategoryToggled;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'Albañil', emoji: '🧱'),
    _CategoryItem(name: 'Electricista', emoji: '⚡'),
    _CategoryItem(name: 'Pintura', emoji: '🎨'),
    _CategoryItem(name: 'Plomero', emoji: '🔧'),
    _CategoryItem(name: 'Aire Acondicionado', emoji: '❄️'),
    _CategoryItem(name: 'Piscinas', emoji: '🏊'),
    _CategoryItem(name: 'Jardinería', emoji: '🌿'),
    _CategoryItem(name: 'Contratista/Construcción', emoji: '🏗️'),
    _CategoryItem(name: 'Flete/Mudanza', emoji: '🚚'),
    _CategoryItem(name: 'Seguridad', emoji: '🔒'),
    _CategoryItem(name: 'Azulejista', emoji: '🧩'),
    _CategoryItem(name: 'Pisos y baldosas', emoji: '🪨'),
    _CategoryItem(name: 'Diseño de Interiores', emoji: '🛋️'),
    _CategoryItem(name: 'Iluminación', emoji: '💡'),
    _CategoryItem(name: 'Herrero', emoji: '⚒️'),
  ];

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
              '¿Qué tipo de trabajos o servicios realizas?',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Subtitulo ──
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selecciona una o varias categorías',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Ayuda sobre categorías',
                child: GestureDetector(
                  onTap: () => _showCategoryHelp(context),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Grid de categorías ──
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: _categories.map((category) {
              final isSelected = selectedCategories.contains(category.name);
              final isMaxReached = selectedCategories.length >= 2;
              final isDisabled = isMaxReached && !isSelected;
              return Semantics(
                button: true,
                selected: isSelected,
                enabled: !isDisabled,
                label:
                    '${category.name}${isSelected ? ", seleccionado" : ""}${isDisabled ? ", no disponible" : ""}',
                child: GestureDetector(
                  onTap: () => onCategoryToggled(category.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF0ED)
                          : isDisabled
                          ? const Color(0xFFF0F4F8).withValues(alpha: 0.5)
                          : const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEE7070)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isDisabled ? 0.4 : 1.0,
                      child: Stack(
                        children: [
                          // ── Check overlay ──
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEE7070),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // ── Content ──
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isSelected
                                          ? const Color(0xFFEE7070)
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showCategoryHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'Categorías de servicio',
          style: AppTypography.headingSmall,
        ),
        content: Text(
          'Selecciona hasta 2 categorías que mejor describan los servicios que ofreces. Esto ayudará a los clientes a encontrarte.',
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

/// Modelo de datos para categoría
class _CategoryItem {
  const _CategoryItem({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

// ─────────────────────────────────────────────────────────
// Step 5: Términos y finalizar
// ─────────────────────────────────────────────────────────
class _Step5Terms extends StatelessWidget {
  const _Step5Terms({required this.acceptTerms, required this.onToggleTerms});

  final bool acceptTerms;
  final ValueChanged<bool?> onToggleTerms;

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
              'Excelente, ya estamos listos para enviar tu formulario de registro.',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Subtitulo ──
          Text(
            'A continuación es necesario aceptar nuestros términos de uso.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // ── Terminos y condiciones ──
          Semantics(
            toggled: acceptTerms,
            label: 'Aceptar términos y condiciones',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: acceptTerms,
                    onChanged: onToggleTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: AppColors.neutral400,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggleTerms(!acceptTerms),
                    child: RichText(
                      text: TextSpan(
                        text: 'Acepto los ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: 'términos y condiciones de uso',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'política de privacidad de datos',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    this.maxLength,
    this.inputFormatters,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
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
      maxLength: maxLength,
      inputFormatters: inputFormatters,
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
  const _PhoneFieldPeru({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral300),
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
                counterText: '',
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

/// Boton pill con gradiente rojo suave estilo referencia
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
