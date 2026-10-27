import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

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

  static const IconData fallbackIcon = Icons.extension_outlined;

  /// Lado del recuadro del icono.
  static const double iconBoxSize = 56.0;

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? tooltip = this.tooltip;
    final Widget tile = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: error ? colors.errorContainer : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                  ),
                  child: Icon(
                    icon ?? fallbackIcon,
                    size: AppSizes.iconMedium,
                    color: error ? colors.onErrorContainer : colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
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
