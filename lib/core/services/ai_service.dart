import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../network/insforge_client.dart';

class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
  });

  final String categoryId;
  final String categoryName;
  final double confidence;

  bool get isConfident => confidence >= 0.7;
}

class AiService {
  final InsForgeClient _client = InsForgeClient();

  /// Sugiere una categoría basándose en la descripción del pedido.
  Future<CategorySuggestion?> suggestCategory(String description) async {
    try {
      final response = await _client.post(
        '/api/ai/suggest-category',
        body: {'description': description},
        requireAuth: false,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['category_id'] != null &&
            (data['category_id'] as String).isNotEmpty) {
          return CategorySuggestion(
            categoryId: data['category_id'] as String,
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

  /// Chat de soporte con IA.
  Future<String?> supportChat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await _client.post(
        '/api/ai/support',
        body: {'message': message, 'history': history},
        requireAuth: true,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['response'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('AiService.supportChat error: $e');
      return null;
    }
  }
}
