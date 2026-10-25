import 'dart:convert';
import 'dart:developer' as developer;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/services.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

/// Paquetes cuyos textos puede reemplazar la app, con el nombre con que se
/// registran en [LocalizationCoordinator].
const List<String> overridablePackages = <String>['core_ui', ItemTrackerPlugin.pluginId];

/// Asset con los textos de [packageName] en [languageCode] que reemplaza la
/// app.
String translationOverridesAsset(String packageName, String languageCode) =>
    'assets/i18n/$packageName/$languageCode.json';

/// Lee de [bundle] los textos que la app reemplaza en cada paquete y se los
/// pasa a [localization] (§6.2). Cada JSON sigue la estructura de los del
/// paquete y solo lleva las claves que cambian; el resto sale del paquete.
///
/// Un archivo que falta o no se puede leer se ignora: ese paquete muestra sus
/// propios textos. Los tests de la app comprueban que los archivos son válidos.
Future<void> applyTranslationOverrides(
  LocalizationCoordinator localization, {
  required AssetBundle bundle,
  List<String> packages = overridablePackages,
}) async {
  for (final String packageName in packages) {
    for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
      final String asset = translationOverridesAsset(packageName, languageCode);
      try {
        final Object? content = jsonDecode(await bundle.loadString(asset));
        localization.overrideTranslations(packageName, languageCode, content! as Map<String, Object?>);
      } on Object catch (error, stackTrace) {
        developer.log(
          'No se pudieron aplicar los textos de $asset',
          name: 'home_utility_app',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
