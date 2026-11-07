import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import 'app_touch_target.dart';

enum AppButtonVariant {
  /// La acción principal de la pantalla.
  primary,

  /// Relleno suave de marca: acción importante, pero no la principal.
  secondary,

  /// Solo borde: acciones de menos peso, junto a otras más importantes.
  outline,

  /// Solo texto.
  text,

  /// Relleno de peligro: confirma algo que no se puede deshacer.
  danger,

  /// Solo borde, en color de peligro: una opción destructiva entre otras.
  dangerOutline,

  /// Solo texto, en color de peligro: una acción destructiva secundaria (p. ej.
  /// «Borrar tarea» al final de un formulario).
  dangerText,
}

enum AppButtonSize {
  /// 36 de alto, para acciones de texto en una cabecera o una fila.
  small,

  /// 40 de alto, para acciones dentro de una tarjeta, un diálogo o una vista
  /// de estado.
  medium,

  /// 48 de alto, con texto más grande, para las acciones de una pantalla.
  large,
}

/// Botón con texto. Mide [size] de alto (por defecto [AppButtonSize.small] si
/// es solo texto y [AppButtonSize.large] si no) y su área táctil es de al
/// menos 48 dp en cualquier tamaño. Con [isLoading] muestra un indicador y se
/// desactiva, conservando su etiqueta para lectores de pantalla.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize? size;
  final bool isLoading;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  AppButtonSize get _size =>
      size ??
      (variant == AppButtonVariant.text || variant == AppButtonVariant.dangerText ? AppButtonSize.small : AppButtonSize.large);

  ButtonStyle _style(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppButtonSize size = _size;
    final (double height, double padding, TextStyle? textStyle) = switch (size) {
      AppButtonSize.small => (AppSizes.controlCompact, AppSpacing.sm, textTheme.labelLarge),
      AppButtonSize.medium => (AppSizes.controlMedium, AppSpacing.md, textTheme.labelLarge),
      AppButtonSize.large => (AppSizes.controlLarge, AppSpacing.s500, textTheme.titleMedium),
    };
    final ButtonStyle style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(Size(height, height)),
      padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: padding)),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final AppThemeColors colors = AppThemeColors.of(context);
    return switch (variant) {
      AppButtonVariant.danger => style.merge(
          FilledButton.styleFrom(backgroundColor: colors.actionDangerDefault, foregroundColor: colors.textOnDanger),
        ),
      AppButtonVariant.dangerOutline => style.merge(
          OutlinedButton.styleFrom(
            foregroundColor: colors.textDanger,
            side: BorderSide(color: colors.borderDanger),
          ),
        ),
      AppButtonVariant.dangerText => style.merge(TextButton.styleFrom(foregroundColor: colors.textDanger)),
      _ => style,
    };
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed = isLoading ? null : this.onPressed;
    final ButtonStyle style = _style(context);
    final Widget? leading = isLoading
        ? const SizedBox.square(
            dimension: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null ? null : Icon(icon));
    final Text text = Text(label, textAlign: TextAlign.center);

    final Widget button = switch ((variant, leading)) {
      (AppButtonVariant.primary || AppButtonVariant.danger, null) =>
        FilledButton(style: style, onPressed: onPressed, child: text),
      (AppButtonVariant.primary || AppButtonVariant.danger, final Widget leading) =>
        FilledButton.icon(style: style, onPressed: onPressed, icon: leading, label: text),
      (AppButtonVariant.secondary, null) => FilledButton.tonal(style: style, onPressed: onPressed, child: text),
      (AppButtonVariant.secondary, final Widget leading) =>
        FilledButton.tonalIcon(style: style, onPressed: onPressed, icon: leading, label: text),
      (AppButtonVariant.outline || AppButtonVariant.dangerOutline, null) =>
        OutlinedButton(style: style, onPressed: onPressed, child: text),
      (AppButtonVariant.outline || AppButtonVariant.dangerOutline, final Widget leading) =>
        OutlinedButton.icon(style: style, onPressed: onPressed, icon: leading, label: text),
      (AppButtonVariant.text || AppButtonVariant.dangerText, null) =>
        TextButton(style: style, onPressed: onPressed, child: text),
      (AppButtonVariant.text || AppButtonVariant.dangerText, final Widget leading) =>
        TextButton.icon(style: style, onPressed: onPressed, icon: leading, label: text),
    };

    return AppTouchTarget(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: expand ? double.infinity : 0),
        child: button,
      ),
    );
  }
}
