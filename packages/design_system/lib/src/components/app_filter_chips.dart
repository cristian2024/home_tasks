import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_choice_selector.dart';
import 'app_focus_ring.dart';
import 'app_touch_target.dart';

/// Elegir varias opciones a la vez (p. ej. filtrar por categorías). Las
/// opciones pasan a la línea siguiente si no caben. Los lectores de pantalla
/// anuncian [label] y qué opciones están elegidas.
///
/// Con [maxVisible], solo se ven las primeras y un chip más, con el texto de
/// [moreLabel], muestra el resto. Si alguna de las ocultas está elegida, se ven
/// todas desde el principio.
class AppFilterChips<T> extends StatefulWidget {
  const AppFilterChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.showLabel = true,
    this.maxVisible,
    this.moreLabel,
  }) : assert(maxVisible == null || moreLabel != null, 'maxVisible necesita moreLabel');

  final String label;
  final List<AppChoice<T>> options;
  final Set<T> selected;

  /// Recibe la selección nueva al marcar o desmarcar una opción; `null`
  /// desactiva los chips.
  final ValueChanged<Set<T>>? onChanged;

  /// Si [label] se ve encima de los chips. Sin él, solo lo anuncian los
  /// lectores de pantalla.
  final bool showLabel;

  /// Cuántas opciones se ven antes de desplegar el resto; `null` las muestra
  /// todas.
  final int? maxVisible;

  /// Texto del chip que despliega las ocultas, a partir de cuántas son (p. ej.
  /// «2 más»).
  final String Function(int hidden)? moreLabel;

  @override
  State<AppFilterChips<T>> createState() => _AppFilterChipsState<T>();
}

class _AppFilterChipsState<T> extends State<AppFilterChips<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<Set<T>>? onChanged = widget.onChanged;
    final List<AppChoice<T>> options = widget.options;
    final Set<T> selected = widget.selected;
    final int? maxVisible = widget.maxVisible;
    final bool hiddenSelected = maxVisible != null &&
        options.skip(maxVisible).any((AppChoice<T> option) => selected.contains(option.value));
    final bool collapsed = maxVisible != null && options.length > maxVisible && !_expanded && !hiddenSelected;
    final List<AppChoice<T>> visible = collapsed ? options.take(maxVisible).toList() : options;
    final String Function(int hidden)? moreLabel = widget.moreLabel;
    return Semantics(
      label: widget.label,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.showLabel) ...<Widget>[
            ExcludeSemantics(
              child: Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(color: AppThemeColors.of(context).textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Con 12 entre filas, las áreas de 48 de chips de 36 no se solapan.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.s300,
            children: <Widget>[
              for (final AppChoice<T> option in visible)
                _ChipFrame(
                  child: FilterChip(
                    label: Text(option.label),
                    avatar: option.icon == null ? null : Icon(option.icon),
                    labelPadding:
                        selected.contains(option.value) ? const EdgeInsets.only(left: AppSpacing.xs) : EdgeInsets.zero,
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
              if (collapsed && moreLabel != null)
                _ChipFrame(
                  child: Semantics(
                    expanded: false,
                    child: ActionChip(
                      label: Text(moreLabel(options.length - maxVisible)),
                      labelPadding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: () => setState(() => _expanded = true),
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

/// Un chip de 36 de alto, como en el diseño (el texto grande lo hace crecer),
/// con 48 de área táctil y el anillo de foco por fuera.
class _ChipFrame extends StatelessWidget {
  const _ChipFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppTouchTarget(
        child: AppFocusRing(
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.controlCompact),
            child: child,
          ),
        ),
      );
}
