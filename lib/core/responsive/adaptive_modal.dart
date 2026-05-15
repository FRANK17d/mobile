import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Muestra un BottomSheet en movil o un Dialog en tablet.
/// Se adapta automaticamente al tamano de pantalla.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  double? maxDialogWidth,
}) {
  final breakpoint = Breakpoint.of(context);

  if (breakpoint.isTablet) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth ?? 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: builder(context),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => builder(context),
    ),
  );
}
