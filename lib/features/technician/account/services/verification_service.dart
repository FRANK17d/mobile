import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

class VerificationSubmitResult {
  const VerificationSubmitResult({
    required this.success,
    required this.message,
    this.error,
  });

  final bool success;
  final String message;
  final String? error;
}

/// Un documento de verificación ya enviado por el técnico (para mostrarlo al
/// volver a la pantalla).
class SubmittedDoc {
  const SubmittedDoc({
    required this.docType,
    required this.filePath,
    required this.status,
    this.reviewNotes,
    this.createdAt,
  });

  final String docType;
  final String filePath;
  final String status; // pending | verified | rejected
  final String? reviewNotes;
  final DateTime? createdAt;

  factory SubmittedDoc.fromJson(Map<String, dynamic> j) => SubmittedDoc(
    docType: j['doc_type'] as String? ?? '',
    filePath: j['file_path'] as String? ?? '',
    status: j['status'] as String? ?? 'pending',
    reviewNotes: j['review_notes'] as String?,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );
}

class VerificationService {
  VerificationService({InsForgeClient? client})
    : _client = client ?? InsForgeClient();

  static const _bucket = 'verification-docs';

  final InsForgeClient _client;

  Future<VerificationSubmitResult> submitIdentityDocuments({
    required String dniFrontPath,
    required String dniBackPath,
    required String selfiePath,
    String? certificatePath,
  }) async {
    try {
      final userId = await _client.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        return const VerificationSubmitResult(
          success: false,
          error: 'not_authenticated',
          message: 'Inicia sesión nuevamente para enviar tus documentos.',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dniFrontKey = _objectKey(
        userId,
        'dni_front',
        dniFrontPath,
        timestamp,
      );
      final dniBackKey = _objectKey(userId, 'dni_back', dniBackPath, timestamp);
      final selfieKey = _objectKey(userId, 'selfie', selfiePath, timestamp);

      final dniFrontUpload = await _client.uploadFile(
        bucket: _bucket,
        filePath: dniFrontPath,
        objectKey: dniFrontKey,
      );
      if (dniFrontUpload == null) return _uploadError('DNI frontal');

      final dniBackUpload = await _client.uploadFile(
        bucket: _bucket,
        filePath: dniBackPath,
        objectKey: dniBackKey,
      );
      if (dniBackUpload == null) return _uploadError('DNI reverso');

      final selfieUpload = await _client.uploadFile(
        bucket: _bucket,
        filePath: selfiePath,
        objectKey: selfieKey,
      );
      if (selfieUpload == null) return _uploadError('selfie');

      // Documento opcional (certificado de estudios / cursos).
      String? certKeyFinal;
      if (certificatePath != null && certificatePath.trim().isNotEmpty) {
        final certKey = _objectKey(
          userId,
          'certificate',
          certificatePath,
          timestamp,
        );
        final certUpload = await _client.uploadFile(
          bucket: _bucket,
          filePath: certificatePath,
          objectKey: certKey,
        );
        if (certUpload == null) return _uploadError('certificado');
        certKeyFinal = certUpload['key'] ?? certKey;
      }

      final response = await _client.post(
        '/api/database/rpc/submit_verification_documents',
        body: {
          'p_dni_front_path': dniFrontUpload['key'] ?? dniFrontKey,
          'p_dni_back_path': dniBackUpload['key'] ?? dniBackKey,
          'p_selfie_path': selfieUpload['key'] ?? selfieKey,
          'p_certificate_path': ?certKeyFinal,
        },
        requireAuth: true,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Verification RPC failed (${response.statusCode}): ${response.body}',
        );
        return const VerificationSubmitResult(
          success: false,
          error: 'rpc_failed',
          message: 'No se pudo registrar el envío. Inténtalo nuevamente.',
        );
      }

      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic> && payload['success'] == true) {
        return VerificationSubmitResult(
          success: true,
          message: payload['message'] as String? ?? 'Documentos enviados.',
        );
      }

      return VerificationSubmitResult(
        success: false,
        error: payload is Map<String, dynamic>
            ? payload['error'] as String?
            : 'unknown',
        message: payload is Map<String, dynamic>
            ? payload['message'] as String? ??
                  'No se pudo enviar la verificación.'
            : 'No se pudo enviar la verificación.',
      );
    } catch (e) {
      debugPrint('Exception submitting verification documents: $e');
      return const VerificationSubmitResult(
        success: false,
        error: 'network',
        message: 'Error de conexión al enviar tus documentos.',
      );
    }
  }

  /// Documentos que el técnico ya envió (último por tipo), para mostrarlos al
  /// volver a la pantalla de verificación.
  Future<List<SubmittedDoc>> getMyDocuments() async {
    try {
      final response = await _client.post(
        '/api/database/rpc/get_my_verification_documents',
        requireAuth: true,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((e) => SubmittedDoc.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } catch (e) {
      debugPrint('getMyDocuments error: $e');
      return const [];
    }
  }

  /// URL del objeto en el bucket PRIVADO. Para mostrarlo hay que pasar el header
  /// `Authorization: Bearer <token>` (la RLS deja al dueño leer lo suyo).
  String storageUrlForKey(String key) =>
      '${InsForgeClient.baseUrl}/api/storage/buckets/$_bucket/objects/${Uri.encodeComponent(key)}';

  /// Header de autorización para cargar documentos privados con `Image.network`.
  Future<Map<String, String>> authImageHeaders() async {
    final token = await _client.getAccessToken();
    return token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : const {};
  }

  VerificationSubmitResult _uploadError(String label) {
    return VerificationSubmitResult(
      success: false,
      error: 'upload_failed',
      message:
          'No se pudo subir $label. Verifica la imagen e inténtalo otra vez.',
    );
  }

  String _objectKey(
    String userId,
    String docType,
    String filePath,
    int timestamp,
  ) {
    final extension = _safeExtension(filePath);
    return 'technicians/$userId/verification/$docType-$timestamp.$extension';
  }

  String _safeExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }
}
