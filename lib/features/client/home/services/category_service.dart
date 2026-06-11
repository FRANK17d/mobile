import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

/// Categoría de servicio tal como vive en la tabla `service_categories`.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.slug,
  });

  final int id;
  final String name;
  final String emoji;
  final String slug;

  /// Descripción corta para la pantalla "Explorar". No existe en el backend
  /// (`service_categories` no tiene columna de descripción), así que se resuelve
  /// localmente por `slug`. Vacía si la categoría aún no tiene texto.
  String get description => kCategoryDescriptions[slug] ?? '';

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

/// Descripciones cortas por `slug` para la pantalla "Explorar".
/// Centralizadas aquí para no acoplarlas a la base de datos.
const Map<String, String> kCategoryDescriptions = {
  'albanil':
      '¿Necesitas construir un muro, reparar una pared o hacer una remodelación '
      'en tu hogar?',
  'electricista':
      '¿Tenés que arreglar una instalación eléctrica, cambiar un enchufe o '
      'solucionar un cortocircuito?',
  'pintura': '¿Querés pintar tu casa, alguna pared o retocar algo?',
  'plomero':
      '¿Necesitas reparar tu ducha, alguna cañería o solucionar una fuga de '
      'agua?',
  'aire-acondicionado':
      'Instalación, mantenimiento, reparación o mudar/trasladar tu equipo.',
  'piscinas': '¿Necesitas limpiar, mantener o reparar tu piscina?',
  'jardineria':
      '¿Necesitas cortar el pasto, arreglar algún terreno o decorar tu jardín?',
  'contratista-construccion':
      '¿Buscas un contratista para tu obra o proyecto de construcción?',
  'flete-mudanza':
      '¿Necesitas un servicio de flete, realizar una mudanza o transportar '
      'muebles?',
  'seguridad':
      '¿Querés instalar cámaras, alarmas o reforzar la seguridad de tu hogar?',
  'azulejista':
      '¿Necesitas colocar o reparar azulejos en baños, cocinas o paredes?',
  'pisos-baldosas': '¿Buscas instalar o reparar pisos y baldosas en tu hogar?',
  'diseno-interiores': '¿Querés renovar y decorar los espacios de tu hogar?',
  'iluminacion':
      '¿Necesitas instalar o mejorar la iluminación de tus ambientes?',
  'herrero':
      '¿Necesitas reparar una reja, fabricar una estructura metálica o hacer '
      'mantenimiento a puertas de hierro?',
};

/// Lee las categorías de servicio del backend InsForge (PostgREST).
class CategoryService {
  final InsForgeClient _client = InsForgeClient();

  /// Devuelve las categorías activas ordenadas por id.
  /// Funciona con o sin sesión (lectura pública del rol anon).
  Future<List<ServiceCategory>> getActiveCategories() async {
    try {
      final response = await _client.get(
        '/api/database/records/service_categories'
        '?is_active=eq.true&order=id.asc&select=id,name,emoji,slug',
        requireAuth: false,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint('Categories fetch error: ${response.statusCode}');
      return const [];
    } catch (e) {
      debugPrint('Exception fetching categories: $e');
      return const [];
    }
  }
}
