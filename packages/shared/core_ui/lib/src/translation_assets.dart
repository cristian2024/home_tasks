import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import 'localization_coordinator.dart';

/// Asset con todos los textos de [packageName] en [languageCode] que inyecta
/// quien consume el paquete (la app o una app de ejemplo).
String translationAsset(String packageName, String languageCode) => 'assets/i18n/$packageName/$languageCode.json';

/// Lee de [bundle] los textos de cada paquete de [packages] en cada idioma
/// soportado y se los inyecta a [localization] con
/// [LocalizationCoordinator.overrideTranslations].
///
/// Quien consume un paquete define todos sus textos, con la misma estructura
/// que los JSON del paquete; `package:core_ui/testing.dart` comprueba en sus
/// tests que estén completos. Un archivo que falta o no se puede leer se
/// registra en el log y ese paquete muestra sus propios textos de respaldo.
Future<void> injectTranslations(
  LocalizationCoordinator localization, {
  required AssetBundle bundle,
  required List<String> packages,
}) async {
  for (final String packageName in packages) {
    for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
      final String asset = translationAsset(packageName, languageCode);
      try {
        final Object? content = jsonDecode(await bundle.loadString(asset));
        localization.overrideTranslations(packageName, languageCode, content! as Map<String, Object?>);
      } on Object catch (error, stackTrace) {
        developer.log(
          'No se pudieron inyectar los textos de $asset',
          name: 'core_ui',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
