import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/services/auth_store.dart';
import '../../client/discover/screens/discover_screen.dart';
import '../../client/explore/screens/explore_screen.dart';
import '../../client/home/widgets/client_menu_sheet.dart';
import '../../client/how_it_works/screens/how_it_works_screen.dart';
import '../../client/notifications/screens/client_notifications_screen.dart';
import '../../client/orders/screens/my_requests_screen.dart';
import '../../client/request_service/screens/request_service_wizard_screen.dart';
import 'update_profile_photo_screen.dart';

/// Pantalla de "Cuenta" del cliente autenticado.
///
/// Cabecera con avatar (editable) + acceso a "Ajustes" (sub-menú), lista de
/// accesos y una tarjeta promocional. Reactiva a [AuthStore].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSnapshot>(
      valueListenable: AuthStore.instance.notifier,
      builder: (context, auth, _) {
        final profile = auth.profile;
        final firstName = profile?['first_name'] as String? ?? '';
        final lastName = profile?['last_name'] as String? ?? '';
        final email = profile?['email'] as String? ?? '';
        final avatarUrl = profile?['avatar_url'] as String?;
        final fullName = [
          firstName,
          lastName,
        ].where((s) => s.trim().isNotEmpty).join(' ').trim();
        final displayName = fullName.isNotEmpty
            ? fullName
            : (email.isNotEmpty ? email.split('@').first : 'Mi cuenta');

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header gradiente con campana + menú ──
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 20,
                      right: 20,
                      bottom: 40,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF3DCC6), Color(0xFFF8ECE0)],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _CircleIconButton(
                          icon: Icons.notifications_outlined,
                          onTap: () => _openNotifications(context),
                        ),
                        const SizedBox(width: 10),
                        _CircleIconButton(
                          icon: Icons.menu_rounded,
                          onTap: () => showClientMenuSheet(
                            context,
                            profileData: profile,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tarjeta blanca ──
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundPrimary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar + botón Ajustes
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Avatar(
                                avatarUrl: avatarUrl,
                                onEdit: () => _openPhoto(context, profile),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _AjustesButton(
                                  onTap: () => showClientMenuSheet(
                                    context,
                                    profileData: profile,
                                    initialSettings: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _RolePill(),

                          const SizedBox(height: 28),

                          // ── Accesos ──
                          _LinkItem(
                            icon: Icons.format_list_bulleted_rounded,
                            label: 'Mis pedidos',
                            showChevron: false,
                            onTap: () =>
                                _push(context, const MyRequestsScreen()),
                          ),
                          _LinkItem(
                            icon: Icons.info_outline_rounded,
                            label: 'Descubrir',
                            onTap: () => _push(context, const DiscoverScreen()),
                          ),
                          _LinkItem(
                            icon: Icons.help_outline_rounded,
                            label: 'Como funciona',
                            onTap: () =>
                                _push(context, const HowItWorksScreen()),
                          ),
                          _LinkItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Ganar dinero',
                            onTap: () => showAppToast(
                              context,
                              message: 'Próximamente',
                              type: ToastType.info,
                            ),
                          ),
                          _LinkItem(
                            icon: Icons.layers_outlined,
                            label: 'Explorar servicios',
                            onTap: () => _push(context, const ExploreScreen()),
                          ),

                          const SizedBox(height: 24),

                          // ── Promo (paso_4) ──
                          _TrustPromoCard(
                            onPedir: () => _push(
                              context,
                              const RequestServiceWizardScreen(),
                            ),
                            onComoFunciona: () =>
                                _push(context, const HowItWorksScreen()),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const ClientNotificationsScreen(),
      ),
    );
  }

  void _openPhoto(BuildContext context, Map<String, dynamic>? profile) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => UpdateProfilePhotoScreen(profile: profile),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1D2939)),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.onEdit});

  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3C4657),
              border: Border.all(color: Colors.white, width: 3),
              image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (avatarUrl == null || avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 46, color: Colors.white)
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 17,
                  color: Color(0xFF1D2939),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AjustesButton extends StatelessWidget {
  const _AjustesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          'Ajustes',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          Text(
            'Cliente',
            style: AppTypography.labelLarge.copyWith(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  const _LinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF374151)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleLarge.copyWith(
                  color: const Color(0xFF1D2939),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA3B2),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta promocional con la imagen paso_4 + beneficios + CTAs.
class _TrustPromoCard extends StatelessWidget {
  const _TrustPromoCard({required this.onPedir, required this.onComoFunciona});

  final VoidCallback onPedir;
  final VoidCallback onComoFunciona;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AppImages.hiwTrust,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(height: 8),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buscá soluciones con los mejores',
                  style: AppTypography.displaySmall.copyWith(
                    color: const Color(0xFF162033),
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _Benefit(
                  icon: Icons.verified_outlined,
                  title: 'Postulantes verificados',
                  subtitle: 'Vos elegís con quién trabajar.',
                ),
                const _Benefit(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Excelencia',
                  subtitle: 'Insignia que garantiza calidad.',
                ),
                const _Benefit(
                  icon: Icons.shield_outlined,
                  title: 'Confianza',
                  subtitle: 'Insignia otorgada a quienes son de confianza.',
                ),
                const _Benefit(
                  icon: Icons.star_outline_rounded,
                  title: 'Valoraciones reales',
                  subtitle: 'Comentarios de clientes reales.',
                ),
                const SizedBox(height: AppSpacing.lg),
                GradientPillButton(label: 'Pedir servicio', onTap: onPedir),
                const SizedBox(height: AppSpacing.sm),
                _OutlinePill(label: '¿Cómo funciona?', onTap: onComoFunciona),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          label,
          style: AppTypography.buttonLarge.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
