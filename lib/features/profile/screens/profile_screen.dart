import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_grid.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/district.dart';
import '../../../core/models/service_category.dart';
import 'tech_registration_screen.dart';

/// Provider to fetch registered categories for the current technician profile.
final techCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userProfile?.id;
  if (userId == null) return [];
  
  final ids = await DatabaseService().fetchTechnicianCategoryIds(userId);
  final allCats = await ref.read(categoriesProvider.future);
  
  return allCats.where((cat) => ids.contains(cat.id)).toList();
});

/// Pantalla de perfil del usuario.
/// Muestra datos reales del usuario y permite alternar a modo Técnico si está registrado.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.isTechnician = false});

  final bool isTechnician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakpoint = Breakpoint.of(context);
    final authState = ref.watch(authProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final techCategoriesAsync = ref.watch(techCategoriesProvider);
    
    // Fallback if not authenticated yet (during logout or transition)
    if (authState.userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.userProfile!;
    final hasTechProfile = authState.technicianProfile != null;
    final techProfile = authState.technicianProfile;
    final isCurrentModeTech = authState.viewMode == AppViewMode.technician;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentContainer(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Avatar + name (dynamic)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: breakpoint.isTablet ? 100 : 80,
                      height: breakpoint.isTablet ? 100 : 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutral200,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.network(
                                user.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.person_rounded,
                                  size: breakpoint.isTablet ? 48 : 40,
                                  color: AppColors.neutral400,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: breakpoint.isTablet ? 48 : 40,
                              color: AppColors.neutral400,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.displayName,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCurrentModeTech ? 'Técnico Especialista' : 'Cliente',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (isCurrentModeTech && techProfile != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: AppColors.starFilled),
                          const SizedBox(width: 4),
                          Text(
                            techProfile.avgRating.toStringAsFixed(1),
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            ' (${techProfile.totalJobsCompleted} trabajos)',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              // Switch View Mode Banner (InDrive Style) o Estado de Verificación
              if (hasTechProfile) ...[
                if (techProfile!.verificationStatus == 'verified') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCurrentModeTech ? 'Cambiar a modo Cliente' : 'Cambiar a modo Técnico',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                isCurrentModeTech
                                    ? 'Busca técnicos y solicita servicios'
                                    : 'Gestiona tus solicitudes y trabajos',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isCurrentModeTech,
                          activeThumbColor: AppColors.primary,
                          onChanged: (_) {
                            ref.read(authProvider.notifier).toggleViewMode();
                            // GoRouter handles redirection to shell based on viewMode
                            if (isCurrentModeTech) {
                              context.go(AppRoutes.clientHome);
                            } else {
                              context.go(AppRoutes.techHome);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (techProfile.verificationStatus == 'pending') ...[
                  // Solicitud en revisión
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solicitud en Revisión',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tu registro como técnico está siendo evaluado. Te notificaremos una vez sea verificado y aprobado.',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (techProfile.verificationStatus == 'rejected') ...[
                  // Solicitud rechazada
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gpp_bad_outlined, color: AppColors.error, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registro Rechazado',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                techProfile.rejectionReason != null && techProfile.rejectionReason!.isNotEmpty
                                    ? 'Motivo: ${techProfile.rejectionReason}'
                                    : 'Tu solicitud no cumple con los requisitos mínimos de verificación.',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (user.role == 'client') ...[
                // Become a Technician Call To Action
                GestureDetector(
                  onTap: () => context.push(AppRoutes.becomeTechnician),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFD8A69)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering_outlined, color: Colors.white, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ofrece tus servicios',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Regístrate como técnico hoy',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Menu: Account / Technician config
              if (isCurrentModeTech) ...[
                _ProfileSection(
                  title: 'Mi Ficha Técnica',
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.business_center_outlined,
                      title: 'Mis Especialidades',
                      trailing: techCategoriesAsync.when(
                        data: (cats) => '${cats.length} seleccionadas',
                        loading: () => 'Cargando...',
                        error: (error, stackTrace) => 'Error',
                      ),
                      onTap: () => _showSpecialtiesDialog(context, ref),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.map_outlined,
                      title: 'Zona de Cobertura',
                      trailing: districtsAsync.when(
                        data: (districts) {
                          final match = districts.firstWhere(
                            (d) => d.id == techProfile?.districtId,
                            orElse: () => District(
                              id: 0,
                              name: 'Trujillo',
                              province: '',
                              department: '',
                              isActive: true,
                              createdAt: DateTime.now(),
                            ),
                          );
                          return match.name;
                        },
                        loading: () => 'Cargando...',
                        error: (error, stackTrace) => 'Error',
                      ),
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Biografía Profesional',
                      onTap: () {
                        _showBioDialog(context, techProfile?.bio ?? 'Sin biografía');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileSection(
                  title: 'Cuenta Técnico',
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Editar perfil técnico',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.photo_library_outlined,
                      title: 'Mi portafolio',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.history_rounded,
                      title: 'Historial de trabajos',
                      onTap: () {},
                    ),
                  ],
                ),
              ] else ...[
                _ProfileSection(
                  title: 'Cuenta',
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Editar perfil',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Direcciones guardadas',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.payment_outlined,
                      title: 'Métodos de pago',
                      onTap: () {},
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Menu: Preferences
              _ProfileSection(
                title: 'Preferencias',
                items: [
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Idioma',
                    trailing: 'Español',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tema oscuro',
                    trailing: 'Desactivado',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Menu: Support
              _ProfileSection(
                title: 'Soporte',
                items: [
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Centro de ayuda',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Términos de servicio',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'Cerrar sesión',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Toke+ v1.0.0',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _showBioDialog(BuildContext context, String bio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Biografía Profesional',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          bio,
          style: AppTypography.bodyMedium.copyWith(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSpecialtiesDialog(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.read(techCategoriesProvider);
    categoriesAsync.whenData((cats) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Mis Especialidades',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((cat) {
                return Chip(
                  label: Text('${cat.emoji ?? '🛠️'} ${cat.name}'),
                  backgroundColor: AppColors.primarySurface,
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  side: const BorderSide(color: AppColors.primaryLight),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 0, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
