import 'dart:io';

/// Violación de una regla de importación del §5.2 de la spec.
class ArchitectureViolation {
  final String rule;
  final String file;
  final String import;

  const ArchitectureViolation({
    required this.rule,
    required this.file,
    required this.import,
  });

  @override
  String toString() => '[$rule] $file importa "$import"';
}

const String _rule1 = 'Regla 1: una funcionalidad no puede importar paquetes de otra';
const String _rule2 = 'Regla 2: Domain no puede importar Flutter ni motores de base de datos';
const String _rule3 = 'Regla 3: design_system solo depende de Flutter y core_ui';
const String _rule4 = 'Regla 4: solo los adaptadores importan SDKs nativos de hardware';
const String _rule5 = 'Regla 5: solo los adaptadores importan motores de base de datos';
const String _rule6 = 'Regla 6: solo las apps, los ejemplos y otros adaptadores importan adaptadores';
const String _rule7 = 'Regla 7: un adaptador o un dominio no importa el plugin';
const String _rule8 = 'Regla 8: un contrato es Dart puro y no importa funcionalidades ni apps';
const String _rule9 = 'Regla 9: solo los adaptadores importan SDKs de plataforma';

final RegExp _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
final RegExp _pubspecName = RegExp(r'^name:\s*(\S+)', multiLine: true);
final RegExp _flutterInDomain = RegExp(r'^(package:flutter\w*/|dart:ui$)');
const Set<String> _allowedInDesignSystem = <String>{'flutter', 'core_ui'};
final RegExp _nativeHardwarePackage = RegExp(r'^(mobile_scanner|nfc_manager\w*|permission_handler\w*)$');

/// SDKs de plataforma que solo usan los adaptadores (compartir, abrir
/// enlaces, archivos).
final RegExp _platformSdkPackage = RegExp(r'^(share_plus\w*|url_launcher\w*|file_picker|path_provider\w*)$');

/// Paquetes de motores de base de datos.
final RegExp _storageEnginePackage =
    RegExp(r'^(isar\w*|sqflite\w*|sqlite3\w*|drift\w*|hive\w*|objectbox\w*|realm\w*|sembast\w*)$');

/// Sufijo de un adaptador de funcionalidad (`<funcionalidad>_<motor>`, p. ej.
/// `item_tracker_isar`).
final RegExp _featureAdapterName = RegExp(r'_(isar|sqflite|sqlite|drift|hive|objectbox|realm|sembast)$');

enum _Role {
  /// App o app de ejemplo: compone paquetes y elige adaptadores.
  host,

  /// `packages/plugins/<funcionalidad>/plugin_<funcionalidad>` o, con la
  /// estructura anterior, `packages/plugins/<plugin>`.
  plugin,

  /// `packages/plugins/<funcionalidad>/<funcionalidad>_domain`: Dart puro.
  domain,

  /// `packages/contracts/*`: API pública de una funcionalidad (eventos y
  /// capacidades) que otras pueden usar. Dart puro.
  contract,

  /// `packages/adapters/*` o `packages/plugins/<funcionalidad>/<funcionalidad>_<motor>`.
  adapter,

  /// Otro paquete de una funcionalidad.
  featureOther,

  /// Paquetes `core`, `shared` y `design_system`.
  other,
}

/// Roles que un contrato no puede importar: solo depende de otros contratos
/// y de paquetes comunes. Los adaptadores ya los prohíbe la regla 6.
const Set<_Role> _contractForbiddenImports = <_Role>{_Role.host, _Role.plugin, _Role.domain, _Role.featureOther};

class _Package {
  _Package(this.name, this.path, this.role, this.feature);

  final String name;
  final String path; // Relativo a la raíz, con '/'.
  final _Role role;

  /// Funcionalidad a la que pertenece (carpeta de `packages/plugins/`).
  final String? feature;

  bool get isDesignSystem => path == 'packages/design_system';
  bool get isCoreHardware => path == 'packages/core/core_hardware';
}

/// Recorre `lib/` de cada paquete bajo `apps/` y `packages/` en [root] y
/// devuelve las violaciones de las reglas de importación.
List<ArchitectureViolation> findViolations(Directory root) {
  final List<_Package> packages = _findPackages(root);
  final Map<String, _Package> byName = <String, _Package>{for (final _Package p in packages) p.name: p};
  final List<ArchitectureViolation> violations = <ArchitectureViolation>[];

  for (final _Package package in packages) {
    final Directory lib = Directory('${root.path}/${package.path}/lib');
    if (!lib.existsSync()) {
      continue;
    }
    final List<File> files = _listFiles(lib).where((File file) => file.path.endsWith('.dart')).toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));

    for (final File file in files) {
      final String relativePath = _relative(root, file.path);
      final bool isDomain = package.role == _Role.domain ||
          relativePath.contains('/lib/src/domain/') ||
          relativePath.contains('/lib/domain/');

      for (final RegExpMatch match in _directive.allMatches(file.readAsStringSync())) {
        final String uri = match.group(1)!;
        final String? importedName = uri.startsWith('package:') ? uri.substring(8).split('/').first : null;
        final _Package? imported = importedName == null || importedName == package.name ? null : byName[importedName];
        final bool importsEngine = importedName != null && _storageEnginePackage.hasMatch(importedName);

        void report(String rule) =>
            violations.add(ArchitectureViolation(rule: rule, file: relativePath, import: uri));

        if (package.role != _Role.host &&
            package.feature != null &&
            imported?.feature != null &&
            imported!.feature != package.feature) {
          report(_rule1);
        }
        if (isDomain && (_flutterInDomain.hasMatch(uri) || importsEngine)) {
          report(_rule2);
        }
        if (package.isDesignSystem &&
            importedName != null &&
            importedName != package.name &&
            !_allowedInDesignSystem.contains(importedName)) {
          report(_rule3);
        }
        // core_hardware se admite mientras sus implementaciones pasan a los
        // adaptadores `hardware_*`.
        if (package.role != _Role.adapter &&
            !package.isCoreHardware &&
            importedName != null &&
            _nativeHardwarePackage.hasMatch(importedName)) {
          report(_rule4);
        }
        if (importsEngine && package.role != _Role.adapter) {
          report(_rule5);
        }
        if (imported?.role == _Role.adapter && package.role != _Role.host && package.role != _Role.adapter) {
          report(_rule6);
        }
        if (imported?.role == _Role.plugin && (package.role == _Role.adapter || package.role == _Role.domain)) {
          report(_rule7);
        }
        if (package.role == _Role.contract &&
            (_flutterInDomain.hasMatch(uri) || _contractForbiddenImports.contains(imported?.role))) {
          report(_rule8);
        }
        if (package.role != _Role.adapter && importedName != null && _platformSdkPackage.hasMatch(importedName)) {
          report(_rule9);
        }
      }
    }
  }
  return violations;
}

List<_Package> _findPackages(Directory root) {
  final Map<String, String> names = <String, String>{}; // Ruta → nombre.
  for (final String top in <String>['apps', 'packages']) {
    final Directory dir = Directory('${root.path}/$top');
    if (!dir.existsSync()) {
      continue;
    }
    for (final File pubspec in _listFiles(dir)) {
      if (!pubspec.path.endsWith('/pubspec.yaml')) {
        continue;
      }
      final String? name = _pubspecName.firstMatch(pubspec.readAsStringSync())?.group(1);
      if (name != null) {
        names[_relative(root, pubspec.parent.path)] = name;
      }
    }
  }
  return <_Package>[
    for (final MapEntry<String, String> entry in names.entries) _classify(entry.key, entry.value, names.keys.toSet()),
  ];
}

/// Rol y funcionalidad de un paquete según su ruta. En `packages/plugins/`
/// conviven dos estructuras mientras dura la migración:
/// - `packages/plugins/<plugin>`: el plugin es la funcionalidad completa.
/// - `packages/plugins/<funcionalidad>/<paquete>`: carpeta de funcionalidad
///   con su plugin, su dominio y sus adaptadores.
_Package _classify(String path, String name, Set<String> packagePaths) {
  final List<String> segments = path.split('/');
  if (segments.first == 'apps' || segments.last == 'example') {
    return _Package(name, path, _Role.host, null);
  }
  if (segments.length >= 2 && segments[1] == 'adapters') {
    return _Package(name, path, _Role.adapter, null);
  }
  if (segments.length >= 2 && segments[1] == 'contracts') {
    return _Package(name, path, _Role.contract, null);
  }
  if (segments.length >= 3 && segments[1] == 'plugins') {
    final String feature = segments[2];
    if (segments.length == 3) {
      return _Package(name, path, _Role.plugin, feature);
    }
    final bool featureFolder = !packagePaths.contains(segments.take(3).join('/'));
    if (featureFolder && segments.length == 4) {
      final _Role role = name.startsWith('plugin_')
          ? _Role.plugin
          : name.endsWith('_domain')
              ? _Role.domain
              : _featureAdapterName.hasMatch(name)
                  ? _Role.adapter
                  : _Role.featureOther;
      return _Package(name, path, role, feature);
    }
  }
  return _Package(name, path, _Role.other, null);
}

/// Archivos bajo [dir] sin seguir enlaces simbólicos (Flutter enlaza el
/// código de los plugins de terceros en `ios/.symlinks`) y sin entrar en
/// directorios ocultos ni en `build/`.
Iterable<File> _listFiles(Directory dir) sync* {
  for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
    final String name = entity.uri.pathSegments.lastWhere((String segment) => segment.isNotEmpty);
    if (entity is Directory) {
      if (!name.startsWith('.') && name != 'build') {
        yield* _listFiles(entity);
      }
    } else if (entity is File) {
      yield entity;
    }
  }
}

String _relative(Directory root, String path) {
  final String normalized = path.replaceAll(r'\', '/');
  final String prefix = '${root.absolute.path.replaceAll(r'\', '/')}/';
  return normalized.startsWith(prefix) ? normalized.substring(prefix.length) : normalized;
}
