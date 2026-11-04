import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';

/// Opción de un [AppChoiceSelector].
class AppChoice<T> {
  const AppChoice({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Elegir una opción entre pocas (tema, idioma…) con un control segmentado. Si
/// las opciones no caben en una fila (etiquetas largas o texto ampliado), se
/// apilan, así que no desborda. Los lectores de pantalla anuncian [label] y qué
/// opción está elegida.
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

  bool _fitsInRow(BuildContext context, double width) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final TextStyle? style = Theme.of(context).textTheme.labelLarge;
    double widestLabel = 0;
    for (final AppChoice<T> option in options) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: option.label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widestLabel = math.max(widestLabel, painter.width);
      painter.dispose();
    }
    return (widestLabel + AppChoiceSegment.chromeWidth) * options.length <= width;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<T>? onChanged = this.onChanged;
    final IconData? icon = this.icon;
    final List<AppChoiceSegment> segments = <AppChoiceSegment>[
      for (final AppChoice<T> option in options)
        AppChoiceSegment(
          label: option.label,
          icon: option.icon,
          selected: option.value == selected,
          onTap: onChanged == null
              ? null
              : () {
                  if (option.value != selected) {
                    onChanged(option.value);
                  }
                },
        ),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: label,
            container: true,
            child: Material(
              type: MaterialType.transparency,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.small),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) => _fitsInRow(context, constraints.maxWidth)
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (final (int index, AppChoiceSegment segment) in segments.indexed) ...<Widget>[
                              if (index > 0) const VerticalDivider(width: AppSizes.strokeThin),
                              Expanded(child: segment),
                            ],
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final (int index, AppChoiceSegment segment) in segments.indexed) ...<Widget>[
                            if (index > 0) const Divider(height: AppSizes.strokeThin),
                            segment,
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opción de [AppChoiceSelector]. La elegida muestra su icono o, sin él, una
/// marca de verificación.
class AppChoiceSegment extends StatelessWidget {
  const AppChoiceSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  /// Lo que ocupa una opción, además de su texto: márgenes, icono y separación.
  static const double chromeWidth = AppSpacing.sm * 2 + AppSizes.iconSmall + AppSpacing.s150 + AppSizes.strokeThin;

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    final IconData? leading = icon ?? (selected ? Icons.check : null);
    final Color foreground = switch ((onTap != null, selected)) {
      (false, _) => colors.textDisabled,
      (true, true) => colors.textBrand,
      (true, false) => colors.textSecondary,
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? colors.bgBrandSubtle : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    ExcludeSemantics(child: Icon(leading, size: AppSizes.iconSmall, color: foreground)),
                    const SizedBox(width: AppSpacing.s150),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
