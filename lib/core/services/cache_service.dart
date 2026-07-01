import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de cache local para soporte offline basico.
/// Guarda respuestas JSON con TTL configurable.
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  static const String _prefix = 'cache_';
  static const String _metaPrefix = 'cache_meta_';
  static const Duration defaultTtl = Duration(minutes: 30);

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Guarda datos en cache con TTL.
  Future<void> set(String key, dynamic data, {Duration? ttl}) async {
    final prefs = await _storage;
    final jsonStr = jsonEncode(data);
    final expiresAt = DateTime.now().add(ttl ?? defaultTtl).millisecondsSinceEpoch;

    await prefs.setString('$_prefix$key', jsonStr);
    await prefs.setInt('$_metaPrefix$key', expiresAt);
  }

  /// Obtiene datos del cache. Retorna null si expiró o no existe.
  Future<T?> get<T>(String key) async {
    final prefs = await _storage;
    final expiresAt = prefs.getInt('$_metaPrefix$key');

    if (expiresAt == null || DateTime.now().millisecondsSinceEpoch > expiresAt) {
      // Expirado o inexistente
      await remove(key);
      return null;
    }

    final jsonStr = prefs.getString('$_prefix$key');
    if (jsonStr == null) return null;

    try {
      return jsonDecode(jsonStr) as T;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene datos del cache, o ejecuta [fetcher] y guarda el resultado.
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final cached = await get<T>(key);
    if (cached != null) return cached;

    final fresh = await fetcher();
    await set(key, fresh, ttl: ttl);
    return fresh;
  }

  /// Elimina una entrada del cache.
  Future<void> remove(String key) async {
    final prefs = await _storage;
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_metaPrefix$key');
  }

  /// Limpia todo el cache.
  Future<void> clear() async {
    final prefs = await _storage;
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_prefix) || k.startsWith(_metaPrefix),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
