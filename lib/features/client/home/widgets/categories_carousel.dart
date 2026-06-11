import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../services/category_service.dart';

/// Carrusel infinito auto-scroll de categorias de servicio.
///
/// Carga las categorias reales desde InsForge (`service_categories`) y, mientras
/// llegan o si falla la red, usa una lista de respaldo local. Duplica los items
/// internamente para lograr el efecto de scroll continuo sin saltos. Se pausa al
/// tocar y reanuda al soltar.
class CategoriesCarousel extends StatefulWidget {
  const CategoriesCarousel({super.key, this.onCategoryTap});

  final void Function(String category)? onCategoryTap;

  @override
  State<CategoriesCarousel> createState() => _CategoriesCarouselState();
}

class _CategoriesCarouselState extends State<CategoriesCarousel>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  static const _scrollSpeed = 30.0; // pixels por segundo
  static const _itemWidth = 82.0;
  static const _itemSpacing = 10.0;
  static const _totalItemWidth = _itemWidth + _itemSpacing;

  /// Categorias mostradas: arrancan con el respaldo local y se reemplazan por
  /// las del backend cuando llegan.
  List<_CatData> _categories = _fallbackCategories;

  // Se duplica la lista para scroll infinito
  double get _singleSetWidth => _categories.length * _totalItemWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // se actualiza en cada frame
    );

    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService().getActiveCategories();
    if (!mounted || categories.isEmpty) return;
    setState(() {
      _categories = categories
          .map((c) => _CatData(name: c.name, emoji: c.emoji))
          .toList();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _animController.addListener(_onTick);
    _animController.repeat();
  }

  DateTime? _lastTick;

  void _onTick() {
    final now = DateTime.now();
    if (_lastTick != null && _scrollController.hasClients) {
      final dt = now.difference(_lastTick!).inMilliseconds / 1000.0;
      final newOffset = _scrollController.offset + (_scrollSpeed * dt);

      // Reset cuando pasamos el primer set completo
      if (newOffset >= _singleSetWidth) {
        _scrollController.jumpTo(newOffset - _singleSetWidth);
      } else {
        _scrollController.jumpTo(newOffset);
      }
    }
    _lastTick = now;
  }

  void _pauseScroll() {
    _animController.stop();
    _lastTick = null;
  }

  void _resumeScroll() {
    _lastTick = null;
    _animController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    // Triplicamos para que siempre haya items visibles
    final items = [..._categories, ..._categories, ..._categories];

    return GestureDetector(
      onPanDown: (_) => _pauseScroll(),
      onPanEnd: (_) => _resumeScroll(),
      onPanCancel: _resumeScroll,
      child: SizedBox(
        width: double.infinity,
        height: 90,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: _itemSpacing),
                  itemBuilder: (_, index) {
                    final cat = items[index];
                    return _CategoryChip(
                      label: cat.name,
                      emoji: cat.emoji,
                      onTap: () => widget.onCategoryTap?.call(cat.name),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 34,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 34,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Datos de categorias ───
class _CatData {
  const _CatData({required this.name, required this.emoji});
  final String name;
  final String emoji;
}

/// Respaldo local: se muestra mientras llegan las categorias del backend o si
/// la red falla. Refleja las categorias activas de `service_categories`.
const _fallbackCategories = [
  _CatData(name: 'Albañil', emoji: '🧱'),
  _CatData(name: 'Electricista', emoji: '⚡'),
  _CatData(name: 'Pintura', emoji: '🎨'),
  _CatData(name: 'Plomero', emoji: '🔧'),
  _CatData(name: 'Aire Acondicionado', emoji: '❄️'),
  _CatData(name: 'Jardinería', emoji: '🌿'),
];

// ─── Chip de categoria ───
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.emoji, this.onTap});

  final String label;
  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _CategoriesCarouselState._itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.neutral700,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
