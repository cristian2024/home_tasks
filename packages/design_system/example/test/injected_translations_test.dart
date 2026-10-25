import 'dart:convert';

import 'package:core_ui/core_ui.dart';
import 'package:core_ui/testing.dart';
import 'package:design_system_example/src/injected_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la galería define todos los textos', () {
    for (final String packageName in injectedTranslationPackages) {
      for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
        final String asset = translationAsset(packageName, languageCode);

        test('$asset tiene las claves y los parámetros del paquete', () async {
          final Object? injected = jsonDecode(await rootBundle.loadString(asset));

          expect(injected, isA<Map<String, Object?>>());
          expect(
            translationProblems(packageTranslations(packageName, languageCode), injected! as Map<String, Object?>),
            isEmpty,
          );
        });
      }
    }
  });
}
