import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_touch_target.dart';

/// Opción de un [AppChoiceSelector].
class AppChoice<T> {
  const AppChoice({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Elegir una opción entre pocas (tema, idioma…) con un control segmentado. Las
/// opciones van en una fila, con el icono o la marca solo si caben. Si ni el
/// texto cabe (etiquetas largas o texto ampliado), se apilan, así que no
/// desborda. Los lectores de pantalla anuncian [label] y qué opción está
/// elegida.
class AppChoiceSelector<T> extends StatelessWidget {
  const AppChoiceSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.showLabel = true,
    this.wrapLabels = false,
  });

  final String label;
  final List<AppChoice<T>> options;
  final T selected;

  /// Se llama al elegir una opción distinta de [selected]; `null` desactiva
  /// el selector.
  final ValueChanged<T>? onChanged;
  final IconData? icon;

  /// Margen alrededor del selector. Dentro de una tarjeta o de una fila de
  /// ajustes conviene el de por defecto; suelto en una pantalla, `EdgeInsets.zero`.
  final EdgeInsetsGeometry padding;

  /// Con `false`, [label] solo lo anuncian los lectores de pantalla.
  final bool showLabel;

  /// Con `true`, las etiquetas que no caben se parten en dos líneas en lugar
  /// de apilar las opciones.
  final bool wrapLabels;

  double _widestLabel(BuildContext context) {
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
    return widestLabel;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<T>? onChanged = this.onChanged;
    final IconData? icon = this.icon;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showLabel) ...<Widget>[
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
          ],
          Semantics(
            label: label,
            container: true,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.small),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double cellWidth = constraints.maxWidth / options.length;
                  final double widestLabel = _widestLabel(context);
                  final bool fitsInRow = wrapLabels || widestLabel + AppChoiceSegment.textPadding <= cellWidth;
                  const Radius corner = Radius.circular(AppRadii.small);
                  final List<AppChoiceSegment> segments = <AppChoiceSegment>[
                    for (final (int index, AppChoice<T> option) in options.indexed)
                      AppChoiceSegment(
                        label: option.label,
                        borderRadius: BorderRadius.only(
                          topLeft: index == 0 ? corner : Radius.zero,
                          topRight: (fitsInRow ? index == options.length - 1 : index == 0) ? corner : Radius.zero,
                          bottomLeft: (fitsInRow ? index == 0 : index == options.length - 1) ? corner : Radius.zero,
                          bottomRight: index == options.length - 1 ? corner : Radius.zero,
                        ),
                        icon: option.icon,
                        selected: option.value == selected,
                        showIcon: widestLabel + AppChoiceSegment.textPadding + AppChoiceSegment.iconWidth <= cellWidth,
                        onTap: onChanged == null
                            ? null
                            : () {
                                if (option.value != selected) {
                                  onChanged(option.value);
                                }
                              },
                      ),
                  ];
                  if (fitsInRow) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final (int index, AppChoiceSegment segment) in segments.indexed) ...<Widget>[
                            if (index > 0) const VerticalDivider(width: AppSizes.strokeThin),
                            Expanded(child: segment),
                          ],
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final (int index, AppChoiceSegment segment) in segments.indexed) ...<Widget>[
                        if (index > 0) const Divider(height: AppSizes.strokeThin),
                        segment,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una opción de [AppChoiceSelector]. La elegida muestra su icono o, sin él, una
/// marca de verificación, salvo con [showIcon] en `false`, donde solo cambia de
/// color: se anuncia igualmente como seleccionada.
class AppChoiceSegment extends StatelessWidget {
  const AppChoiceSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.showIcon = true,
    this.borderRadius = BorderRadius.zero,
  });

  /// Lo que ocupa una opción, además de su texto: márgenes y separador.
  static const double textPadding = AppSpacing.sm * 2 + AppSizes.strokeThin;

  /// Lo que añaden el icono y su separación.
  static const double iconWidth = AppSizes.iconSmall + AppSpacing.s150;

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showIcon;

  /// Esquinas de la opción: las de los extremos siguen el borde del selector.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final AppThemeColors colors = AppThemeColors.of(context);
    final IconData? leading = showIcon ? icon ?? (selected ? AppIcons.check : null) : null;
    final Color foreground = switch ((onTap != null, selected)) {
      (false, _) => colors.textDisabled,
      (true, true) => colors.textBrand,
      (true, false) => colors.textSecondary,
    };
    return AppTouchTarget(
      child: Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? colors.bgBrandSubtle : Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
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
      ),
    );
  }
}
