import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/responsive/responsive_grid.dart';
import '../../../../core/widgets/cards/service_card.dart';

/// Pantalla de lista de pedidos del cliente.
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        centerTitle: false,
      ),
      body: ContentContainer(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Tabs
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
              const SizedBox(height: AppSpacing.sm),

              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    _OrdersList(orders: _activeOrders),
                    _OrdersList(orders: _completedOrders),
                    _OrdersList(orders: _cancelledOrders),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders});

  final List<_OrderData> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay pedidos',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final order = orders[index];
        return ServiceOrderCard(
          serviceName: order.service,
          technicianName: order.technician,
          date: order.date,
          status: order.status,
          statusColor: order.statusColor,
          price: order.price,
          onTap: () {
            // TODO: Navigate to order detail
          },
        );
      },
    );
  }
}

// Mock data
class _OrderData {
  const _OrderData(this.service, this.technician, this.date, this.status,
      this.statusColor, this.price);
  final String service;
  final String technician;
  final String date;
  final String status;
  final Color statusColor;
  final String price;
}

const _activeOrders = [
  _OrderData('Reparacion electrica', 'Carlos Rodriguez', 'Hoy, 2:00 PM',
      'En camino', AppColors.info, '\$45'),
  _OrderData('Instalacion de grifo', 'Maria Gonzalez', 'Manana, 10:00 AM',
      'Confirmado', AppColors.success, '\$60'),
];

const _completedOrders = [
  _OrderData('Cambio de cerradura', 'Jose Martinez', '12 May 2026',
      'Completado', AppColors.success, '\$35'),
  _OrderData('Pintura de habitacion', 'Ana Lopez', '8 May 2026', 'Completado',
      AppColors.success, '\$120'),
  _OrderData('Limpieza profunda', 'Laura Diaz', '2 May 2026', 'Completado',
      AppColors.success, '\$80'),
];

const _cancelledOrders = [
  _OrderData('Reparacion A/C', 'Pedro Sanchez', '28 Abr 2026', 'Cancelado',
      AppColors.error, '\$0'),
];
