import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/services/auth_service.dart';
import 'visibility_config_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.profileData});

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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisibilityConfigScreen(
          firstName: _firstName,
          initialVisible: !_receiving,
        ),
      ),
    );
    if (!mounted) return;
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
            const Divider(height: 1, thickness: 1, color: AppColors.borderLight),

            // Switch "Recibir nuevos pedidos"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 26, color: AppColors.secondary),
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

            // Lista de notificaciones reales
            Expanded(child: _NotificationsList()),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  IconData _iconForType(String type) {
    switch (type) {
      case 'request_approved':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'new_application':
        return Icons.person_add_outlined;
      case 'application_accepted':
        return Icons.emoji_events_outlined;
      case 'application_rejected':
        return Icons.thumb_down_outlined;
      case 'technician_verified':
        return Icons.verified_outlined;
      case 'verification_rejected':
        return Icons.gpp_bad_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const _EmptyNotifications();
        }

        return RefreshIndicator(
          onRefresh: () => NotificationService.instance.loadHistory(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = list[i];
              return _NotificationCard(
                notification: n,
                icon: _iconForType(n.type),
                onTap: () {
                  if (!n.isRead) {
                    NotificationService.instance.markAsRead(n.id);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.onTap,
  });

  final AppNotification notification;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isRead ? AppColors.neutral200 : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20,
                  color: isRead ? AppColors.neutral500 : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt!),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Toggle Sí/No ─────────────────────────────────────────────
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

// ─── Estado vacío ─────────────────────────────────────────────
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: AppColors.neutral500.withValues(alpha: 0.9)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.emptyNotifications,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando\nhaya actividad en tus pedidos.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
