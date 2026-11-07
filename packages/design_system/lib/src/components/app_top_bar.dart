import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

/// Barra superior de una pantalla. Con flecha atrás, el título empieza justo
/// después de ella; sin flecha, en el margen de la pantalla.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title, this.actions, this.leading});

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final bool hasLeading = leading != null || (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
    // El contenido va más cerca del pie de la barra que de su borde superior.
    // AppBar centra su fila: el hueco extra se añade como margen superior.
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(padding: media.padding.copyWith(top: media.padding.top + AppSpacing.sm)),
      child: AppBar(
        toolbarHeight: AppSizes.topBarHeight - AppSpacing.sm,
        leading: leading,
        title: title,
        titleSpacing: hasLeading ? AppSpacing.s0 : AppSpacing.md,
        actions: actions,
      ),
    );
  }
}
