import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static const tablet = 700.0;
  static const desktop = 1024.0;
  static const contentMaxWidth = 1120.0;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static int columnsFor(double width, {double minTileWidth = 320}) {
    return (width / minTileWidth).floor().clamp(1, 3);
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 320,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveLayout.columnsFor(
          constraints.maxWidth,
          minTileWidth: minTileWidth,
        );
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
