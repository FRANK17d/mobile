import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/logout_transition_screen.dart';
import '../../../profile/screens/biometric_access_screen.dart';
import '../../../profile/screens/change_password_screen.dart';
import '../../../profile/screens/delete_account_screen.dart';
import '../../../profile/screens/edit_client_profile_screen.dart';
import '../../../profile/screens/update_profile_photo_screen.dart';
import '../../orders/screens/my_requests_screen.dart';
import '../../request_service/screens/request_service_wizard_screen.dart';

/// Abre el menú del cliente autenticado como vista full-screen.
/// Si [initialSettings] es true, arranca directamente en el sub-menú "Ajustes".
void showClientMenuSheet(
  BuildContext context, {
  Map<String, dynamic>? profileData,
  bool initialSettings = false,
}) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ClientMenuFullScreen(
            profileData: profileData,
            initialSettings: initialSettings,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

class _ClientMenuFullScreen extends StatefulWidget {
  const _ClientMenuFullScreen({this.profileData, this.initialSettings = false});

  final Map<String, dynamic>? profileData;
  final bool initialSettings;

  @override
  State<_ClientMenuFullScreen> createState() => _ClientMenuFullScreenState();
}

class _ClientMenuFullScreenState extends State<_ClientMenuFullScreen> {
  /// Cuando es true, el cuerpo muestra el sub-menú de "Ajustes".
  late bool _showSettings = widget.initialSettings;

  void _close() => Navigator.of(context).pop();

  /// Empuja una pantalla ENCIMA del menú: al retroceder vuelve al menú.
  void _push(Widget screen) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: AppStrings.shareMessage));
  }

  void _soon() => showAppToast(context, message: 'Disponible pronto');

  /// Abre el flujo de conversión a prestador de servicios. Capturamos el router
  /// antes de cerrar el menú (al cerrar, este context deja de ser válido).
  void _becomeProvider() {
    final router = GoRouter.of(context);
    _close();
    router.push('/become-provider');
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final avatarUrl = widget.profileData?['avatar_url'] as String?;
    final firstName = widget.profileData?['first_name'] as String? ?? '';
    final lastName = widget.profileData?['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        // En el sub-menú de Ajustes, el botón atrás vuelve al menú principal.
        canPop: !_showSettings,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _showSettings) {
            setState(() => _showSettings = false);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── Header: X + "Pedir servicio" ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingH,
                  topPadding + AppSpacing.md,
                  AppSpacing.screenPaddingH,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _close,
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _push(const RequestServiceWizardScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          'Pedir servicio',
                          style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Divider con gradiente ──
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Cuerpo: menú principal o ajustes ──
              Expanded(
                child: _showSettings
                    ? _buildSettings(context)
                    : _buildMain(
                        context,
                        avatarUrl: avatarUrl,
                        fullName: fullName,
                      ),
              ),

              // ── Versión ──
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.md),
                child: Center(
                  child: Text(
                    'Versión (1.0.0)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

  // ── Menú principal ──
  Widget _buildMain(
    BuildContext context, {
    required String? avatarUrl,
    required String fullName,
  }) {
    return Column(
      children: [
        // ── Fila de perfil ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const _AvatarFallback(),
                          errorWidget: (_, _, _) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  fullName.isNotEmpty ? fullName : 'Mi cuenta',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              _ClientMenuTile(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: _close,
              ),
              _ClientMenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Mis pedidos',
                onTap: () => _push(const MyRequestsScreen()),
              ),
              _ClientMenuTile(
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B7280),
                  size: 22,
                ),
                onTap: () => setState(() => _showSettings = true),
              ),
              _BecomeProviderTile(onTap: _becomeProvider),
              _ClientMenuTile(
                icon: Icons.share_outlined,
                label: 'Compartir',
                onTap: _share,
              ),
              _ClientMenuTile(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                onTap: () => showLogoutTransition(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sub-menú de Ajustes ──
  Widget _buildSettings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        // ── Pill "← Ajustes" (vuelve al menú) ──
        GestureDetector(
          onTap: () => setState(() => _showSettings = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF1D2939),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Ajustes',
                  style: AppTypography.titleLarge.copyWith(
                    color: const Color(0xFF1D2939),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        _ClientMenuTile(
          icon: Icons.photo_camera_outlined,
          label: 'Foto de perfil',
          onTap: () =>
              _push(UpdateProfilePhotoScreen(profile: widget.profileData)),
        ),
        _ClientMenuTile(
          icon: Icons.person_outline_rounded,
          label: 'Mi info personal',
          onTap: () {
            final p = widget.profileData;
            if (p == null) {
              _soon();
            } else {
              _push(EditClientProfileScreen(profile: p));
            }
          },
        ),
        _ClientMenuTile(
          icon: Icons.fingerprint_rounded,
          label: 'Acceso biométrico',
          onTap: () => _push(const BiometricAccessScreen()),
        ),
        _ClientMenuTile(
          icon: Icons.key_outlined,
          label: 'Cambiar mi contraseña',
          onTap: () => _push(const ChangePasswordScreen()),
        ),
        _ClientMenuTile(
          icon: Icons.sentiment_dissatisfied_outlined,
          label: 'Eliminar mi cuenta',
          onTap: () => _push(const DeleteAccountScreen()),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Item destacado del menú: convertirse en prestador de servicios.
class _BecomeProviderTile extends StatelessWidget {
  const _BecomeProviderTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Ser prestador de servicios',
                style: AppTypography.titleLarge.copyWith(
                  color: const Color(0xFF1D2939),
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

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral200,
      child: const Icon(Icons.person, size: 20, color: Color(0xFF6B7280)),
    );
  }
}

/// Tile individual del menú del cliente.
class _ClientMenuTile extends StatelessWidget {
  const _ClientMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF374151)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleLarge.copyWith(
                  color: const Color(0xFF1D2939),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
