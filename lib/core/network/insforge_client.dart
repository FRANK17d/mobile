import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cliente HTTP singleton para InsForge.
/// Garantiza que solo una instancia maneje tokens y refresh.
class InsForgeClient {
  // ── Singleton ──
  static final InsForgeClient _instance = InsForgeClient._internal();
  factory InsForgeClient() => _instance;
  InsForgeClient._internal();

  static const String baseUrl = 'https://439t8drp.us-east.insforge.app';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4NDUzMTR9.cH00CEsIwy7FW31ZZgfp5Lt9yVVmtBFhMO9wEDXF_9E';
  static const int _maxUploadBytes = 5 * 1024 * 1024;

  final _storage = const FlutterSecureStorage();

  /// Lock para evitar refresh concurrente desde multiples llamadas.
  Completer<bool>? _refreshCompleter;

  static const String _accessTokenKey = 'insforge_access_token';
  static const String _refreshTokenKey = 'insforge_refresh_token';

  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Limpia TODOS los datos de sesion incluyendo tokens y verifiers OAuth.
  Future<void> clearAllAuthData() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Refresca la sesion con lock para evitar llamadas concurrentes.
  Future<bool> refreshSession() async {
    // Si ya hay un refresh en progreso, esperar ese resultado.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final result = await _doRefresh();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh?client_type=mobile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (accessToken == null || accessToken.isEmpty) return false;

        await saveTokens(accessToken, newRefreshToken ?? refreshToken);
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await clearTokens();
      }

      debugPrint(
        'Session refresh failed (${response.statusCode}): ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('Exception during session refresh: $e');
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};

    if (requireAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        headers['Authorization'] = 'Bearer $_anonKey';
      }
    } else {
      headers['Authorization'] = 'Bearer $_anonKey';
    }

    return headers;
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function(Map<String, String> headers) send, {
    bool requireAuth = true,
  }) async {
    final response = await send(await _getHeaders(requireAuth: requireAuth));

    if (!requireAuth || response.statusCode != 401) {
      return response;
    }

    final refreshed = await refreshSession();
    if (!refreshed) return response;

    return await send(await _getHeaders(requireAuth: requireAuth));
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    return await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl$endpoint'), headers: headers),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    return await _sendWithRefresh(
      (headers) => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    return await _sendWithRefresh(
      (headers) => http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    return await _sendWithRefresh(
      (headers) =>
          http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers),
      requireAuth: requireAuth,
    );
  }

  /// Sube un archivo al bucket de InsForge Storage.
  /// Retorna {url, key} on success.
  Future<Map<String, String>?> uploadFile({
    required String bucket,
    required String filePath,
    required String objectKey,
  }) async {
    final contentType = _contentTypeForPath(filePath);
    if (contentType == null) {
      debugPrint('Storage upload failed: unsupported image type for $filePath');
      return null;
    }

    final file = await http.MultipartFile.fromPath('file', filePath);
    if (file.length > _maxUploadBytes) {
      debugPrint('Storage upload failed: file exceeds $_maxUploadBytes bytes');
      return null;
    }

    final strategyResponse = await post(
      '/api/storage/buckets/$bucket/upload-strategy',
      body: {
        'filename': objectKey,
        'contentType': contentType,
        'size': file.length,
      },
      requireAuth: true,
    );

    if (strategyResponse.statusCode < 200 ||
        strategyResponse.statusCode >= 300) {
      debugPrint(
        'Storage strategy failed (${strategyResponse.statusCode}): ${strategyResponse.body}',
      );
      return null;
    }

    final strategy = jsonDecode(strategyResponse.body) as Map<String, dynamic>;
    final method = strategy['method'] as String?;

    if (method == 'presigned') {
      return await _uploadWithPresignedStrategy(
        bucket: bucket,
        file: file,
        contentType: contentType,
        strategy: strategy,
      );
    }

    if (method != 'direct') {
      debugPrint('Storage upload failed: unsupported strategy $method');
      return null;
    }

    final uri = Uri.parse(
      '$baseUrl/api/storage/buckets/$bucket/objects/${Uri.encodeComponent(objectKey)}',
    );
    final request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(await _getHeaders(requireAuth: true));
    request.headers.remove('Content-Type');
    request.files.add(file);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _uploadResultFromBody(
        bucket: bucket,
        objectKey: objectKey,
        body: response.body,
      );
    }

    debugPrint(
      'Storage upload failed (${response.statusCode}): ${response.body}',
    );
    return null;
  }

  Future<Map<String, String>?> _uploadWithPresignedStrategy({
    required String bucket,
    required http.MultipartFile file,
    required String contentType,
    required Map<String, dynamic> strategy,
  }) async {
    final uploadUrl = strategy['uploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) return null;

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    final fields = strategy['fields'];
    if (fields is Map<String, dynamic>) {
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });
    }
    request.files.add(file);

    final streamedResponse = await request.send();
    final uploadResponse = await http.Response.fromStream(streamedResponse);
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      debugPrint(
        'Presigned storage upload failed (${uploadResponse.statusCode}): ${uploadResponse.body}',
      );
      return null;
    }

    final strategyKey = strategy['key'] as String?;
    if (strategy['confirmRequired'] == true &&
        strategy['confirmUrl'] is String) {
      final confirmUri = _resolveUri(strategy['confirmUrl'] as String);
      final confirmResponse = await http.post(
        confirmUri,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode({'size': file.length, 'contentType': contentType}),
      );

      if (confirmResponse.statusCode >= 200 &&
          confirmResponse.statusCode < 300) {
        return _uploadResultFromBody(
          bucket: bucket,
          objectKey: strategyKey ?? file.filename ?? 'avatar',
          body: confirmResponse.body,
        );
      }

      debugPrint(
        'Storage upload confirm failed (${confirmResponse.statusCode}): ${confirmResponse.body}',
      );
      return null;
    }

    final key = strategyKey ?? file.filename ?? 'avatar';
    return {'url': getPublicUrl(bucket, key), 'key': key};
  }

  Uri _resolveUri(String url) {
    final uri = Uri.parse(url);
    if (uri.hasScheme) return uri;
    return Uri.parse('$baseUrl$url');
  }

  Map<String, String> _uploadResultFromBody({
    required String bucket,
    required String objectKey,
    required String body,
  }) {
    Map<String, dynamic>? payload;
    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        payload = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
      }
    }

    final key = payload?['key'] as String? ?? objectKey;
    return {
      'url': payload?['url'] as String? ?? getPublicUrl(bucket, key),
      'key': key,
    };
  }

  String? _contentTypeForPath(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => null,
    };
  }

  /// Genera la URL pública de un objeto en Storage.
  String getPublicUrl(String bucket, String objectKey) {
    return '$baseUrl/api/storage/buckets/$bucket/objects/${Uri.encodeComponent(objectKey)}';
  }
}
