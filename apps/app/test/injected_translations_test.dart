import 'dart:convert';

import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/i18n/injected_translations.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

/// Paquete Dart de cada nombre de [injectedTranslationPackages], para leer
/// sus JSON.
const Map<String, String> _dartPackages = <String, String>{
  'core_ui': 'core_ui',
  ItemTrackerPlugin.pluginId: 'plugin_item_tracker',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada paquete inyectado tiene su paquete Dart para validar', () {
    expect(_dartPackages.keys, unorderedEquals(injectedTranslationPackages));
  });

  group('la app define todos los textos', () {
    for (final String packageName in injectedTranslationPackages) {
      for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
        final String asset = translationAsset(packageName, languageCode);

        test('$asset tiene las claves y los parámetros del paquete', () async {
          final Object? injected = jsonDecode(await rootBundle.loadString(asset));

          expect(injected, isA<Map<String, Object?>>());
          expect(
            translationProblems(
              packageTranslations(_dartPackages[packageName]!, languageCode),
              injected! as Map<String, Object?>,
            ),
            isEmpty,
          );
        });
      }
    }
  });

  test('los textos que se muestran son los de la app', () async {
    final LocalizationCoordinator localization = LocalizationCoordinator();
    ItemTrackerPlugin(locator: ServiceLocator(), localization: localization).registerLocalization();
    final Map<String, Object?> en =
        jsonDecode(await rootBundle.loadString(translationAsset(ItemTrackerPlugin.pluginId, 'en')))
            as Map<String, Object?>;

    await injectTranslations(localization, bundle: rootBundle, packages: injectedTranslationPackages);
    localization.setLanguage('en');

    expect(localization.translate('itemTracker.title'), (en['item_tracker']! as Map<String, Object?>)['title']);
    localization.setLanguage('es');
  });
}
