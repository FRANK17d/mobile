import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sombras y elevaciones para Toke+
abstract final class AppShadows {
  // ─── Card Shadows ───
  static List<BoxShadow> get none => [];

  static List<BoxShadow> get xs => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Specific Component Shadows ───
  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.30),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get topBar => [
    BoxShadow(
      color: AppColors.neutral900.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
