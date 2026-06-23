import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tarjeta "fantasma" con animación de pulso + leve expansión, para mostrar
/// mientras cargan los pedidos.
class OrderCardSkeleton extends StatefulWidget {
  const OrderCardSkeleton({super.key, this.height = 150});

  final double height;

  @override
  State<OrderCardSkeleton> createState() => _OrderCardSkeletonState();
}

class _OrderCardSkeletonState extends State<OrderCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final base = Color.lerp(AppColors.neutral200, AppColors.neutral100, t)!;
        // Leve "expansión" vertical para dar sensación de carga.
        final scaleY = 0.97 + 0.03 * t;
        return Transform.scale(
          scaleY: scaleY,
          alignment: Alignment.topCenter,
          child: Container(
            height: widget.height,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(base, width: 90, height: 14),
                const SizedBox(height: 14),
                _bar(base, width: double.infinity, height: 16),
                const SizedBox(height: 10),
                _bar(base, width: 150, height: 12),
                const Spacer(),
                _bar(base, width: double.infinity, height: 38, radius: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(
    Color color, {
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
