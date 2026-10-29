import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

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
    final ValueChanged<bool>? onChanged = this.onChanged;
    final String? subtitle = this.subtitle;
    return ListTile(
      leading: Checkbox(
        value: value,
        semanticLabel: checkboxLabel,
        onChanged: onChanged == null ? null : (bool? checked) => onChanged(checked ?? false),
      ),
      title: Text(
        title,
        style: value
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: subtitle == null && badges.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (subtitle != null) Text(subtitle),
                if (badges.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: badges),
                ],
              ],
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
