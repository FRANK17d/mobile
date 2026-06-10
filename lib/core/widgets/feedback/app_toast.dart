import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// Tipos de toast para la app.
enum ToastType { info, success, warning, error }

/// Muestra un toast overlay con diseño custom Toke+.
/// Reemplaza los SnackBars genericos del sistema.
void showAppToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      type: type,
      icon: icon,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.icon,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final IconData? icon;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _toastConfig(widget.type);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: AppSpacing.screenPaddingH,
      right: AppSpacing.screenPaddingH,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (_) => _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: config.borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.borderColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon ?? config.icon,
                      size: 20,
                      color: config.iconColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTypography.bodyMedium.copyWith(
                          color: config.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastConfig _toastConfig(ToastType type) {
    return switch (type) {
      ToastType.success => const _ToastConfig(
          backgroundColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFF86EFAC),
          iconColor: Color(0xFF16A34A),
          textColor: Color(0xFF15803D),
          icon: Icons.check_circle_rounded,
        ),
      ToastType.error => const _ToastConfig(
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFCA5A5),
          iconColor: Color(0xFFDC2626),
          textColor: Color(0xFFB91C1C),
          icon: Icons.error_rounded,
        ),
      ToastType.warning => const _ToastConfig(
          backgroundColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFCD34D),
          iconColor: Color(0xFFD97706),
          textColor: Color(0xFF92400E),
          icon: Icons.warning_rounded,
        ),
      ToastType.info => const _ToastConfig(
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFF93C5FD),
          iconColor: Color(0xFF2563EB),
          textColor: Color(0xFF1E40AF),
          icon: Icons.info_rounded,
        ),
    };
  }
}

class _ToastConfig {
  const _ToastConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
}
