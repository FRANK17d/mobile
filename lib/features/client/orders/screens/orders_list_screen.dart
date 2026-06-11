import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';

/// Pantalla de pedidos del cliente.
///
/// Cuando el usuario no esta autenticado muestra un empty state
/// con barra de busqueda y CTA para iniciar sesion / conocer el flujo.
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  // TODO: reemplazar con estado real de autenticacion
  static const _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const _AuthenticatedOrdersView();
    }
    return const _UnauthenticatedOrdersView();
  }
}

// ─────────────────────────────────────────────────────────
// Vista NO autenticada (empty state estilo referencia)
// ─────────────────────────────────────────────────────────
class _UnauthenticatedOrdersView extends StatelessWidget {
  const _UnauthenticatedOrdersView();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // ── Header oscuro ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: 20,
                right: 20,
                bottom: 28,
              ),
              decoration: const BoxDecoration(color: Color(0xFF1D2939)),
              child: Column(
                children: [
                  // ── Top bar: titulo + boton Entrar + menu ──
                  Row(
                    children: [
                      Text(
                        'Mis Pedidos',
                        style: AppTypography.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _EntrarButton(
                        onTap: () {
                          context.push(AppRoutes.login);
                        },
                      ),
                      const SizedBox(width: 10),
                      _HeaderMenuButton(
                        onTap: () {
                          showAppMenuSheet(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Barra de busqueda ──
                  Container(
                    width: double.infinity,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3B4F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Explorar pedidos de otros clientes',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido blanco con bordes redondeados arriba ──
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sin pedidos por ahora',
                            textAlign: TextAlign.center,
                            style: AppTypography.headingLarge.copyWith(
                              color: const Color(0xFF162033),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Una vez que solicites un servicio, vas a poder '
                            'seguir todo el proceso desde esta pantalla. '
                            'Simple, rápido y transparente.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ComoFuncionaButton(
                            onTap: () {
                              // TODO: navegar a pantalla como funciona
                            },
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────
// Boton "Entrar"
// ─────────────────────────────────────────────────────────
class _EntrarButton extends StatelessWidget {
  const _EntrarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Entrar',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton menu hamburguesa (mismo estilo que home)
// ─────────────────────────────────────────────────────────
class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "¿Como funciona?"
// ─────────────────────────────────────────────────────────
class _ComoFuncionaButton extends StatelessWidget {
  const _ComoFuncionaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          '¿Cómo funciona?',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista autenticada (con tabs de pedidos)
// ─────────────────────────────────────────────────────────
class _AuthenticatedOrdersView extends StatelessWidget {
  const _AuthenticatedOrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos'), centerTitle: false),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.labelLarge,
              unselectedLabelStyle: AppTypography.labelMedium,
              tabs: const [
                Tab(text: 'Activos'),
                Tab(text: 'Completados'),
                Tab(text: 'Cancelados'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _EmptyOrdersPlaceholder(),
                  _EmptyOrdersPlaceholder(),
                  _EmptyOrdersPlaceholder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.neutral300,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay pedidos',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
