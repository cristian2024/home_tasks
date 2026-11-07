import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import 'app_icon_box.dart';

/// Acceso rápido: icono destacado con su título debajo, pensado para
/// [AppShortcutGrid].
///
/// Sin [icon] muestra [fallbackIcon]. El título se corta en dos líneas. Con
/// [error] se pinta con los colores de error; [tooltip] explica el motivo.
/// Para los lectores de pantalla es un único botón con el título.
class AppShortcutTile extends StatelessWidget {
  const AppShortcutTile({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.tooltip,
    this.error = false,
  });

  static const IconData fallbackIcon = AppIcons.layoutGrid;

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? tooltip = this.tooltip;
    final Widget tile = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIconBox(icon: icon ?? fallbackIcon, error: error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? tile : Tooltip(message: tooltip, child: tile);
  }
}
