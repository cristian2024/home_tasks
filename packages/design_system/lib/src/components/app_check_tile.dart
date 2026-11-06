import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_touch_target.dart';

/// Fila de una lista que se marca como hecha (p. ej. comprado) con su
/// casilla. Un toque en el resto de la fila llama a [onTap] (p. ej. editar).
///
/// Marcada, el título se tacha. [badges] se muestran bajo el subtítulo.
class AppCheckTile extends StatelessWidget {
  const AppCheckTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.checkboxLabel,
    this.subtitle,
    this.badges = const <Widget>[],
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Si está marcada.
  final bool value;

  /// Recibe el valor nuevo al tocar la casilla; `null` la desactiva.
  final ValueChanged<bool>? onChanged;

  /// Lo que anuncian los lectores de pantalla para la casilla (p. ej.
  /// «Marcar como comprado»).
  final String checkboxLabel;

  final List<Widget> badges;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final ValueChanged<bool>? onChanged = this.onChanged;
    final String? subtitle = this.subtitle;
    final Widget? trailing = this.trailing;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.s300),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s300,
          children: <Widget>[
            _SizedCheckbox(
              child: Checkbox(
                value: value,
                semanticLabel: checkboxLabel,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged == null ? null : (bool? checked) => onChanged(checked ?? false),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: value ? colors.textTertiary : colors.textPrimary,
                      decoration: value ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                  if (badges.isNotEmpty) Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: badges),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Dibuja una casilla de Material a [AppSizes.iconMedium], con el área táctil
/// completa.
class _SizedCheckbox extends StatelessWidget {
  const _SizedCheckbox({required this.child});

  /// Tamaño con el que Material dibuja la casilla.
  static const double _materialSize = 18.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => AppTouchTarget(
        child: SizedBox.square(
          dimension: AppSizes.iconMedium,
          child: OverflowBox(
            maxWidth: AppSizes.minTouchTarget,
            maxHeight: AppSizes.minTouchTarget,
            child: Transform.scale(scale: AppSizes.iconMedium / _materialSize, child: child),
          ),
        ),
      );
}
