import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../services/district_service.dart';

/// Pantalla de selección de distrito.
/// Carga los distritos activos desde la tabla `districts` (InsForge) en vez
/// de una lista hardcodeada. Devuelve el [District] seleccionado.
class DistrictSelectorScreen extends StatefulWidget {
  const DistrictSelectorScreen({super.key, this.currentSelection});

  final District? currentSelection;

  @override
  State<DistrictSelectorScreen> createState() => _DistrictSelectorScreenState();
}

class _DistrictSelectorScreenState extends State<DistrictSelectorScreen> {
  final DistrictService _service = DistrictService();

  List<District> _districts = const [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final districts = await _service.getActiveDistricts();

    if (!mounted) return;
    setState(() {
      _districts = districts;
      _loading = false;
      _error = districts.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Volver',
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Volver',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Seleccione su distrito',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── Header provincia ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.backgroundSecondary,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Provincia de Trujillo',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // ── Contenido ──
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudieron cargar los distritos.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.lg,
        AppSpacing.screenPaddingH,
        AppSpacing.xxl,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        children: _districts.map((district) {
          final isSelected = district.id == widget.currentSelection?.id;

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Distrito ${district.name}',
            child: GestureDetector(
              onTap: () {
                final navigator = Navigator.of(context);
                // Retornar selección tras breve delay visual
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (!context.mounted) return;
                  navigator.pop(district);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF0ED) : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE8836B)
                        : AppColors.neutral300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  district.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? const Color(0xFFE8836B)
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
