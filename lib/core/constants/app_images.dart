/// Rutas de assets de la app Toke+
///
/// Todas las imagenes usan WebP con variantes de resolucion:
///   1x (base) → assets/images/
///   2x        → assets/images/2.0x/
///   3x        → assets/images/3.0x/
/// Flutter selecciona la variante correcta automaticamente.
abstract final class AppImages {
  static const String _basePath = 'assets/images';
  static const String _onboardingPath = 'assets/images/onboarding';
  static const String _iconsPath = 'assets/icons';

  // ─── Logo ───
  static const String logo = '$_basePath/toke_logo.webp';
  static const String logoTextSvg = '$_iconsPath/toke_logo_text.svg';

  // ─── Mascota ───
  static const String mascot = '$_iconsPath/mascot.svg';

  // ─── Moneda / créditos ───
  static const String tokeCoin = '$_basePath/moneda-toke.webp';
  static const String coinPackSmall = '$_basePath/moneda1.webp';
  static const String coinPackMedium = '$_basePath/moneda2.webp';
  static const String coinPackLarge = '$_basePath/moneda3.webp';
  static const String walletCredits = '$_basePath/billetera.webp';

  // ─── Onboarding (5 paginas) ───
  static const String onboarding1 = '$_onboardingPath/onboarding_1.webp';
  static const String onboarding2 = '$_onboardingPath/onboarding_2.webp';
  static const String onboarding3 = '$_onboardingPath/onboarding_3.webp';
  static const String onboarding4 = '$_onboardingPath/onboarding_4.webp';
  static const String onboarding5 = '$_onboardingPath/onboarding_5.webp';

  // ─── Cómo funciona (pantalla "¿Cómo funciona Toke+?") ───
  // TODO: Reemplazar por las imágenes reales (las de las capturas adjuntas).
  //       Hasta entonces se muestra un placeholder automático.
  static const String _howItWorksPath = '$_basePath/how_it_works';
  static const String hiwStep1 = '$_howItWorksPath/paso_1.webp';
  static const String hiwStep2 = '$_howItWorksPath/paso_2.webp';
  static const String hiwStep3 = '$_howItWorksPath/paso_3.webp';
  static const String hiwTrust = '$_howItWorksPath/buscar_soluciones.webp';
  static const String hiwOrderBasic = '$_howItWorksPath/pedido_basico.webp';
  static const String hiwOrderExclusive =
      '$_howItWorksPath/pedido_exclusivo.webp';

  // ─── Placeholders ───
  // TODO: Agregar estos assets cuando se necesiten
  // static const String avatarPlaceholder = '$_basePath/avatar_placeholder.webp';
  // static const String emptyState = '$_basePath/empty_state.webp';
}
