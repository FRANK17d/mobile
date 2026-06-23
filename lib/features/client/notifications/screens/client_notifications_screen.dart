import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Pantalla de notificaciones del cliente.
///
/// Muestra las notificaciones reales (vía [NotificationService]) y, cuando no
/// hay ninguna, un estado vacío con ilustración ("No hay notificaciones").
class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

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
            Expanded(
              child: ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationService.instance.notifications,
                builder: (context, list, _) {
                  if (list.isEmpty) {
                    return const _EmptyNotifications();
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        NotificationService.instance.loadHistory(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = list[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.horizontal,
                          background: const _DismissBackground(toLeft: false),
                          secondaryBackground:
                              const _DismissBackground(toLeft: true),
                          onDismissed: (_) =>
                              NotificationService.instance.deleteNotification(n.id),
                          child: _NotificationCard(
                            notification: n,
                            onTap: () {
                              if (!n.isRead) {
                                NotificationService.instance.markAsRead(n.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
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
            color: isRead
                ? AppColors.borderLight
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isRead
                    ? AppColors.neutral200
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: isRead ? AppColors.neutral500 : AppColors.primary,
              ),
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
}

/// Fondo rojo "Eliminar" que se revela al deslizar una notificación.
class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.toLeft});

  /// true = se reveló deslizando de derecha a izquierda (contenido a la derecha).
  final bool toLeft;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22);
    const label = Text(
      'Eliminar',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    );

    return Container(
      alignment: toLeft ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: toLeft
            ? const [label, SizedBox(width: 8), icon]
            : const [icon, SizedBox(width: 8), label],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Estado vacío con ilustración (círculo + figuras)
// ─────────────────────────────────────────────────────────
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _EmptyIllustration(),
          const SizedBox(height: 28),
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

/// Ilustración del estado vacío: un círculo suave con pequeñas figuras
/// geométricas alrededor (cuadrado, círculo y rombo de acento).
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo exterior muy tenue
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEFF2),
              shape: BoxShape.circle,
            ),
          ),
          // Círculo interior
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E6EB),
              shape: BoxShape.circle,
            ),
          ),
          // Cuadrado naranja (arriba-izquierda)
          Positioned(
            top: 24,
            left: 34,
            child: _ShapeOutline(
              color: AppColors.primary,
              child: const SizedBox(width: 14, height: 14),
            ),
          ),
          // Círculo naranja (arriba-derecha)
          Positioned(
            top: 30,
            right: 36,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          // Rombo rojo (abajo-derecha)
          Positioned(
            bottom: 30,
            right: 44,
            child: Transform.rotate(
              angle: 0.785398, // 45°
              child: _ShapeOutline(
                color: const Color(0xFFE05A5A),
                child: const SizedBox(width: 12, height: 12),
              ),
            ),
          ),
          // Punto pequeño (izquierda)
          Positioned(
            bottom: 64,
            left: 28,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFE05A5A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeOutline extends StatelessWidget {
  const _ShapeOutline({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: child,
    );
  }
}
