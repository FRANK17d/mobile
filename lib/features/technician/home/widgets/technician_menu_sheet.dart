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
import '../../account/screens/credits_screen.dart';
import '../../account/screens/toke_pro_screen.dart';

/// Abre el menú del técnico como vista full-screen.
void showTechnicianMenuSheet(
  BuildContext context, {
  Map<String, dynamic>? profileData,
}) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _TechnicianMenuFullScreen(profileData: profileData),
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

class _TechnicianMenuFullScreen extends StatelessWidget {
  const _TechnicianMenuFullScreen({this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final avatarUrl = profileData?['avatar_url'] as String?;
    final firstName = profileData?['first_name'] as String? ?? '';
    final lastName = profileData?['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Color(0xFF1D2939),
                    ),
                  ),
                  // CTA pill button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: navegar a pedir servicio
                    },
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

            // ── Profile row ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
              ),
              child: Row(
                children: [
                  // Avatar
                  ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.neutral200,
                                child: const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.neutral200,
                                child: const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.neutral200,
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Full name
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

            // ── Menu items (scrollable) ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  _TechMenuTile(
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    onTap: () {
                      Navigator.of(context).pop();
                      TechnicianShell.goToTab(TechnicianShell.tabHome);
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.business_center_outlined,
                    label: 'Mi panel profesional',
                    onTap: () {
                      Navigator.of(context).pop();
                      TechnicianShell.goToTab(TechnicianShell.tabPanel);
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.list_alt_rounded,
                    label: 'Mis pedidos',
                    onTap: () {
                      showAppToast(context, message: 'Disponible pronto');
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Descubrir',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6B7280),
                      size: 22,
                    ),
                    onTap: () {
                      showAppToast(context, message: 'Disponible pronto');
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.settings_outlined,
                    label: 'Ajustes',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF6B7280),
                      size: 22,
                    ),
                    onTap: () {
                      showAppToast(context, message: 'Disponible pronto');
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.share_outlined,
                    label: 'Compartir',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(text: AppStrings.shareMessage),
                      );
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Beneficios de ser #TokePro',
                    iconColor: AppColors.primaryDark,
                    labelColor: AppColors.primaryDark,
                    onTap: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TokeProScreen(),
                        ),
                      );
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.monetization_on_outlined,
                    label: 'Comprar créditos',
                    onTap: () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreditsScreen(),
                        ),
                      );
                    },
                  ),
                  _TechMenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Cerrar sesión',
                    onTap: () => _handleLogout(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
    );
  }

  /// Muestra la vista de cierre de sesión (logo animado), cierra la sesión y
  /// vuelve al home como no autenticado. La propia vista limpia el menú del
  /// stack imperativo antes de navegar.
  void _handleLogout(BuildContext context) {
    showLogoutTransition(context);
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
