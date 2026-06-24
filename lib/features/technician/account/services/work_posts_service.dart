import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

class TechnicianWorkPost {
  const TechnicianWorkPost({
    required this.id,
    required this.description,
    required this.imageUrls,
    this.createdAt,
  });

  final String id;
  final String description;
  final List<String> imageUrls;
  final DateTime? createdAt;

  factory TechnicianWorkPost.fromJson(Map<String, dynamic> json) {
    final rawImages = json['image_urls'];
    return TechnicianWorkPost(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrls: rawImages is List
          ? rawImages
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class WorkPostsService {
  static const _bucket = 'work-photos';

  final InsForgeClient _client = InsForgeClient();

  Future<List<TechnicianWorkPost>> getMyPosts() async {
    final technicianId = await _client.getCurrentUserId();
    if (technicianId == null || technicianId.isEmpty) return const [];

    try {
      final encodedId = Uri.encodeQueryComponent(technicianId);
      final response = await _client.get(
        '/api/database/records/technician_work_posts?technician_id=eq.$encodedId&select=id,description,image_urls,created_at,is_public&order=created_at.desc',
        requireAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('getMyPosts error: ${response.statusCode} ${response.body}');
        return const [];
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => TechnicianWorkPost.fromJson(e as Map<String, dynamic>))
          .where((post) => post.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Exception getMyPosts: $e');
      return const [];
    }
  }

  Future<List<TechnicianWorkPost>> getPublicPosts(String technicianId) async {
    if (technicianId.trim().isEmpty) return const [];
    try {
      final encodedId = Uri.encodeQueryComponent(technicianId);
      final response = await _client.get(
        '/api/database/records/technician_work_posts?technician_id=eq.$encodedId&is_public=eq.true&select=id,description,image_urls,created_at&order=created_at.desc',
        requireAuth: false,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => TechnicianWorkPost.fromJson(e as Map<String, dynamic>))
          .where((post) => post.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Exception getPublicPosts: $e');
      return const [];
    }
  }

  Future<({bool success, String? message})> createPost({
    required String description,
    required List<String> photoPaths,
  }) async {
    final userId = await _client.getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      return (success: false, message: 'Sesión no válida.');
    }
    if (description.trim().isEmpty) {
      return (success: false, message: 'Describe el trabajo realizado.');
    }
    if (photoPaths.isEmpty) {
      return (success: false, message: 'Agrega al menos una foto.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];
    for (var i = 0; i < photoPaths.length; i++) {
      final path = photoPaths[i];
      final ext = _safeExtension(path);
      final result = await _client.uploadFile(
        bucket: _bucket,
        filePath: path,
        objectKey: 'technicians/$userId/work-posts/$timestamp-$i.$ext',
      );
      final url = result?['url'];
      if (url != null && url.isNotEmpty) urls.add(url);
    }

    if (urls.isEmpty) {
      return (success: false, message: 'No se pudieron subir las fotos.');
    }

    try {
      final response = await _client.post(
        '/api/database/records/technician_work_posts',
        body: [
          {
            'technician_id': userId,
            'description': description.trim(),
            'image_urls': urls,
            'is_public': true,
          },
        ],
        requireAuth: true,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (success: true, message: null);
      }
      debugPrint('createPost error: ${response.statusCode} ${response.body}');
      return (success: false, message: 'No se pudo publicar el trabajo.');
    } catch (e) {
      debugPrint('Exception createPost: $e');
      return (success: false, message: 'Error de conexión.');
    }
  }

  String _safeExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }
}
