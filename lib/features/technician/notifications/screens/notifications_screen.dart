import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/services/auth_service.dart';
import 'visibility_config_screen.dart';

/// Pantalla de notificaciones del técnico.
///
/// Muestra el switch "Recibir nuevos pedidos" y la lista de notificaciones
/// (vacía por ahora). El switch es el acceso al flujo de visibilidad: al
/// tocarlo abre [VisibilityConfigScreen] para confirmar y guardar el cambio.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.profileData});

  /// Perfil del técnico (para personalizar el título de configuración).
  final Map<String, dynamic>? profileData;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _receiving = true;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _firstName = _extractFirstName(widget.profileData);
    _loadState();
  }

  Future<void> _loadState() async {
    final receiving = await AppPreferences.isReceivingOrders();
    // Si no llegó el perfil por parámetro, intentamos obtenerlo.
    String? name;
    if (_firstName.isEmpty) {
      final profile = await AuthService().getMyTechnicianProfile();
      name = _extractFirstName(profile);
    }
    if (!mounted) return;
    setState(() {
      _receiving = receiving;
      if (name != null && name.isNotEmpty) _firstName = name;
    });
  }

  String _extractFirstName(Map<String, dynamic>? profile) {
    if (profile == null) return '';
    final fullName =
        profile['full_name'] as String? ?? profile['name'] as String? ?? '';
    if (fullName.isEmpty) return '';
    return fullName.trim().split(' ').first;
  }

  Future<void> _openVisibilityConfig() async {
    // El switch propone invertir el estado actual; el usuario confirma y guarda.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisibilityConfigScreen(
          firstName: _firstName,
          initialVisible: !_receiving,
        ),
      ),
    );
    if (!mounted) return;
    // Refresca el estado al volver (pudo guardarse un cambio).
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            AppStrings.notificationsTitle,
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

            // ── Switch "Recibir nuevos pedidos" ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 26,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.receiveNewOrders,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _YesNoToggle(value: _receiving, onTap: _openVisibilityConfig),
                ],
              ),
            ),

            // ── Estado vacío ──
            const Expanded(child: _EmptyNotifications()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Toggle Sí/No (pill)
// ─────────────────────────────────────────────────────────
class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 82,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.neutral300,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Etiqueta del estado ──
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  value ? AppStrings.switchYes : AppStrings.switchNo,
                  style: AppTypography.titleMedium.copyWith(
                    color: value ? Colors.white : AppColors.neutral600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // ── Perilla ──
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Estado vacío
// ─────────────────────────────────────────────────────────
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Halo difuso ──
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neutral200.withValues(alpha: 0.5),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neutral200,
                  ),
                ),
                // ── Formas decorativas ──
                const Positioned(
                  top: 24,
                  left: 36,
                  child: _DecorShape(isSquare: true, color: AppColors.primary),
                ),
                Positioned(
                  top: 30,
                  right: 30,
                  child: _DecorShape(
                    isSquare: false,
                    color: AppColors.primaryLight,
                  ),
                ),
                const Positioned(
                  bottom: 44,
                  left: 22,
                  child: _DecorShape(isSquare: false, color: AppColors.primary),
                ),
                const Positioned(
                  bottom: 36,
                  right: 44,
                  child: _DecorShape(isSquare: true, color: AppColors.error),
                ),
                // ── Campana ──
                Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: AppColors.neutral500.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.emptyNotifications,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pequeño cuadrado o círculo con borde, como las formas flotantes del mockup.
class _DecorShape extends StatelessWidget {
  const _DecorShape({required this.isSquare, required this.color});

  final bool isSquare;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: isSquare ? 0.5 : 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isSquare ? BorderRadius.circular(3) : null,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
