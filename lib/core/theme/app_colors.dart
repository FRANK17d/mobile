import 'package:flutter/material.dart';

/// Paleta de colores de Toke+
/// Rojo suave del logo tk+ como color primario
abstract final class AppColors {
  // ─── Brand Primary (Rojo suave Toke+) ───
  static const Color primary = Color(0xFFEE7070);
  static const Color primaryLight = Color(0xFFF4A0A0);
  static const Color primaryDark = Color(0xFFD94F4F);
  static const Color primarySurface = Color(0xFFFFF5F5);

  // ─── Gradient Onboarding ───
  static const Color gradientStart = Color(0xFFEE7070);
  static const Color gradientEnd = Color(0xFFE85555);

  // ─── Secondary (Azul oscuro profesional) ───
  static const Color secondary = Color(0xFF1A2B4A);
  static const Color secondaryLight = Color(0xFF2D4470);
  static const Color secondaryDark = Color(0xFF0F1A2E);

  // ─── Neutral ───
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF2E2E2E);
  static const Color neutral700 = Color(0xFF424242);
  static const Color neutral600 = Color(0xFF616161);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);

  // ─── Semantic ───
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFE8F8EF);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF5E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEB);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);

  // ─── Background ───
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color backgroundTertiary = Color(0xFFF0F2F5);

  // ─── Surface ───
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceOverlay = Color(0x80000000);

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Border ───
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderFocused = Color(0xFFEE7070);

  // ─── Rating ───
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // ─── Dark Theme Overrides ───
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkTextTertiary = Color(0xFF757575);
}
