import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InsForgeClient {
  static const String baseUrl = 'https://439t8drp.us-east.insforge.app';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNTI1Nzd9.2dOzij2zno-SbyaGf43n_txtfgMgjXviPeoKjHJftXQ';
  
  final _storage = const FlutterSecureStorage();
  
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

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

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

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint, {dynamic body, bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {dynamic body, bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }
}
