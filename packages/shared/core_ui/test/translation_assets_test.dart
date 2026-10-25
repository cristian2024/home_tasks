import 'package:core_ui/core_ui.dart';
import 'package:core_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('translationAsset sigue la convención assets/i18n/<paquete>/<idioma>.json', () {
    expect(translationAsset('core_ui', 'en'), 'assets/i18n/core_ui/en.json');
  });

  group('injectTranslations', () {
    late LocalizationCoordinator localization;

    setUp(() => localization = LocalizationCoordinator());
    tearDown(() {
      for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
        localization.overrideTranslations('core_ui', languageCode, <String, Object?>{});
      }
      localization.setLanguage('es');
    });

    test('inyecta los textos de cada idioma desde los assets', () async {
      await injectTranslations(
        localization,
        bundle: MapAssetBundle(<String, String>{
          translationAsset('core_ui', 'es'): '{"common": {"cancel": "Descartar"}}',
          translationAsset('core_ui', 'en'): '{"common": {"cancel": "Discard"}}',
        }),
        packages: <String>['core_ui'],
      );

      expect(commonStrings.common.cancel, 'Descartar');
      localization.setLanguage('en');
      expect(commonStrings.common.cancel, 'Discard');
    });

    test('un archivo inválido o ausente se ignora y el paquete usa sus textos', () async {
      await injectTranslations(
        localization,
        bundle: MapAssetBundle(<String, String>{translationAsset('core_ui', 'es'): 'no es JSON'}),
        packages: <String>['core_ui'],
      );

      expect(commonStrings.common.cancel, 'Cancelar');
      localization.setLanguage('en');
      expect(commonStrings.common.cancel, 'Cancel');
    });
  });

  group('translationProblems', () {
    final Map<String, Object?> base = <String, Object?>{
      'title': 'Título',
      'greeting': 'Hola {name}',
      'section': <String, Object?>{'label': 'Etiqueta'},
    };

    test('textos completos no tienen problemas', () {
      expect(
        translationProblems(base, <String, Object?>{
          'title': 'Otro título',
          'greeting': '¡Hola, {name}!',
          'section': <String, Object?>{'label': 'Otra'},
        }),
        isEmpty,
      );
    });

    test('detecta claves que faltan, que sobran, tipos y parámetros distintos', () {
      expect(
        translationProblems(base, <String, Object?>{
          'greeting': 'Hola {nombre}',
          'section': <String, Object?>{'other': 'z'},
          'extra': 'x',
        }),
        <String>[
          'title: falta',
          'greeting: parámetros {nombre} en lugar de {name}',
          'section.label: falta',
          'section.other: no existe en el paquete',
          'extra: no existe en el paquete',
        ],
      );
      expect(
        translationProblems(base, <String, Object?>{
          'title': <String, Object?>{'x': 'y'},
          'greeting': 'Hola {name}',
          'section': 'texto',
        }),
        <String>[
          'title: no tiene el mismo tipo que en el paquete',
          'section: no tiene el mismo tipo que en el paquete',
        ],
      );
    });
  });

  test('packageTranslations lee los JSON de un paquete del workspace', () {
    final Map<String, Object?> es = packageTranslations('core_ui', 'es');

    expect((es['common']! as Map<String, Object?>)['cancel'], 'Cancelar');
  });
}
