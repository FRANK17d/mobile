import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Layout master-detail adaptivo.
/// En movil: solo muestra el master (lista).
/// En tablet: split panel con lista a la izquierda y detalle a la derecha.
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.detailPlaceholder,
    this.masterWidth = 360,
    this.showDivider = true,
  });

  /// Panel izquierdo (lista)
  final Widget master;

  /// Panel derecho (detalle) - null si no hay item seleccionado
  final Widget? detail;

  /// Widget a mostrar cuando no hay detalle seleccionado (solo tablet)
  final Widget? detailPlaceholder;

  /// Ancho del panel master en tablet
  final double masterWidth;

  /// Mostrar divisor entre paneles
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);

    if (breakpoint.isMobile) {
      return master;
    }

    // Tablet: split layout
    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        if (showDivider) const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child:
              detail ??
              detailPlaceholder ??
              const Center(child: Text('Selecciona un elemento')),
        ),
      ],
    );
  }
}
