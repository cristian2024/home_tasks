import 'dart:io';

import 'package:test/test.dart';

import '../src/architecture_rules.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('arch_rules_test').absolute);
  tearDown(() => root.deleteSync(recursive: true));

  void package(String path, String name) {
    File('${root.path}/$path/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('name: $name\n');
  }

  void source(String path, String content) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  List<String> rules() => [for (final v in findViolations(root)) v.rule.split(':').first];

  test('un monorepo que respeta las reglas no tiene violaciones', () {
    package('packages/core/core_contracts', 'core_contracts');
    package('packages/plugins/plugin_a', 'plugin_a');
    package('packages/design_system', 'design_system');
    source('packages/plugins/plugin_a/lib/src/domain/item.dart', '''
import 'package:core_contracts/core_contracts.dart';
import 'package:plugin_a/src/domain/other.dart';
import 'dart:async';
''');
    source('packages/plugins/plugin_a/lib/src/presentation/screen.dart',
        "import 'package:flutter/material.dart';\n");
    source('packages/design_system/lib/theme.dart', '''
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/tokens.dart';
''');

    expect(findViolations(root), isEmpty);
  });

  test('Regla 1: detecta un plugin que importa otro plugin', () {
    package('packages/plugins/plugin_a', 'plugin_a');
    package('packages/plugins/plugin_b', 'plugin_b');
    source('packages/plugins/plugin_a/lib/a.dart', "export 'package:plugin_b/b.dart';\n");

    final violations = findViolations(root);

    expect(rules(), ['Regla 1']);
    expect(violations.single.file, 'packages/plugins/plugin_a/lib/a.dart');
    expect(violations.single.import, 'package:plugin_b/b.dart');
  });

  test('Regla 1: la app de ejemplo de un plugin puede importarlo', () {
    package('packages/plugins/plugin_a', 'plugin_a');
    package('packages/plugins/plugin_a/example', 'plugin_a_example');
    source('packages/plugins/plugin_a/example/lib/main.dart', "import 'package:plugin_a/plugin_a.dart';\n");

    expect(findViolations(root), isEmpty);
  });

  test('Regla 2: detecta Flutter, Isar y dart:ui en Domain', () {
    package('packages/plugins/plugin_a', 'plugin_a');
    source('packages/plugins/plugin_a/lib/src/domain/item.dart', '''
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:isar_community/isar.dart';
import "dart:ui";
''');

    expect(rules(), ['Regla 2', 'Regla 2', 'Regla 2', 'Regla 2']);
  });

  test('Regla 3: detecta design_system importando infraestructura', () {
    package('packages/design_system', 'design_system');
    source('packages/design_system/lib/a.dart', "import 'package:core_storage/core_storage.dart';\n");

    expect(rules(), ['Regla 3']);
  });

  test('Regla 4: solo core_hardware importa SDKs nativos de hardware', () {
    package('packages/core/core_hardware', 'core_hardware');
    package('packages/plugins/plugin_a', 'plugin_a');
    source('packages/core/core_hardware/lib/a.dart', '''
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
''');
    source('packages/plugins/plugin_a/lib/src/presentation/scan.dart', '''
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';
''');

    expect(rules(), ['Regla 4', 'Regla 4', 'Regla 4']);
  });

  test('ignora enlaces simbólicos, directorios ocultos y build/', () {
    package('packages/core/core_hardware/example', 'example');
    package('third_party/plugin', 'third_party');
    source('third_party/plugin/lib/a.dart', "import 'package:nfc_manager/nfc_manager.dart';\n");
    Link('${root.path}/packages/core/core_hardware/example/ios_symlink')
        .createSync('${root.path}/third_party/plugin');
    package('packages/core/core_hardware/example/ios/.symlinks/plugins/x', 'x');
    source(
      'packages/core/core_hardware/example/ios/.symlinks/plugins/x/lib/a.dart',
      "import 'package:mobile_scanner/mobile_scanner.dart';\n",
    );
    source('packages/core/core_hardware/example/build/lib/a.dart', "import 'package:mobile_scanner/m.dart';\n");

    expect(findViolations(root), isEmpty);
  });

  test('ignora archivos fuera de lib/', () {
    package('packages/plugins/plugin_a', 'plugin_a');
    package('packages/plugins/plugin_b', 'plugin_b');
    source('packages/plugins/plugin_a/test/a_test.dart', "import 'package:plugin_b/b.dart';\n");

    expect(findViolations(root), isEmpty);
  });
}
