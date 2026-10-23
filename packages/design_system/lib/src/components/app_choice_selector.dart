import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Opción de un [AppChoiceSelector].
class AppChoice<T> {
  const AppChoice({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Elegir una opción entre pocas (tema, idioma…). Las opciones pasan a la
/// línea siguiente si no caben, así que no desborda con el texto ampliado.
/// Los lectores de pantalla anuncian [label] y qué opción está elegida.
class AppChoiceSelector<T> extends StatelessWidget {
  const AppChoiceSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final List<AppChoice<T>> options;
  final T selected;

  /// Se llama al elegir una opción distinta de [selected]; `null` desactiva
  /// el selector.
  final ValueChanged<T>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<T>? onChanged = this.onChanged;
    final IconData? icon = this.icon;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: label,
            container: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final AppChoice<T> option in options)
                  ChoiceChip(
                    label: Text(option.label),
                    avatar: option.icon == null ? null : Icon(option.icon),
                    showCheckmark: option.icon == null,
                    selected: option.value == selected,
                    onSelected: onChanged == null
                        ? null
                        : (bool _) {
                            if (option.value != selected) {
                              onChanged(option.value);
                            }
                          },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
