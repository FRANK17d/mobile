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

class VerificationService {
  VerificationService({InsForgeClient? client})
    : _client = client ?? InsForgeClient();

  static const _bucket = 'verification-docs';

  final InsForgeClient _client;

  Future<VerificationSubmitResult> submitIdentityDocuments({
    required String dniFrontPath,
    required String dniBackPath,
    required String selfiePath,
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

      final response = await _client.post(
        '/api/database/rpc/submit_verification_documents',
        body: {
          'p_dni_front_path': dniFrontUpload['key'] ?? dniFrontKey,
          'p_dni_back_path': dniBackUpload['key'] ?? dniBackKey,
          'p_selfie_path': selfieUpload['key'] ?? selfieKey,
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
