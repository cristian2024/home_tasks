import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_touch_target.dart';
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
              child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: AppThemeColors.of(context).textPrimary)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Con 12 entre filas, las áreas de 48 de chips de 36 no se solapan.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.s300,
            children: <Widget>[
              for (final AppChoice<T> option in options)
                AppTouchTarget(
                  // 36 de alto, como en el diseño; el texto grande lo hace crecer.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.controlCompact),
                    child: FilterChip(
                    label: Text(option.label),
                    avatar: option.icon == null ? null : Icon(option.icon),
                    labelPadding: selected.contains(option.value) ? const EdgeInsets.only(left: AppSpacing.xs) : EdgeInsets.zero,
                    showCheckmark: option.icon == null,
                    selected: selected.contains(option.value),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: onChanged == null
                        ? null
                        : (bool isSelected) => onChanged(
                              isSelected
                                  ? <T>{...selected, option.value}
                                  : <T>{for (final T value in selected) if (value != option.value) value},
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
