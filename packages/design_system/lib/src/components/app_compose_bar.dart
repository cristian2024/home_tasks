import 'package:flutter/material.dart';

import '../tokens/app_elevation.dart';
import '../tokens/app_icons.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_choice_selector.dart';
import 'app_focus_ring.dart';
import 'app_icon_button.dart';
import 'app_touch_target.dart';
import 'field_error.dart';

/// Barra para crear elementos seguidos desde una lista, justo encima del
/// teclado: cabecera con [label] y Cerrar (arriba, lejos de Enviar), el campo y
/// Enviar. Intro también envía. Tras [onSubmitted], quien la usa decide si
/// vacía el campo (con su [controller]); el foco se queda en él.
///
/// Con [destinations], debajo del campo se ve a dónde irá lo nuevo
/// ([destinationLabel] y un chip con la opción elegida). Al tocar el chip se
/// despliegan las opciones sin cerrar el teclado: el campo conserva el foco
/// real y el chip se marca como activo. Al elegir, se cierran y el foco vuelve
/// al campo. Con [errorText], el error sustituye a esa línea.
class AppComposeBar<T> extends StatefulWidget {
  const AppComposeBar({
    super.key,
    required this.label,
    required this.controller,
    required this.onSubmitted,
    required this.submitTooltip,
    required this.onClose,
    required this.closeTooltip,
    this.focusNode,
    this.hint,
    this.errorText,
    this.destinationLabel,
    this.destinations = const <Never>[],
    this.selectedDestination,
    this.onDestinationChanged,
    this.destinationSemanticLabel,
  });

  /// Etiqueta visible del campo (p. ej. «Nombre del ítem nuevo»).
  final String label;
  final TextEditingController controller;

  /// Recibe el texto al pulsar Enviar o Intro.
  final ValueChanged<String> onSubmitted;
  final String submitTooltip;
  final VoidCallback onClose;
  final String closeTooltip;

  /// Foco del campo; sin él, la barra crea uno. Al montarse, el campo lo pide.
  final FocusNode? focusNode;
  final String? hint;
  final String? errorText;

  /// Texto delante del chip de destino (p. ej. «Se añadirá a»).
  final String? destinationLabel;

  /// Opciones de destino; vacía, no se muestra la línea de destino.
  final List<AppChoice<T>> destinations;
  final T? selectedDestination;
  final ValueChanged<T>? onDestinationChanged;

  /// Lo que leen los lectores de pantalla para el chip (p. ej. «Categoría del
  /// ítem nuevo: Comida. Cambiar»).
  final String? destinationSemanticLabel;

  @override
  State<AppComposeBar<T>> createState() => _AppComposeBarState<T>();
}

class _AppComposeBarState<T> extends State<AppComposeBar<T>> {
  FocusNode? _ownFocusNode;
  bool _choosing = false;

  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode(debugLabel: 'AppComposeBar'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmitted(widget.controller.text);
    _focusNode.requestFocus();
  }

  void _choose(T value) {
    setState(() => _choosing = false);
    widget.onDestinationChanged?.call(value);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final AppThemeColors colors = AppThemeColors.of(context);
    final List<BoxShadow> shadow = theme.brightness == Brightness.dark ? AppElevation.dark2 : AppElevation.light2;
    final String? errorText = widget.errorText;
    final List<AppChoice<T>> destinations = widget.destinations;
    final bool showDestination = destinations.isNotEmpty && errorText == null;
    final TextStyle? captionStyle = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    // Con el selector abierto, el campo se dibuja sin foco: solo hay uno activo.
    final Color fieldBorder = errorText != null ? colors.borderDanger : colors.borderStrong;
    final Color focusedBorder = switch ((errorText != null, _choosing)) {
      (true, _) => colors.borderDanger,
      (false, true) => colors.borderStrong,
      (false, false) => colors.borderFocus,
    };
    final double focusedWidth = _choosing ? AppSizes.strokeThin : AppSizes.strokeThick;
    final String label = widget.label;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bgSurfaceRaised, boxShadow: shadow),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.s300, AppSpacing.s300),
          // El destino cuenta como parte del campo: tocarlo no quita el foco.
          child: TextFieldTapRegion(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s150,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(label, style: textTheme.labelLarge?.copyWith(color: colors.textPrimary)),
                      ),
                    ),
                    AppIconButton(
                      icon: AppIcons.x,
                      tooltip: widget.closeTooltip,
                      variant: AppIconButtonVariant.subtle,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        label: label,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (String _) => _submit(),
                          style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            filled: true,
                            fillColor: colors.bgSurface,
                            constraints: const BoxConstraints(minHeight: AppSizes.controlLarge),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s300,
                              vertical: AppSpacing.s300,
                            ),
                            enabledBorder: _border(fieldBorder, AppSizes.strokeThin),
                            focusedBorder: _border(focusedBorder, focusedWidth),
                            error: errorText == null ? null : FieldError(errorText),
                            errorMaxLines: 3,
                            errorBorder: _border(colors.borderDanger, AppSizes.strokeThin),
                            focusedErrorBorder: _border(colors.borderDanger, AppSizes.strokeThick),
                          ),
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: AppIcons.send,
                      tooltip: widget.submitTooltip,
                      variant: AppIconButtonVariant.filled,
                      onPressed: _submit,
                    ),
                  ],
                ),
                if (showDestination)
                  _Destination<T>(
                    label: widget.destinationLabel,
                    labelStyle: captionStyle,
                    options: destinations,
                    selected: widget.selectedDestination,
                    semanticLabel: widget.destinationSemanticLabel,
                    choosing: _choosing,
                    onToggle: () => setState(() => _choosing = !_choosing),
                    onChosen: _choose,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// «Se añadirá a» con el chip del destino y, desplegadas, las opciones.
class _Destination<T> extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.labelStyle,
    required this.options,
    required this.selected,
    required this.semanticLabel,
    required this.choosing,
    required this.onToggle,
    required this.onChosen,
  });

  final String? label;
  final TextStyle? labelStyle;
  final List<AppChoice<T>> options;
  final T? selected;
  final String? semanticLabel;
  final bool choosing;
  final VoidCallback onToggle;
  final ValueChanged<T> onChosen;

  @override
  Widget build(BuildContext context) {
    final String? label = this.label;
    final AppChoice<T> current = options.firstWhere(
      (AppChoice<T> option) => option.value == selected,
      orElse: () => options.first,
    );
    final BorderRadius chipRadius = BorderRadius.circular(AppRadii.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s300,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: <Widget>[
            if (label != null) ExcludeSemantics(child: Text(label, style: labelStyle)),
            AppTouchTarget(
              child: AppFocusRing.when(
                focused: choosing,
                keyboardOnly: false,
                position: AppFocusRingPosition.outside,
                borderRadius: chipRadius,
                child: Semantics(
                  button: true,
                  expanded: choosing,
                  label: semanticLabel,
                  excludeSemantics: semanticLabel != null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.controlCompact),
                    child: ActionChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.xs,
                        children: <Widget>[
                          Flexible(child: Text(current.label)),
                          Icon(choosing ? AppIcons.chevronUp : AppIcons.chevronDown, size: AppSizes.iconSmall),
                        ],
                      ),
                      labelPadding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: onToggle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (choosing)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.s300,
            children: <Widget>[
              for (final AppChoice<T> option in options)
                AppTouchTarget(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.controlCompact),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: option.value == current.value,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (bool _) => onChosen(option.value),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
