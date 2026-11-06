import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_button.dart';

/// Opción de [showAppChoiceDialog].
class AppDialogOption<T> {
  const AppDialogOption({required this.value, required this.label, this.destructive = false, this.primary = false});

  final T value;
  final String label;

  /// Se pinta con borde de peligro (p. ej. «Borrar todo»).
  final bool destructive;

  /// Es la opción recomendada.
  final bool primary;
}

/// Diálogo que pregunta entre varias acciones, además de cancelar. Devuelve
/// el `value` de la opción elegida, o `null` si el usuario cancela o lo
/// cierra. Las opciones van apiladas, a todo el ancho, y cancelar al final.
Future<T?> showAppChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  required List<AppDialogOption<T>> options,
  String? cancelLabel,
}) =>
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Text(message),
              const SizedBox(height: AppSpacing.sm),
              for (final AppDialogOption<T> option in options)
                AppButton(
                  label: option.label,
                  variant: switch (option) {
                    AppDialogOption<T>(destructive: true) => AppButtonVariant.dangerOutline,
                    AppDialogOption<T>(primary: true) => AppButtonVariant.primary,
                    _ => AppButtonVariant.secondary,
                  },
                  size: AppButtonSize.medium,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(option.value),
                ),
              Center(
                child: AppButton(
                  label: cancelLabel ?? commonStrings.common.cancel,
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
