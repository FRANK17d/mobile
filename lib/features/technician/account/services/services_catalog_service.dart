import 'dart:convert';

import '../../../../core/network/insforge_client.dart';

/// Un servicio (sub-servicio) dentro de una categoría, con el flag de si el
/// técnico actual lo ofrece.
class CatalogService {
  final int id;
  final String name;
  final bool selected;

  const CatalogService({
    required this.id,
    required this.name,
    required this.selected,
  });

  factory CatalogService.fromJson(Map<String, dynamic> j) => CatalogService(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String? ?? '',
    selected: j['selected'] == true,
  );
}

/// Una categoría con su lista de servicios.
class ServiceCatalogCategory {
  final int id;
  final String name;
  final String emoji;
  final List<CatalogService> services;

  const ServiceCatalogCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.services,
  });

  factory ServiceCatalogCategory.fromJson(Map<String, dynamic> j) =>
      ServiceCatalogCategory(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🛠️',
        services: ((j['services'] as List<dynamic>?) ?? const [])
            .map((e) => CatalogService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Acceso al catálogo de servicios por categoría y a la selección del técnico.
class ServicesCatalogService {
  final InsForgeClient _client = InsForgeClient();

  /// Catálogo completo agrupado por categoría, con `selected` por servicio.
  Future<List<ServiceCatalogCategory>> getCatalog() async {
    final res = await _client.post(
      '/api/database/rpc/get_technician_services_catalog',
      body: const {},
      requireAuth: true,
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map(
              (e) => ServiceCatalogCategory.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    }
    return const [];
  }

  /// Reemplaza la selección completa del técnico por [serviceIds].
  Future<({bool success, String? message})> setServices(
    List<int> serviceIds,
  ) async {
    try {
      final res = await _client.post(
        '/api/database/rpc/set_technician_services',
        body: {'p_service_ids': serviceIds},
        requireAuth: true,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final r = jsonDecode(res.body) as Map<String, dynamic>;
        return (success: r['success'] == true, message: r['message'] as String?);
      }
      return (success: false, message: 'No se pudo guardar.');
    } catch (_) {
      return (success: false, message: 'Error de conexión.');
    }
  }
}
