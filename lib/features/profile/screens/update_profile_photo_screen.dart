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

/// "Actualizar foto de perfil": reglas + selector (galería/cámara) y guardado.
/// Sube el avatar al storage y actualiza el perfil; refresca [AuthStore].
class UpdateProfilePhotoScreen extends StatefulWidget {
  const UpdateProfilePhotoScreen({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  State<UpdateProfilePhotoScreen> createState() =>
      _UpdateProfilePhotoScreenState();
}

class _UpdateProfilePhotoScreenState extends State<UpdateProfilePhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final AuthService _auth = AuthService();

  String? _localPath; // nueva foto elegida (aún no subida)
  bool _saving = false;

  String? get _currentUrl => widget.profile?['avatar_url'] as String?;

  Future<void> _pick(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (img != null && mounted) setState(() => _localPath = img.path);
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          message: 'No se pudo acceder a las fotos.',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_localPath == null) {
      showAppToast(
        context,
        message: 'Elegí una foto primero.',
        type: ToastType.info,
      );
      return;
    }
    setState(() => _saving = true);

    final url = await _auth.uploadAvatar(_localPath!);
    if (url == null) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        message: 'No se pudo subir la foto. Intentá de nuevo.',
        type: ToastType.error,
      );
      return;
    }

    final p = widget.profile;
    final res = await _auth.updateProfile(
      firstName: (p?['first_name'] as String?) ?? '',
      lastName: p?['last_name'] as String?,
      phone: p?['phone'] as String?,
      avatarUrl: url,
    );

    if (!mounted) return;

    if (res.success) {
      // Refresca el perfil en memoria para que el avatar se vea al instante.
      final fresh = await _auth.getMyTechnicianProfile();
      AuthStore.instance.setAuthenticated(fresh);
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        message: 'Foto de perfil actualizada.',
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      showAppToast(
        context,
        message: res.message ?? 'No se pudo actualizar la foto.',
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
            'Actualizar foto de perfil',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.md,
              AppSpacing.screenPaddingH,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Reglas ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reglas y consideraciones importantes:',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _bullet(
                        'Usa una foto donde se te vea bien, sin lentes oscuros.',
                      ),
                      _bullet('Que no sea una foto grupal.'),
                      _bullet(
                        'Puede ser una foto de medio cuerpo hacia arriba, de '
                        'manera que tu rostro se vea claramente.',
                      ),
                      _bullet('También puede ser el logo de tu empresa.'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'En cualquiera de los casos, la foto no debe contener '
                        'datos de contacto como números de celular, correos '
                        'electrónicos, etc.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Foto tuya o logo de tu negocio',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Zona de foto ──
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF1F7),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Preview(localPath: _localPath, currentUrl: _currentUrl),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PickButton(
                            icon: Icons.photo_library_outlined,
                            onTap: () => _pick(ImageSource.gallery),
                          ),
                          const SizedBox(width: 20),
                          _PickButton(
                            icon: Icons.photo_camera_outlined,
                            onTap: () => _pick(ImageSource.camera),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                GradientPillButton(
                  label: 'Guardar cambios',
                  isLoading: _saving,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 8),
            child: CircleAvatar(
              radius: 2.5,
              backgroundColor: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.localPath, required this.currentUrl});

  final String? localPath;
  final String? currentUrl;

  @override
  Widget build(BuildContext context) {
    final size = 100.0;
    Widget child;
    if (localPath != null) {
      child = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (currentUrl != null && currentUrl!.isNotEmpty) {
      child = Image.network(
        currentUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PlaceholderIcon(),
      );
    } else {
      child = const _PlaceholderIcon();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neutral200,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 44,
        color: AppColors.neutral500,
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 24, color: AppColors.textSecondary),
      ),
    );
  }
}
