import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio global para gestionar el tema de la app (claro, oscuro, sistema).
///
/// Singleton con [ValueNotifier] para que los widgets escuchen cambios sin
/// necesidad de un state-management externo.
class ThemeService extends ValueNotifier<ThemeMode> {
  ThemeService._() : super(ThemeMode.light);

  static final ThemeService instance = ThemeService._();

  static const String _prefKey = 'theme_mode';

  /// Inicializa el servicio leyendo la preferencia persistida.
  /// Debe llamarse antes de runApp o en el initState del widget raíz.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    value = _fromString(stored);
  }

  /// Alterna entre claro y oscuro (ignora sistema).
  void toggle() {
    if (value == ThemeMode.dark) {
      setMode(ThemeMode.light);
    } else {
      setMode(ThemeMode.dark);
    }
  }

  /// Establece un modo específico y lo persiste.
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _toString(mode));
  }

  // ─── Helpers de serialización ───

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }
}
