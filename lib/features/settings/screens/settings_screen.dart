import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_preferences.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../profile/screens/biometric_access_screen.dart';
import '../../profile/screens/change_password_screen.dart';
import '../../profile/screens/delete_account_screen.dart';

/// Pantalla de Ajustes accesible desde el menú del cliente y del técnico.
///
/// Secciones: Apariencia, Notificaciones, Seguridad, Cuenta y Acerca de.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ─── State ───
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notif = await AppPreferences.isReceivingOrders();
    final bioEnabled = await BiometricService.instance.isEnabled();
    final bioSupported = await BiometricService.instance.isDeviceSupported();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notif;
      _biometricEnabled = bioEnabled;
      _biometricSupported = bioSupported;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajustes',
          style: AppTypography.headingSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.md,
              ),
              children: [
                // ── Apariencia ──
                _SectionHeader(title: 'Apariencia'),
                const SizedBox(height: AppSpacing.xs),
                _ThemeSelector(isDark: isDark),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Notificaciones ──
                _SectionHeader(title: 'Notificaciones'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Recibir notificaciones',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      await AppPreferences.setReceivingOrders(value);
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Seguridad ──
                _SectionHeader(title: 'Seguridad'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Acceso biométrico',
                  subtitle: _biometricSupported
                      ? null
                      : 'No disponible en este dispositivo',
                  trailing: _biometricSupported
                      ? Switch.adaptive(
                          value: _biometricEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) => _toggleBiometric(value),
                        )
                      : const Icon(
                          Icons.block_rounded,
                          color: AppColors.neutral400,
                          size: 20,
                        ),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Cuenta ──
                _SectionHeader(title: 'Cuenta'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  icon: Icons.key_outlined,
                  label: 'Cambiar contraseña',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutral500,
                  ),
                  onTap: () => _push(const ChangePasswordScreen()),
                ),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar cuenta',
                  labelColor: AppColors.error,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutral500,
                  ),
                  onTap: () => _push(const DeleteAccountScreen()),
                ),

                const SizedBox(height: AppSpacing.sectionGap),

                // ── Acerca de ──
                _SectionHeader(title: 'Acerca de'),
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Versión',
                  trailing: Text(
                    '1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  label: 'Términos y condiciones',
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.neutral500,
                  ),
                  onTap: () => _openUrl(
                    'https://tokeplus.com/terminos',
                  ),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  label: 'Política de privacidad',
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.neutral500,
                  ),
                  onTap: () => _openUrl(
                    'https://tokeplus.com/privacidad',
                  ),
                ),

                const SizedBox(height: AppSpacing.huge),
              ],
            ),
    );
  }

  // ─── Actions ───

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // Navegar a la pantalla de configuración biométrica
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BiometricAccessScreen()),
      );
    } else {
      await BiometricService.instance.disable();
      if (mounted) setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Widgets internos ───

/// Selector de tema: Claro / Oscuro / Sistema
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance,
      builder: (context, currentMode, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            children: [
              _ThemeOption(
                label: 'Claro',
                icon: Icons.light_mode_outlined,
                isSelected: currentMode == ThemeMode.light,
                onTap: () => ThemeService.instance.setMode(ThemeMode.light),
                isDark: isDark,
              ),
              _ThemeOption(
                label: 'Oscuro',
                icon: Icons.dark_mode_outlined,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () => ThemeService.instance.setMode(ThemeMode.dark),
                isDark: isDark,
              ),
              _ThemeOption(
                label: 'Sistema',
                icon: Icons.settings_suggest_outlined,
                isSelected: currentMode == ThemeMode.system,
                onTap: () => ThemeService.instance.setMode(ThemeMode.system),
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tile genérica de ajustes.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = labelColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xxs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSpacing.iconSize,
              color: labelColor ??
                  (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(color: textColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
