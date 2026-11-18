import 'package:flutter/material.dart';

import '../tokens/app_elevation.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Panel fijo bajo la barra superior (p. ej. los filtros de una lista): no se
/// desplaza con la lista, que va debajo. Mide lo que su contenido, como mucho
/// [maxHeightFactor] de la pantalla; si no cabe (p. ej. con el texto al 200 %),
/// [child] se desplaza dentro del panel y [footer] queda siempre a la vista.
class AppPinnedPanel extends StatelessWidget {
  const AppPinnedPanel({super.key, required this.child, this.footer, this.maxHeightFactor = 0.5});

  final Widget child;

  /// Acciones al pie del panel (p. ej. «Restablecer» y «Listo»), fuera del
  /// desplazamiento.
  final Widget? footer;

  /// Fracción del alto de la pantalla que puede ocupar el panel.
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    final List<BoxShadow> shadow =
        Theme.of(context).brightness == Brightness.dark ? AppElevation.dark2 : AppElevation.light2;
    final Widget? footer = this.footer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        boxShadow: shadow,
        border: Border(bottom: BorderSide(color: colors.borderDefault, width: AppSizes.strokeThin)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.s300),
                  child: child,
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.md, AppSpacing.s300),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
