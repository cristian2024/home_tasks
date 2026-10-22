import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

/// Botón con texto. Mide al menos 48 dp de alto; con [isLoading] muestra un
/// indicador y se desactiva, conservando su etiqueta para lectores de pantalla.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onPressed = isLoading ? null : this.onPressed;
    final leading = isLoading
        ? const SizedBox.square(
            dimension: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null ? null : Icon(icon));
    final text = Text(label, textAlign: TextAlign.center);

    final button = switch ((variant, leading)) {
      (AppButtonVariant.primary, null) => FilledButton(onPressed: onPressed, child: text),
      (AppButtonVariant.primary, final Widget leading) =>
        FilledButton.icon(onPressed: onPressed, icon: leading, label: text),
      (AppButtonVariant.secondary, null) => OutlinedButton(onPressed: onPressed, child: text),
      (AppButtonVariant.secondary, final Widget leading) =>
        OutlinedButton.icon(onPressed: onPressed, icon: leading, label: text),
      (AppButtonVariant.text, null) => TextButton(onPressed: onPressed, child: text),
      (AppButtonVariant.text, final Widget leading) =>
        TextButton.icon(onPressed: onPressed, icon: leading, label: text),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSizes.minTouchTarget,
        minWidth: expand ? double.infinity : AppSizes.minTouchTarget,
      ),
      child: button,
    );
  }
}
