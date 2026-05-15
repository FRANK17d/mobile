import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_grid.dart';
import '../widgets/search_header.dart';
import '../widgets/category_grid.dart';
import '../widgets/promo_banner.dart';
import '../widgets/nearby_technicians.dart';

/// Pantalla principal del cliente.
/// Muestra busqueda, categorias, promos y tecnicos cercanos.
class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // TODO: Refresh data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: breakpoint.screenPadding,
            ),
            child: ContentContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Search header
                  const SearchHeader(
                    userName: 'Usuario',
                    location: 'Caracas, Venezuela',
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.05, end: 0, duration: 400.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Promo banners
                  const PromoBanner()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Categories
                  const CategoryGrid()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Nearby technicians
                  const NearbyTechnicians()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
