import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Grid responsivo que ajusta el numero de columnas segun el breakpoint.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.largeColumns = 4,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final int largeColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);
    final columns = switch (breakpoint) {
      Breakpoint.compact => compactColumns,
      Breakpoint.medium => mediumColumns,
      Breakpoint.expanded => expandedColumns,
      Breakpoint.large => largeColumns,
    };

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Wrapper que limita el ancho del contenido en tablets.
/// En movil ocupa todo el ancho. En tablet se centra con un maxWidth.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint.of(context);
    final effectiveMaxWidth = maxWidth ?? breakpoint.maxContentWidth;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(horizontal: breakpoint.screenPadding);

    if (effectiveMaxWidth == null) {
      return Padding(
        padding: effectivePadding,
        child: child,
      );
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
