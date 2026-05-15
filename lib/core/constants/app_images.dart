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

  // ─── Logo ───
  static const String logo = '$_basePath/toke_logo.webp';

  // ─── Onboarding (5 paginas) ───
  static const String onboarding1 = '$_onboardingPath/onboarding_1.webp';
  static const String onboarding2 = '$_onboardingPath/onboarding_2.webp';
  static const String onboarding3 = '$_onboardingPath/onboarding_3.webp';
  static const String onboarding4 = '$_onboardingPath/onboarding_4.webp';
  static const String onboarding5 = '$_onboardingPath/onboarding_5.webp';

  // ─── Placeholders ───
  // TODO: Agregar estos assets cuando se necesiten
  // static const String avatarPlaceholder = '$_basePath/avatar_placeholder.webp';
  // static const String emptyState = '$_basePath/empty_state.webp';
}
