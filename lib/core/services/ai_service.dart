import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../network/insforge_client.dart';

class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
  });

  /// Id de la categoría como String (el mobile lo parsea a int si aplica).
  final String categoryId;
  final String categoryName;
  final double confidence;

  bool get isConfident => confidence >= 0.6;
}

/// IA del marketplace vía la Edge Function de InsForge (`ai-gateway`),
/// que usa el Model Gateway (OpenRouter). Misma base URL que el resto de
/// llamadas a InsForge — no requiere un backend aparte.
class AiService {
  final InsForgeClient _client = InsForgeClient();

  static const _endpoint = '/functions/ai-gateway';

  /// Sugiere una categoría a partir de la descripción del pedido.
  /// [categories] son las categorías reales (id como String + nombre).
  Future<CategorySuggestion?> suggestCategory(
    String description,
    List<Map<String, String>> categories,
  ) async {
    try {
      final response = await _client.post(
        _endpoint,
        body: {
          'action': 'suggest_category',
          'description': description,
          'categories': categories,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final id = data['category_id'] as String?;
        if (id != null && id.isNotEmpty) {
          return CategorySuggestion(
            categoryId: id,
            categoryName: data['category_name'] as String? ?? '',
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('AiService.suggestCategory error: $e');
      return null;
    }
  }

  /// Chat de soporte con IA. [history] es la conversación previa
  /// (cada item: {'role': 'user'|'assistant', 'content': '...'}).
  Future<String?> supportChat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await _client.post(
        _endpoint,
        body: {
          'action': 'support',
          'message': message,
          'history': history,
        },
        requireAuth: true,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['response'] as String?;
      }
      // 503 = IA no configurada (sin OPENROUTER_API_KEY). Devolvemos null y
      // la UI muestra su mensaje de respaldo.
      return null;
    } catch (e) {
      debugPrint('AiService.supportChat error: $e');
      return null;
    }
  }
}
