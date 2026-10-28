import 'dart:convert';

import 'package:core_ui/core_ui.dart';
import 'package:core_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:item_tracker_example/src/injected_translations.dart';
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

  group('el ejemplo define todos los textos', () {
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
}
