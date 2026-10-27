import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Grilla desplazable de accesos rápidos ([AppShortcutTile]).
///
/// En móvil tiene [compactColumns] columnas; en pantallas más anchas, tantas
/// como quepan de [maxTileWidth] (nunca menos de [compactColumns]). Cada
/// casilla toma el alto que necesite, así un título de dos líneas o con texto
/// grande no se corta.
class AppShortcutGrid extends StatelessWidget {
  const AppShortcutGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  /// Ancho a partir del cual la grilla deja de ser la de móvil.
  static const double compactBreakpoint = 600.0;
  static const int compactColumns = 4;
  static const double maxTileWidth = 140.0;

  final List<Widget> children;
  final EdgeInsets padding;

  /// Columnas para un ancho disponible de [width].
  static int columnsFor(double width) =>
      width < compactBreakpoint ? compactColumns : math.max(compactColumns, width ~/ maxTileWidth);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = columnsFor(constraints.maxWidth);
          final double tileWidth = ((constraints.maxWidth - padding.horizontal) / columns).floorToDouble();
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
