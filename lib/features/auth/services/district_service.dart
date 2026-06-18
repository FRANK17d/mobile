import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/network/insforge_client.dart';

/// Distrito tal como vive en la tabla `districts`.
class District {
  const District({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final double? latitude;
  final double? longitude;

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Lee los distritos del backend InsForge (PostgREST).
/// Reemplaza la lista hardcodeada: ahora la fuente de verdad es la tabla
/// `districts`, así el admin puede agregar/quitar distritos sin recompilar.
class DistrictService {
  final InsForgeClient _client = InsForgeClient();

  /// Devuelve los distritos activos ordenados por nombre.
  /// Funciona con o sin sesión (lectura del rol anon/authenticated).
  Future<List<District>> getActiveDistricts() async {
    try {
      final response = await _client.get(
        '/api/database/records/districts'
        '?is_active=eq.true&order=name.asc&select=id,name,latitude,longitude',
        requireAuth: false,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => District.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint('Districts fetch error: ${response.statusCode}');
      return const [];
    } catch (e) {
      debugPrint('Exception fetching districts: $e');
      return const [];
    }
  }
}
