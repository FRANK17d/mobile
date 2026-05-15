import 'package:flutter/widgets.dart';

/// Breakpoints del sistema adaptivo de Toke+
/// Basados en las guias de Material Design 3
enum Breakpoint {
  /// Telefonos pequenos (< 360dp) - iPhone SE, etc.
  compact(0, 359),

  /// Telefonos normales (360-599dp) - Mayoria de dispositivos
  medium(360, 599),

  /// Tablets pequenas, foldables (600-839dp)
  expanded(600, 839),

  /// Tablets grandes, iPad Pro (840dp+)
  large(840, double.infinity);

  const Breakpoint(this.minWidth, this.maxWidth);

  final double minWidth;
  final double maxWidth;

  /// Obtiene el breakpoint actual segun el ancho de pantalla
  static Breakpoint fromWidth(double width) {
    if (width < 360) return Breakpoint.compact;
    if (width < 600) return Breakpoint.medium;
    if (width < 840) return Breakpoint.expanded;
    return Breakpoint.large;
  }

  /// Obtiene el breakpoint desde el BuildContext
  static Breakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  /// Helpers de comparacion
  bool get isCompact => this == Breakpoint.compact;
  bool get isMedium => this == Breakpoint.medium;
  bool get isExpanded => this == Breakpoint.expanded;
  bool get isLarge => this == Breakpoint.large;

  /// Helpers de rango
  bool get isMobile => this == Breakpoint.compact || this == Breakpoint.medium;
  bool get isTablet => this == Breakpoint.expanded || this == Breakpoint.large;

  /// Numero de columnas recomendado para grids
  int get gridColumns {
    return switch (this) {
      Breakpoint.compact => 2,
      Breakpoint.medium => 2,
      Breakpoint.expanded => 3,
      Breakpoint.large => 4,
    };
  }

  /// Padding horizontal de pantalla
  double get screenPadding {
    return switch (this) {
      Breakpoint.compact => 16.0,
      Breakpoint.medium => 20.0,
      Breakpoint.expanded => 24.0,
      Breakpoint.large => 32.0,
    };
  }

  /// Ancho maximo de contenido (para centrar en tablets)
  double? get maxContentWidth {
    return switch (this) {
      Breakpoint.compact => null,
      Breakpoint.medium => null,
      Breakpoint.expanded => 680.0,
      Breakpoint.large => 900.0,
    };
  }
}
