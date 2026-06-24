import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/navigation/technician_shell.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/logout_transition_screen.dart';
import '../../../client/request_service/screens/request_service_wizard_screen.dart';
import '../../../profile/screens/biometric_access_screen.dart';
import '../../../profile/screens/change_password_screen.dart';
import '../../../profile/screens/delete_account_screen.dart';
import '../../../profile/screens/update_profile_photo_screen.dart';
import '../../account/screens/credits_screen.dart';
import '../../account/screens/panel_screens.dart';
import '../../account/screens/toke_pro_screen.dart';

/// Abre el menú del técnico autenticado como vista full-screen.
/// Si [initialSettings] es true, arranca directamente en el sub-menú "Ajustes".
void showTechnicianMenuSheet(
  BuildContext context, {
  Map<String, dynamic>? profileData,
  bool initialSettings = false,
}) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _TechnicianMenuFullScreen(
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

class _TechnicianMenuFullScreen extends StatefulWidget {
  const _TechnicianMenuFullScreen({
    this.profileData,
    this.initialSettings = false,
  });

  final Map<String, dynamic>? profileData;
  final bool initialSettings;

  @override
  State<_TechnicianMenuFullScreen> createState() =>
      _TechnicianMenuFullScreenState();
}

class _TechnicianMenuFullScreenState extends State<_TechnicianMenuFullScreen> {
  /// Cuando es true, el cuerpo muestra el sub-menú de "Ajustes".
  late bool _showSettings = widget.initialSettings;

  void _close() => Navigator.of(context).pop();

  /// Empuja una pantalla ENCIMA del menú: al retroceder vuelve al menú.
  void _push(Widget screen) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  /// Cierra el menú y cambia de tab en el shell del técnico.
  void _goTab(int tab) {
    _close();
    TechnicianShell.goToTab(tab);
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: AppStrings.shareMessage));
  }

  void _soon() => showAppToast(context, message: 'Disponible pronto');

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
              // ── Header: X close + "Pedir servicio" pill ──
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

              // ── Gradient divider ──
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
                    ? _buildSettings()
                    : _buildMain(avatarUrl: avatarUrl, fullName: fullName),
              ),

              // ── Bottom version text ──
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
  Widget _buildMain({required String? avatarUrl, required String fullName}) {
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
                  fullName.isNotEmpty ? fullName : 'Técnico',
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
              _TechMenuTile(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => _goTab(TechnicianShell.tabHome),
              ),
              _TechMenuTile(
                icon: Icons.business_center_outlined,
                label: 'Mi panel profesional',
                onTap: () => _goTab(TechnicianShell.tabPanel),
              ),
              _TechMenuTile(
                icon: Icons.list_alt_rounded,
                label: 'Mis pedidos',
                onTap: () => _goTab(TechnicianShell.tabOrders),
              ),
              _TechMenuTile(
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B7280),
                  size: 22,
                ),
                onTap: () => setState(() => _showSettings = true),
              ),
              _TechMenuTile(
                icon: Icons.share_outlined,
                label: 'Compartir',
                onTap: _share,
              ),
              _TechMenuTile(
                icon: Icons.workspace_premium_rounded,
                label: 'Beneficios de ser #TokePro',
                iconColor: AppColors.primaryDark,
                labelColor: AppColors.primaryDark,
                onTap: () => _push(const TokeProScreen()),
              ),
              _TechMenuTile(
                icon: Icons.monetization_on_outlined,
                label: 'Comprar créditos',
                onTap: () => _push(const CreditsScreen()),
              ),
              _TechMenuTile(
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
  Widget _buildSettings() {
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

        _TechMenuTile(
          icon: Icons.photo_camera_outlined,
          label: 'Foto de perfil',
          onTap: () =>
              _push(UpdateProfilePhotoScreen(profile: widget.profileData)),
        ),
        _TechMenuTile(
          icon: Icons.person_outline_rounded,
          label: 'Mi información',
          onTap: () {
            final p = widget.profileData;
            if (p == null) {
              _soon();
            } else {
              _push(EditProfileScreen(profileData: p));
            }
          },
        ),
        _TechMenuTile(
          icon: Icons.fingerprint_rounded,
          label: 'Acceso biométrico',
          onTap: () => _push(const BiometricAccessScreen()),
        ),
        _TechMenuTile(
          icon: Icons.key_outlined,
          label: 'Cambiar mi contraseña',
          onTap: () => _push(const ChangePasswordScreen()),
        ),
        _TechMenuTile(
          icon: Icons.sentiment_dissatisfied_outlined,
          label: 'Eliminar mi cuenta',
          onTap: () => _push(const DeleteAccountScreen()),
        ),
        const SizedBox(height: 32),
      ],
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

/// Tile individual del menú de técnico.
class _TechMenuTile extends StatelessWidget {
  const _TechMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor ?? const Color(0xFF374151)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleLarge.copyWith(
                  color: labelColor ?? const Color(0xFF1D2939),
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
