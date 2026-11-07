import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Grilla desplazable de accesos rápidos ([AppShortcutTile]).
///
/// Tiene tantas columnas como quepan de [minTileWidth] (nunca menos de
/// [minColumns]), así que se adapta a cualquier ancho. Cada casilla toma el
/// alto que necesite, así un título de dos líneas o con texto grande no se
/// corta.
class AppShortcutGrid extends StatelessWidget {
  const AppShortcutGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  static const int minColumns = 2;
  static const double minTileWidth = 114.0;

  final List<Widget> children;
  final EdgeInsets padding;

  /// Columnas para [width], el ancho sin los márgenes.
  static int columnsFor(double width) => math.max(minColumns, width ~/ minTileWidth);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth - padding.horizontal;
          final int columns = columnsFor(width);
          final double tileWidth = (width / columns).floorToDouble();
          return SingleChildScrollView(
            padding: padding,
            child: Wrap(
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (final Widget child in children) SizedBox(width: tileWidth, child: child),
              ],
            ),
          );
        },
      );
}
