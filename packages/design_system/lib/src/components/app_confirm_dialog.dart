import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'app_button.dart';

/// Diálogo de confirmación. Devuelve `true` solo si el usuario confirma.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: <Widget>[
        AppButton(
          label: cancelLabel ?? commonStrings.common.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel ?? commonStrings.common.confirm,
          variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
