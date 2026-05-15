import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/responsive/master_detail.dart';

/// Pantalla de solicitudes del tecnico.
/// En tablet usa master-detail split.
class TechRequestsScreen extends StatefulWidget {
  const TechRequestsScreen({super.key});

  @override
  State<TechRequestsScreen> createState() => _TechRequestsScreenState();
}

class _TechRequestsScreenState extends State<TechRequestsScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes'),
        centerTitle: false,
      ),
      body: MasterDetailLayout(
        master: _RequestsList(
          selectedIndex: _selectedIndex,
          onSelect: (index) => setState(() => _selectedIndex = index),
        ),
        detail: _selectedIndex != null
            ? _RequestDetail(request: _mockRequests[_selectedIndex!])
            : null,
        detailPlaceholder: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 64, color: AppColors.neutral300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una solicitud',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({this.selectedIndex, required this.onSelect});

  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _mockRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final req = _mockRequests[index];
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySurface
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: AppShadows.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neutral200,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.neutral400, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.clientName, style: AppTypography.titleSmall),
                      Text(
                        req.service,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      req.timeAgo,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.price,
                      style: AppTypography.titleSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.request});

  final _RequestData request;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client info
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neutral200,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.neutral400, size: 36),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.clientName, style: AppTypography.headingSmall),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.starFilled),
                      const SizedBox(width: 2),
                      Text('4.5',
                          style: AppTypography.labelMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(' (23 servicios)',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Service details
          Text('Servicio solicitado', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(request.service, style: AppTypography.bodyLarge),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text('Descripcion', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            request.description,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: AppSpacing.md),

          // Location
          Text('Ubicacion', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    request.location,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Price
          Text('Presupuesto del cliente', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            request.price,
            style: AppTypography.displaySmall
                .copyWith(color: AppColors.primary),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textInverse,
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Mock data
class _RequestData {
  const _RequestData({
    required this.clientName,
    required this.service,
    required this.description,
    required this.location,
    required this.price,
    required this.timeAgo,
  });

  final String clientName;
  final String service;
  final String description;
  final String location;
  final String price;
  final String timeAgo;
}

const _mockRequests = [
  _RequestData(
    clientName: 'Juan Perez',
    service: 'Reparacion electrica urgente',
    description:
        'Se fue la luz en toda la casa. Necesito un electricista urgente. El breaker principal se dispara cada vez que lo subo.',
    location: 'Av. Libertador, Edif. Torre Norte, Piso 5, Caracas',
    price: '\$45',
    timeAgo: 'Hace 5 min',
  ),
  _RequestData(
    clientName: 'Ana Martinez',
    service: 'Instalacion de tomacorriente',
    description:
        'Necesito instalar 3 tomacorrientes nuevos en la cocina para los electrodomesticos.',
    location: 'Las Mercedes, Calle Paris, Casa 12, Caracas',
    price: '\$35',
    timeAgo: 'Hace 15 min',
  ),
  _RequestData(
    clientName: 'Pedro Gomez',
    service: 'Revision de tablero electrico',
    description:
        'El tablero electrico hace un ruido extrano. Quiero una revision preventiva.',
    location: 'Altamira, Av. San Juan Bosco, Edif. Altamira, Caracas',
    price: '\$25',
    timeAgo: 'Hace 30 min',
  ),
  _RequestData(
    clientName: 'Laura Diaz',
    service: 'Cableado nuevo para oficina',
    description:
        'Necesito cablear una oficina nueva con 8 puntos de red y 12 tomas electricas.',
    location: 'Chacao, Centro Comercial El Recreo, Local 205',
    price: '\$180',
    timeAgo: 'Hace 1 hora',
  ),
];
