import 'dart:convert';
import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/i18n/translation_overrides.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

/// Paquete Dart de cada nombre de [overridablePackages], para leer sus JSON.
const Map<String, String> _dartPackages = <String, String>{
  'core_ui': 'core_ui',
  ItemTrackerPlugin.pluginId: 'plugin_item_tracker',
};

/// slang solo comprueba los reemplazos al aplicarlos: aquí se verifica que
/// cada clave reemplazada existe en el paquete, con el mismo tipo y los
/// mismos parámetros. Devuelve un mensaje por problema.
List<String> overrideProblems(Map<String, Object?> base, Map<String, Object?> overrides, [String prefix = '']) {
  final List<String> problems = <String>[];
  for (final MapEntry<String, Object?> entry in overrides.entries) {
    final String path = '$prefix${entry.key}';
    final Object? original = base[entry.key];
    final Object? value = entry.value;
    if (!base.containsKey(entry.key)) {
      problems.add('$path: no existe en el paquete');
    } else if (original is Map<String, Object?> && value is Map<String, Object?>) {
      problems.addAll(overrideProblems(original, value, '$path.'));
    } else if (original is String && value is String) {
      if (!setEquals(_parameters(original), _parameters(value))) {
        problems.add('$path: parámetros ${_parameters(value)} en lugar de ${_parameters(original)}');
      }
    } else {
      problems.add('$path: no tiene el mismo tipo que en el paquete');
    }
  }
  return problems;
}

final RegExp _parameter = RegExp(r'\{(\w+)\}');

Set<String> _parameters(String text) =>
    _parameter.allMatches(text).map((RegExpMatch match) => match.group(1)!).toSet();

/// JSON de traducciones de [packageName], localizado con el
/// `package_config.json` del workspace (`Isolate.resolvePackageUri` no está
/// disponible en `flutter test`).
Map<String, Object?> _packageTranslations(String packageName, String languageCode) {
  Directory directory = Directory.current;
  while (!File('${directory.path}/.dart_tool/package_config.json').existsSync()) {
    directory = directory.parent;
  }
  final File config = File('${directory.path}/.dart_tool/package_config.json');
  final List<Object?> packages = (jsonDecode(config.readAsStringSync()) as Map<String, Object?>)['packages']! as List<Object?>;
  final Map<String, Object?> package = packages
      .cast<Map<String, Object?>>()
      .firstWhere((Map<String, Object?> entry) => entry['name'] == _dartPackages[packageName]);
  final Uri root = config.uri.resolve('${package['rootUri']}/');
  final File file = File.fromUri(root.resolve('lib/src/i18n/$languageCode.i18n.json'));
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// Assets en memoria; un asset que no está falla como en `rootBundle`.
class _MapAssetBundle extends CachingAssetBundle {
  _MapAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final String? content = assets[key];
    if (content == null) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    return ByteData.sublistView(utf8.encode(content));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('archivos de la app', () {
    for (final String packageName in overridablePackages) {
      for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
        final String asset = translationOverridesAsset(packageName, languageCode);

        test('$asset solo reemplaza claves que existen, con sus parámetros', () async {
          final Object? overrides = jsonDecode(await rootBundle.loadString(asset));

          expect(overrides, isA<Map<String, Object?>>());
          expect(
            overrideProblems(_packageTranslations(packageName, languageCode), overrides! as Map<String, Object?>),
            isEmpty,
          );
        });
      }
    }
  });

  test('overrideProblems detecta claves desconocidas, tipos y parámetros distintos', () {
    final Map<String, Object?> base = <String, Object?>{
      'title': 'Título',
      'greeting': 'Hola {name}',
      'section': <String, Object?>{'label': 'Etiqueta'},
    };

    expect(
      overrideProblems(base, <String, Object?>{
        'title': 'Otro título',
        'section': <String, Object?>{'label': 'Otra'},
      }),
      isEmpty,
    );
    expect(
      overrideProblems(base, <String, Object?>{
        'missing': 'x',
        'greeting': 'Hola {nombre}',
        'title': <String, Object?>{'x': 'y'},
        'section': <String, Object?>{'other': 'z'},
      }),
      <String>[
        'missing: no existe en el paquete',
        'greeting: parámetros {nombre} en lugar de {name}',
        'title: no tiene el mismo tipo que en el paquete',
        'section.other: no existe en el paquete',
      ],
    );
  });

  group('applyTranslationOverrides', () {
    late LocalizationCoordinator localization;

    setUp(() {
      localization = LocalizationCoordinator();
      ItemTrackerPlugin(locator: ServiceLocator(), localization: localization).registerLocalization();
    });

    tearDown(() {
      for (final String packageName in overridablePackages) {
        for (final String languageCode in LocalizationCoordinator.supportedLanguageCodes) {
          localization.overrideTranslations(packageName, languageCode, <String, Object?>{});
        }
      }
      localization.setLanguage('es');
    });

    test('los textos de la app tienen prioridad y un archivo inválido o ausente se ignora', () async {
      await applyTranslationOverrides(
        localization,
        bundle: _MapAssetBundle(<String, String>{
          translationOverridesAsset(ItemTrackerPlugin.pluginId, 'es'): '{"item_tracker": {"title": "Mis cosas"}}',
          translationOverridesAsset('core_ui', 'es'): 'no es JSON',
        }),
      );

      expect(localization.translate('itemTracker.title'), 'Mis cosas');
      expect(localization.translate('itemTracker.description'), startsWith('Identifica tus objetos'));
      expect(localization.translate('common.cancel'), 'Cancelar');

      localization.setLanguage('en');
      expect(localization.translate('itemTracker.title'), 'Item Tracker');
    });
  });
}
