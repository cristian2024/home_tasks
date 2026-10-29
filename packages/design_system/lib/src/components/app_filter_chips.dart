import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_choice_selector.dart';

/// Elegir varias opciones a la vez (p. ej. filtrar por categorías). Las
/// opciones pasan a la línea siguiente si no caben. Los lectores de pantalla
/// anuncian [label] y qué opciones están elegidas.
class AppFilterChips<T> extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.showLabel = true,
  });

  final String label;
  final List<AppChoice<T>> options;
  final Set<T> selected;

  /// Recibe la selección nueva al marcar o desmarcar una opción; `null`
  /// desactiva los chips.
  final ValueChanged<Set<T>>? onChanged;

  /// Si [label] se ve encima de los chips. Sin él, solo lo anuncian los
  /// lectores de pantalla.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<Set<T>>? onChanged = this.onChanged;
    return Semantics(
      label: label,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showLabel) ...<Widget>[
            ExcludeSemantics(
              child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final AppChoice<T> option in options)
                FilterChip(
                  label: Text(option.label),
                  avatar: option.icon == null ? null : Icon(option.icon),
                  showCheckmark: option.icon == null,
                  selected: selected.contains(option.value),
                  onSelected: onChanged == null
                      ? null
                      : (bool isSelected) => onChanged(
                            isSelected
                                ? <T>{...selected, option.value}
                                : <T>{for (final T value in selected) if (value != option.value) value},
                          ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
