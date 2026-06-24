import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/auth_store.dart';

/// Edición del perfil del cliente: foto, nombre, apellido y teléfono.
/// El email es de solo lectura (lo gestiona el flujo de auth). Guarda vía
/// [AuthService.updateProfile], refresca [AuthStore] y devuelve `true`.
class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditClientProfileScreen> createState() =>
      _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  final AuthService _auth = AuthService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;

  late final String? _currentAvatarUrl;
  late final String _email;
  XFile? _pickedPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstName = TextEditingController(text: p['first_name'] as String? ?? '');
    _lastName = TextEditingController(text: p['last_name'] as String? ?? '');
    _phone = TextEditingController(text: p['phone'] as String? ?? '');
    _currentAvatarUrl = p['avatar_url'] as String?;
    _email = p['email'] as String? ?? '';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (shot != null && mounted) setState(() => _pickedPhoto = shot);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'No se pudo acceder a las fotos.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final firstName = _firstName.text.trim();
    if (firstName.isEmpty) {
      showAppToast(
        context,
        message: 'El nombre es obligatorio.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _saving = true);

    // Subir la foto nueva (si se eligió una) antes de guardar el perfil.
    String? avatarUrl;
    if (_pickedPhoto != null) {
      avatarUrl = await _auth.uploadAvatar(_pickedPhoto!.path);
      if (avatarUrl == null) {
        if (!mounted) return;
        setState(() => _saving = false);
        showAppToast(
          context,
          message: 'No se pudo subir la foto. Intenta de nuevo.',
          type: ToastType.error,
        );
        return;
      }
    }

    final result = await _auth.updateProfile(
      firstName: firstName,
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      avatarUrl: avatarUrl,
    );
    if (!mounted) return;

    if (result.success) {
      // Refrescar el perfil en memoria para que toda la UI lo refleje.
      final fresh = await _auth.getMyTechnicianProfile();
      if (fresh != null) AuthStore.instance.setAuthenticated(fresh);
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        message: result.message ?? 'Perfil actualizado.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      showAppToast(
        context,
        message: result.message ?? 'No se pudo actualizar el perfil.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Editar perfil',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  AppSpacing.xl,
                  AppSpacing.screenPaddingH,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ──
                    Center(
                      child: _AvatarEditor(
                        pickedPhoto: _pickedPhoto,
                        currentUrl: _currentAvatarUrl,
                        onTap: _pickPhoto,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _Label('Nombre'),
                    const SizedBox(height: AppSpacing.xs),
                    _Input(controller: _firstName, hint: 'Tu nombre'),
                    const SizedBox(height: AppSpacing.lg),

                    _Label('Apellido'),
                    const SizedBox(height: AppSpacing.xs),
                    _Input(controller: _lastName, hint: 'Tu apellido'),
                    const SizedBox(height: AppSpacing.lg),

                    _Label('Teléfono', optional: true),
                    const SizedBox(height: AppSpacing.xs),
                    _Input(
                      controller: _phone,
                      hint: 'Ej: 987 654 321',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Email (no editable) ──
                    _Label('Correo'),
                    const SizedBox(height: AppSpacing.xs),
                    _ReadOnlyField(value: _email.isEmpty ? '—' : _email),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.md,
                AppSpacing.screenPaddingH,
                AppSpacing.md + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.backgroundPrimary,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: GradientPillButton(
                label: 'Guardar cambios',
                isLoading: _saving,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular editable con badge de cámara.
class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.pickedPhoto,
    required this.currentUrl,
    required this.onTap,
  });

  final XFile? pickedPhoto;
  final String? currentUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (pickedPhoto != null) {
      image = FileImage(File(pickedPhoto!.path));
    } else if (currentUrl != null && currentUrl!.isNotEmpty) {
      image = NetworkImage(currentUrl!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral200,
              border: Border.all(color: AppColors.primary, width: 3),
              image: image != null
                  ? DecorationImage(image: image, fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: AppColors.neutral400,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundPrimary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label, {this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (optional)
            TextSpan(
              text: ' (opcional)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, size: 18, color: AppColors.neutral400),
        ],
      ),
    );
  }
}
