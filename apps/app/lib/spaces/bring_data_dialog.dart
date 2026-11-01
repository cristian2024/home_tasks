import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';

/// Pregunta si los datos del espacio [spaceName], que no tiene hogar, van al
/// hogar que se crea o al que se une. Devuelve `true` para llevarlos,
/// `false` para empezar un espacio vacío y `null` si el usuario cancela.
Future<bool?> showBringDataDialog(BuildContext context, {required String spaceName}) => showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _BringDataDialog(spaceName: spaceName),
    );

class _BringDataDialog extends StatelessWidget {
  const _BringDataDialog({required this.spaceName});

  final String spaceName;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    return AlertDialog(
      title: Text(t.bringTitle(name: spaceName)),
      content: Text(t.bringMessage),
      actions: <Widget>[
        AppButton(label: t.cancel, variant: AppButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(label: t.startEmpty, variant: AppButtonVariant.secondary, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(label: t.bringConfirm, onPressed: () => Navigator.of(context).pop(true)),
      ],
    );
  }
}
