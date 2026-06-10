import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Pantalla de seleccion de distrito de Trujillo.
/// Solo muestra los 11 distritos de la provincia de Trujillo.
class DistrictSelectorScreen extends StatelessWidget {
  const DistrictSelectorScreen({super.key, this.currentSelection});

  final String? currentSelection;

  /// Los 11 distritos de la provincia de Trujillo
  static const List<String> _districts = [
    'Trujillo',
    'El Porvenir',
    'Florencia de Mora',
    'Huanchaco',
    'La Esperanza',
    'Laredo',
    'Moche',
    'Poroto',
    'Salaverry',
    'Simbal',
    'Víctor Larco Herrera',
  ];

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

              // ── Chips de distritos ──
              Expanded(
                child: SingleChildScrollView(
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
                      final isSelected = district == currentSelection;

                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'Distrito $district',
                        child: GestureDetector(
                          onTap: () {
                            final navigator = Navigator.of(context);
                            // Retornar seleccion tras breve delay visual
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                if (!context.mounted) return;
                                navigator.pop(district);
                              },
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF0ED)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE8836B)
                                    : AppColors.neutral300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              district,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? const Color(0xFFE8836B)
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
