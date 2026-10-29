import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Opción de [showAppChoiceDialog].
class AppDialogOption<T> {
  const AppDialogOption({required this.value, required this.label, this.destructive = false});

  final T value;
  final String label;

  /// Se pinta con el color de error (p. ej. «Borrar todo»).
  final bool destructive;
}

/// Diálogo que pregunta entre varias acciones, además de cancelar. Devuelve
/// el `value` de la opción elegida, o `null` si el usuario cancela o lo
/// cierra. Si los botones no caben en una fila, se apilan.
Future<T?> showAppChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  required List<AppDialogOption<T>> options,
  String? cancelLabel,
}) {
  return showDialog<T>(
    context: context,
    builder: (BuildContext context) {
      final ColorScheme colors = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelLabel ?? commonStrings.common.cancel),
          ),
          for (final AppDialogOption<T> option in options)
            FilledButton(
              style: option.destructive
                  ? FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)
                  : null,
              onPressed: () => Navigator.of(context).pop(option.value),
              child: Text(option.label),
            ),
        ],
      );
    },
  );
}
