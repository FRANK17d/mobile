import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

/// Widget builder que reconstruye la UI segun el breakpoint actual.
///
/// Uso:
/// ```dart
/// ResponsiveBuilder(
///   compact: (context) => MobileLayout(),
///   medium: (context) => MobileLayout(),   // opcional, hereda compact
///   expanded: (context) => TabletLayout(),
///   large: (context) => TabletLayout(),     // opcional, hereda expanded
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  /// Layout para telefonos pequenos (requerido, es el fallback)
  final WidgetBuilder compact;

  /// Layout para telefonos normales (opcional, usa compact si no se provee)
  final WidgetBuilder? medium;

  /// Layout para tablets (opcional, usa medium/compact si no se provee)
  final WidgetBuilder? expanded;

  /// Layout para tablets grandes (opcional, usa expanded si no se provee)
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    return switch (breakpoint) {
      Breakpoint.large => (large ?? expanded ?? medium ?? compact)(context),
      Breakpoint.expanded => (expanded ?? medium ?? compact)(context),
      Breakpoint.medium => (medium ?? compact)(context),
      Breakpoint.compact => compact(context),
    };
  }
}

/// Devuelve un valor segun el breakpoint actual.
///
/// Uso:
/// ```dart
/// final columns = responsiveValue<int>(
///   context,
///   compact: 1,
///   medium: 2,
///   expanded: 3,
///   large: 4,
/// );
/// ```
T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
  T? large,
}) {
  final breakpoint = Breakpoint.of(context);

  return switch (breakpoint) {
    Breakpoint.large => large ?? expanded ?? medium ?? compact,
    Breakpoint.expanded => expanded ?? medium ?? compact,
    Breakpoint.medium => medium ?? compact,
    Breakpoint.compact => compact,
  };
}
