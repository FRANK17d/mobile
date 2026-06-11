import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipografico de Toke+
/// Usa Inter para UI y Poppins para headings
abstract final class AppTypography {
  // ─── Font Families (cached) ───
  static final String _headingFamily = GoogleFonts.poppins().fontFamily!;
  static final String _bodyFamily = GoogleFonts.inter().fontFamily!;

  // ─── Display ───
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -1.0,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.28,
    letterSpacing: -0.25,
  );

  // ─── Headings ───
  static TextStyle get headingLarge => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static TextStyle get headingMedium => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get headingSmall => TextStyle(
    fontFamily: _headingFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );

  // ─── Title ───
  static TextStyle get titleLarge => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  static TextStyle get titleSmall => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.38,
  );

  // ─── Body ───
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  // ─── Label ───
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ─── Caption ───
  static TextStyle get caption => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.4,
  );

  // ─── Button ───
  static TextStyle get buttonLarge => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonMedium => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.2,
  );
}
