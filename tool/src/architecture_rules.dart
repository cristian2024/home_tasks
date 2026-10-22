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

const _rule1 = 'Regla 1: un plugin no puede importar otro plugin';
const _rule2 = 'Regla 2: Domain no puede importar Flutter ni persistencia';
const _rule3 = 'Regla 3: design_system solo depende de Flutter y core_ui';
const _rule4 = 'Regla 4: solo core_hardware importa SDKs nativos de hardware';

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
final _pubspecName = RegExp(r'^name:\s*(\S+)', multiLine: true);
final _forbiddenInDomain = RegExp(r'^(package:(flutter|isar)\w*/|dart:ui$)');
const _allowedInDesignSystem = {'flutter', 'core_ui'};
final _nativeHardwarePackage = RegExp(r'^(mobile_scanner|nfc_manager\w*|permission_handler\w*)$');

class _Package {
  final String name;
  final String path; // Relativo a la raíz, con '/'.

  _Package(this.name, this.path);

  bool get isPlugin => path.startsWith('packages/plugins/');
  bool get isDesignSystem => path == 'packages/design_system';
  bool get isCoreHardware => path == 'packages/core/core_hardware';
}

/// Recorre `lib/` de cada paquete bajo `apps/` y `packages/` en [root] y
/// devuelve las violaciones de las reglas de importación.
List<ArchitectureViolation> findViolations(Directory root) {
  final packages = _findPackages(root);
  final pluginNames = {for (final p in packages) if (p.isPlugin) p.name};
  final violations = <ArchitectureViolation>[];

  for (final package in packages) {
    final lib = Directory('${root.path}/${package.path}/lib');
    if (!lib.existsSync()) {
      continue;
    }
    final files = _listFiles(lib)
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final relativePath = _relative(root, file.path);
      final isDomain = relativePath.contains('/lib/src/domain/') ||
          relativePath.contains('/lib/domain/');

      for (final match in _directive.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        final importedPackage = uri.startsWith('package:') ? uri.substring(8).split('/').first : null;

        void report(String rule) =>
            violations.add(ArchitectureViolation(rule: rule, file: relativePath, import: uri));

        if (package.isPlugin &&
            importedPackage != null &&
            importedPackage != package.name &&
            pluginNames.contains(importedPackage)) {
          report(_rule1);
        }
        if (isDomain && _forbiddenInDomain.hasMatch(uri)) {
          report(_rule2);
        }
        if (package.isDesignSystem &&
            importedPackage != null &&
            importedPackage != package.name &&
            !_allowedInDesignSystem.contains(importedPackage)) {
          report(_rule3);
        }
        if (!package.isCoreHardware &&
            importedPackage != null &&
            _nativeHardwarePackage.hasMatch(importedPackage)) {
          report(_rule4);
        }
      }
    }
  }
  return violations;
}

List<_Package> _findPackages(Directory root) {
  final packages = <_Package>[];
  for (final top in ['apps', 'packages']) {
    final dir = Directory('${root.path}/$top');
    if (!dir.existsSync()) {
      continue;
    }
    for (final pubspec in _listFiles(dir)) {
      if (!pubspec.path.endsWith('/pubspec.yaml')) {
        continue;
      }
      final name = _pubspecName.firstMatch(pubspec.readAsStringSync())?.group(1);
      if (name != null) {
        packages.add(_Package(name, _relative(root, pubspec.parent.path)));
      }
    }
  }
  return packages;
}

/// Archivos bajo [dir] sin seguir enlaces simbólicos (Flutter enlaza el
/// código de los plugins de terceros en `ios/.symlinks`) y sin entrar en
/// directorios ocultos ni en `build/`.
Iterable<File> _listFiles(Directory dir) sync* {
  for (final entity in dir.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
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
  final normalized = path.replaceAll(r'\', '/');
  final prefix = '${root.absolute.path.replaceAll(r'\', '/')}/';
  return normalized.startsWith(prefix) ? normalized.substring(prefix.length) : normalized;
}
