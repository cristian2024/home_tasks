import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_focus_ring.dart';
import 'app_icon_button.dart';
import 'app_touch_target.dart';

/// Acción de icono al final de un [AppCheckTile] (p. ej. el lápiz de editar).
class AppTileAction {
  const AppTileAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;

  /// También es lo que leen los lectores de pantalla (p. ej. «Editar «Leche»»).
  final String tooltip;
  final VoidCallback onPressed;
}

/// Fila de una lista que se marca como hecha (p. ej. comprado) con su
/// casilla. Un toque en el resto de la fila llama a [onTap] (p. ej. editar).
///
/// Marcada, el título se tacha y pasa al color secundario, que conserva el
/// contraste. [subtitle] es la línea de datos (fecha, categoría…) y [badges] se
/// muestran debajo.
///
/// Con [action], la fila termina en un botón de icono de 48 con el icono de 20
/// en `text.tertiary`, para no competir con el contenido, y la casilla se
/// centra con él. Con [semanticLabel], los lectores de pantalla leen la fila
/// como un solo botón con ese texto; la casilla y [action] siguen siendo
/// destinos propios, y [semanticActions] añade acciones al menú del lector (p.
/// ej. «Borrar»). Con el foco del teclado, la fila lleva el anillo por dentro.
/// [highlighted] la pinta con el fondo de marca (p. ej. recién creada).
class AppCheckTile extends StatefulWidget {
  const AppCheckTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.checkboxLabel,
    this.subtitle,
    this.subtitleSemantics,
    this.badges = const <Widget>[],
    this.onTap,
    this.trailing,
    this.action,
    this.semanticLabel,
    this.semanticActions = const <CustomSemanticsAction, VoidCallback>{},
    this.highlighted = false,
  });

  /// Cuánto tarda el fondo de [highlighted] en aparecer y en irse.
  static const Duration highlightDuration = Duration(milliseconds: 300);

  final String title;
  final String? subtitle;

  /// Cómo leen [subtitle] los lectores de pantalla, si debe ser distinto (p. ej.
  /// la fecha completa en lugar de «12 nov»).
  final String? subtitleSemantics;

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
  final AppTileAction? action;

  /// Lo que leen los lectores de pantalla para toda la fila, en lugar de sus
  /// textos (p. ej. «Leche, 2 litros, inmediata. Editar»).
  final String? semanticLabel;

  /// Acciones del menú del lector de pantalla (TalkBack, rotor de VoiceOver).
  /// Solo con [semanticLabel].
  final Map<CustomSemanticsAction, VoidCallback> semanticActions;

  final bool highlighted;

  @override
  State<AppCheckTile> createState() => _AppCheckTileState();
}

class _AppCheckTileState extends State<AppCheckTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeColors colors = AppThemeColors.of(context);
    final ValueChanged<bool>? onChanged = widget.onChanged;
    final String? subtitle = widget.subtitle;
    final Widget? trailing = widget.trailing;
    final AppTileAction? action = widget.action;
    final String? semanticLabel = widget.semanticLabel;
    final bool value = widget.value;
    final List<Widget> badges = widget.badges;
    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: <Widget>[
        Text(
          widget.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value ? colors.textSecondary : colors.textPrimary,
            decoration: value ? TextDecoration.lineThrough : null,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            semanticsLabel: widget.subtitleSemantics,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        if (badges.isNotEmpty) Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: badges),
      ],
    );
    final Widget readTexts = semanticLabel == null ? texts : ExcludeSemantics(child: texts);
    final Widget checkbox = _SizedCheckbox(
      child: Checkbox(
        value: value,
        semanticLabel: widget.checkboxLabel,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: onChanged == null ? null : (bool? checked) => onChanged(checked ?? false),
      ),
    );
    // Con acción, la casilla queda centrada con el botón de 48 y el padding
    // vertical lo pone el texto.
    final Widget row = action == null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.s300),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s300,
              children: <Widget>[checkbox, Expanded(child: readTexts), ?trailing],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s300,
              children: <Widget>[
                Padding(padding: const EdgeInsets.only(top: AppSpacing.s300), child: checkbox),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s300),
                    child: readTexts,
                  ),
                ),
                ?trailing,
                AppIconButton(
                  icon: action.icon,
                  tooltip: action.tooltip,
                  variant: AppIconButtonVariant.subtle,
                  iconColor: colors.textTertiary,
                  onPressed: action.onPressed,
                ),
              ],
            ),
          );
    final Widget tile = AppFocusRing.when(
      focused: _focused,
      child: AnimatedContainer(
        duration: AppCheckTile.highlightDuration,
        color: widget.highlighted ? colors.bgBrandSubtle : colors.bgBrandSubtle.withValues(alpha: 0),
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (bool focused) => setState(() => _focused = focused),
          child: row,
        ),
      ),
    );
    if (semanticLabel == null) {
      return tile;
    }
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: semanticLabel,
      customSemanticsActions: widget.semanticActions.isEmpty ? null : widget.semanticActions,
      child: tile,
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
