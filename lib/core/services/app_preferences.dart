import 'package:shared_preferences/shared_preferences.dart';

/// Servicio simple para flags persistentes de la app.
class AppPreferences {
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyShowProviderGuide = 'show_provider_guide';
  static const _keyReceiveOrders = 'tech_receive_orders';
  static const _keyProfileVisible = 'tech_profile_visible';

  /// Devuelve `true` si el usuario ya completó el onboarding.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Marca el onboarding como completado.
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// Indica si se debe mostrar la guía del prestador.
  /// Por defecto es `false` para que no se muestre en logins tras reinstalar.
  /// Solo se debe poner a `true` inmediatamente después de un registro exitoso.
  static Future<bool> shouldShowProviderGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowProviderGuide) ?? false;
  }

  /// Configura si se debe mostrar la guía del prestador.
  static Future<void> setShouldShowProviderGuide(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowProviderGuide, value);
  }

  /// Indica si el técnico está configurado para recibir nuevos pedidos.
  /// Por defecto `true`: una cuenta nueva recibe pedidos hasta que decida lo
  /// contrario.
  static Future<bool> isReceivingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReceiveOrders) ?? true;
  }

  /// Activa o desactiva la recepción de nuevos pedidos.
  static Future<void> setReceivingOrders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReceiveOrders, value);
  }

  /// Indica si el perfil del técnico es visible para los clientes.
  /// Por defecto `true`: el perfil arranca visible tras el registro.
  static Future<bool> isProfileVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyProfileVisible) ?? true;
  }

  /// Cambia la visibilidad del perfil del técnico.
  static Future<void> setProfileVisible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfileVisible, value);
  }
}
