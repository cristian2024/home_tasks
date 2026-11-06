import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';

/// Pregunta si los datos del espacio [spaceName], que no tiene hogar, van al
/// hogar que se crea o al que se une. Devuelve `true` para llevarlos,
/// `false` para empezar un espacio vacío y `null` si el usuario cancela.
Future<bool?> showBringDataDialog(BuildContext context, {required String spaceName}) {
  final AppTranslations$app$spaces$es t = appStrings.app.spaces;
  return showAppChoiceDialog<bool>(
    context,
    title: t.bringTitle(name: spaceName),
    message: t.bringMessage,
    cancelLabel: t.cancel,
    options: <AppDialogOption<bool>>[
      AppDialogOption<bool>(value: true, label: t.bringConfirm, primary: true),
      AppDialogOption<bool>(value: false, label: t.startEmpty),
    ],
  );
}
