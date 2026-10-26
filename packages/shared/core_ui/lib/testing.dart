/// Utilidades para los tests de quien inyecta los textos de los paquetes
/// (`injectTranslations`): comprobar que sus archivos están completos y
/// cargar assets en memoria.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Compara los textos que inyecta un consumidor ([injected]) con los JSON del
/// paquete ([base]) en el mismo idioma. Deben tener exactamente las mismas
/// claves, del mismo tipo y con los mismos parámetros. Devuelve un mensaje
/// por problema; una lista vacía significa que están completos.
List<String> translationProblems(Map<String, Object?> base, Map<String, Object?> injected, [String prefix = '']) {
  final List<String> problems = <String>[];
  for (final MapEntry<String, Object?> entry in base.entries) {
    final String path = '$prefix${entry.key}';
    final Object? original = entry.value;
    final Object? value = injected[entry.key];
    if (!injected.containsKey(entry.key)) {
      problems.add('$path: falta');
    } else if (original is Map<String, Object?> && value is Map<String, Object?>) {
      problems.addAll(translationProblems(original, value, '$path.'));
    } else if (original is String && value is String) {
      if (!setEquals(_parameters(original), _parameters(value))) {
        problems.add('$path: parámetros ${_parameters(value)} en lugar de ${_parameters(original)}');
      }
    } else {
      problems.add('$path: no tiene el mismo tipo que en el paquete');
    }
  }
  for (final String key in injected.keys) {
    if (!base.containsKey(key)) {
      problems.add('$prefix$key: no existe en el paquete');
    }
  }
  return problems;
}

final RegExp _parameter = RegExp(r'\{(\w+)\}');

Set<String> _parameters(String text) =>
    _parameter.allMatches(text).map((RegExpMatch match) => match.group(1)!).toSet();

/// JSON de traducciones del paquete Dart [dartPackage] en [languageCode]
/// (`lib/src/i18n/<idioma>.i18n.json`), localizado con el
/// `package_config.json` del workspace (`Isolate.resolvePackageUri` no está
/// disponible en `flutter test`).
Map<String, Object?> packageTranslations(String dartPackage, String languageCode) {
  Directory directory = Directory.current;
  while (!File('${directory.path}/.dart_tool/package_config.json').existsSync()) {
    directory = directory.parent;
  }
  final File config = File('${directory.path}/.dart_tool/package_config.json');
  final List<Object?> packages =
      (jsonDecode(config.readAsStringSync()) as Map<String, Object?>)['packages']! as List<Object?>;
  final Map<String, Object?> package = packages
      .cast<Map<String, Object?>>()
      .firstWhere((Map<String, Object?> entry) => entry['name'] == dartPackage);
  final Uri root = config.uri.resolve('${package['rootUri']}/');
  final File file = File.fromUri(root.resolve('lib/src/i18n/$languageCode.i18n.json'));
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// Assets en memoria; un asset que no está falla como en `rootBundle`.
class MapAssetBundle extends CachingAssetBundle {
  MapAssetBundle(this.assets);

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
