import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_grid.dart';

/// Pantalla de perfil del usuario.
/// Se adapta segun el rol (cliente o tecnico).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.isTechnician = false});

  final bool isTechnician;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
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

              // Avatar + name
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
                      child: Icon(
                        Icons.person_rounded,
                        size: breakpoint.isTablet ? 48 : 40,
                        color: AppColors.neutral400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Juan Perez', style: AppTypography.headingMedium),
                    const SizedBox(height: 2),
                    Text(
                      isTechnician ? 'Electricista Certificado' : 'Cliente',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (isTechnician) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.starFilled),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: AppTypography.titleMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            ' (124 resenas)',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats row (for technician)
              if (isTechnician) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(
                      label: 'Trabajos',
                      value: '127',
                      icon: Icons.work_rounded,
                    ),
                    _ProfileStat(
                      label: 'Clientes',
                      value: '89',
                      icon: Icons.people_rounded,
                    ),
                    _ProfileStat(
                      label: 'Anos',
                      value: '3',
                      icon: Icons.timeline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Menu items
              _ProfileSection(
                title: 'Cuenta',
                items: [
                  _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Editar perfil',
                    onTap: () {},
                  ),
                  if (isTechnician)
                    _ProfileMenuItem(
                      icon: Icons.photo_library_outlined,
                      title: 'Mi portafolio',
                      onTap: () {},
                    ),
                  _ProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Direcciones guardadas',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Metodos de pago',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

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
                    trailing: 'Espanol',
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
                    title: 'Politica de privacidad',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terminos de servicio',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Logout
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Cerrar sesion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Toke+ v1.0.0',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.headingSmall),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
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
              child: Text(title, style: AppTypography.bodyMedium),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
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
