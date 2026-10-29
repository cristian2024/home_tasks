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

  List<String> rules() =>
      <String>[for (final ArchitectureViolation v in findViolations(root)) v.rule.split(':').first];

  /// Funcionalidad `item_tracker` con la estructura de carpeta: dominio,
  /// plugin (con su ejemplo) y adaptador Isar, más el adaptador base.
  void featureFolder() {
    package('packages/adapters/storage_isar', 'storage_isar');
    package('packages/plugins/item_tracker/item_tracker_domain', 'item_tracker_domain');
    package('packages/plugins/item_tracker/plugin_item_tracker', 'plugin_item_tracker');
    package('packages/plugins/item_tracker/plugin_item_tracker/example', 'item_tracker_example');
    package('packages/plugins/item_tracker/item_tracker_isar', 'item_tracker_isar');
  }

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

  test('una carpeta de funcionalidad que respeta las reglas no tiene violaciones', () {
    featureFolder();
    package('apps/app', 'app');
    source('packages/plugins/item_tracker/item_tracker_domain/lib/item.dart', '''
import 'dart:async';
import 'package:equatable/equatable.dart';
''');
    source('packages/plugins/item_tracker/plugin_item_tracker/lib/plugin.dart', '''
import 'package:flutter/material.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
''');
    source('packages/plugins/item_tracker/item_tracker_isar/lib/repository.dart', '''
import 'package:isar_community/isar.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/storage_isar.dart';
''');
    source('packages/adapters/storage_isar/lib/storage_isar.dart', "export 'package:isar_community/isar.dart';\n");
    source('packages/plugins/item_tracker/plugin_item_tracker/example/lib/main.dart', '''
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:storage_isar/storage_isar.dart';
''');
    source('apps/app/lib/bootstrap.dart', '''
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:storage_isar/storage_isar.dart';
''');

    expect(findViolations(root), isEmpty);
  });

  group('Regla 1', () {
    test('detecta un plugin que importa otro plugin', () {
      package('packages/plugins/plugin_a', 'plugin_a');
      package('packages/plugins/plugin_b', 'plugin_b');
      source('packages/plugins/plugin_a/lib/a.dart', "export 'package:plugin_b/b.dart';\n");

      final List<ArchitectureViolation> violations = findViolations(root);

      expect(rules(), <String>['Regla 1']);
      expect(violations.single.file, 'packages/plugins/plugin_a/lib/a.dart');
      expect(violations.single.import, 'package:plugin_b/b.dart');
    });

    test('detecta una funcionalidad que importa paquetes de otra, en las dos estructuras', () {
      featureFolder();
      package('packages/plugins/notes/notes_domain', 'notes_domain');
      package('packages/plugins/plugin_legacy', 'plugin_legacy');
      source('packages/plugins/notes/notes_domain/lib/a.dart', "import 'package:item_tracker_domain/a.dart';\n");
      source('packages/plugins/plugin_legacy/lib/a.dart', "import 'package:item_tracker_domain/a.dart';\n");
      source('packages/plugins/item_tracker/plugin_item_tracker/lib/a.dart', "import 'package:plugin_legacy/a.dart';\n");

      expect(rules(), <String>['Regla 1', 'Regla 1', 'Regla 1']);
    });

    test('la app de ejemplo de un plugin puede importarlo', () {
      package('packages/plugins/plugin_a', 'plugin_a');
      package('packages/plugins/plugin_a/example', 'plugin_a_example');
      source('packages/plugins/plugin_a/example/lib/main.dart', "import 'package:plugin_a/plugin_a.dart';\n");

      expect(findViolations(root), isEmpty);
    });
  });

  test('Regla 2: detecta Flutter, motores de base de datos y dart:ui en Domain', () {
    package('packages/plugins/plugin_a', 'plugin_a');
    source('packages/plugins/plugin_a/lib/src/domain/item.dart', '''
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import "dart:ui";
''');

    // El motor incumple también la Regla 5.
    expect(rules(), <String>['Regla 2', 'Regla 2', 'Regla 5', 'Regla 2']);
  });

  test('Regla 2: todo un paquete *_domain es Domain', () {
    featureFolder();
    source('packages/plugins/item_tracker/item_tracker_domain/lib/a.dart', '''
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
''');

    // El motor incumple también la Regla 5.
    expect(rules(), <String>['Regla 2', 'Regla 2', 'Regla 5']);
  });

  test('Regla 3: detecta design_system importando infraestructura', () {
    package('packages/design_system', 'design_system');
    source('packages/design_system/lib/a.dart', "import 'package:core_storage/core_storage.dart';\n");

    expect(rules(), <String>['Regla 3']);
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

    expect(rules(), <String>['Regla 4', 'Regla 4', 'Regla 4']);
  });

  group('Regla 5', () {
    test('detecta motores de base de datos fuera de los adaptadores', () {
      featureFolder();
      package('packages/core/core_utils', 'core_utils');
      package('apps/app', 'app');
      source('packages/plugins/item_tracker/plugin_item_tracker/lib/a.dart', '''
import 'package:isar_community/isar.dart';
import 'package:drift/drift.dart';
''');
      source('packages/core/core_utils/lib/a.dart', "import 'package:hive/hive.dart';\n");
      source('apps/app/lib/a.dart', "import 'package:isar/isar.dart';\n");

      expect(rules(), <String>['Regla 5', 'Regla 5', 'Regla 5', 'Regla 5']);
    });
  });

  test('Regla 6: solo las apps, los ejemplos y otros adaptadores importan adaptadores', () {
    featureFolder();
    package('packages/core/core_contracts', 'core_contracts');
    source('packages/plugins/item_tracker/plugin_item_tracker/lib/a.dart', '''
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:storage_isar/storage_isar.dart';
''');
    source('packages/core/core_contracts/lib/a.dart', "import 'package:storage_isar/storage_isar.dart';\n");

    expect(rules(), <String>['Regla 6', 'Regla 6', 'Regla 6']);
  });

  test('Regla 7: un adaptador o un dominio no importa el plugin', () {
    featureFolder();
    package('packages/plugins/plugin_legacy', 'plugin_legacy');
    source('packages/plugins/item_tracker/item_tracker_isar/lib/a.dart',
        "import 'package:plugin_item_tracker/plugin_item_tracker.dart';\n");
    source('packages/plugins/item_tracker/item_tracker_domain/lib/a.dart',
        "import 'package:plugin_item_tracker/plugin_item_tracker.dart';\n");
    source('packages/adapters/storage_isar/lib/a.dart', "import 'package:plugin_legacy/plugin_legacy.dart';\n");

    expect(rules(), <String>['Regla 7', 'Regla 7', 'Regla 7']);
  });

  group('Regla 8', () {
    test('un contrato puede importar otros contratos y paquetes comunes, y las funcionalidades lo importan', () {
      featureFolder();
      package('packages/core/core_events', 'core_events');
      package('packages/contracts/item_tracker_contract', 'item_tracker_contract');
      package('packages/contracts/shopping_list_contract', 'shopping_list_contract');
      source('packages/contracts/shopping_list_contract/lib/a.dart', '''
import 'dart:async';
import 'package:core_events/core_events.dart';
import 'package:item_tracker_contract/item_tracker_contract.dart';
''');
      source('packages/plugins/item_tracker/plugin_item_tracker/lib/a.dart',
          "import 'package:shopping_list_contract/shopping_list_contract.dart';\n");
      source('packages/plugins/item_tracker/item_tracker_domain/lib/a.dart',
          "import 'package:shopping_list_contract/shopping_list_contract.dart';\n");

      expect(findViolations(root), isEmpty);
    });

    test('detecta un contrato que importa Flutter, una funcionalidad o una app', () {
      featureFolder();
      package('apps/app', 'app');
      package('packages/plugins/item_tracker/item_tracker_ui', 'item_tracker_ui');
      package('packages/contracts/shopping_list_contract', 'shopping_list_contract');
      source('packages/contracts/shopping_list_contract/lib/a.dart', '''
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_ui/item_tracker_ui.dart';
import 'package:app/bootstrap.dart';
''');

      expect(rules(), List<String>.filled(6, 'Regla 8'));
    });

    test('un contrato que importa un adaptador lo detecta la regla 6', () {
      featureFolder();
      package('packages/contracts/shopping_list_contract', 'shopping_list_contract');
      source('packages/contracts/shopping_list_contract/lib/a.dart', "import 'package:storage_isar/storage_isar.dart';\n");

      expect(rules(), <String>['Regla 6']);
    });
  });

  test('Regla 9: solo los adaptadores importan SDKs de plataforma', () {
    featureFolder();
    package('packages/adapters/share_native', 'share_native');
    package('packages/core/core_share', 'core_share');
    source('packages/adapters/share_native/lib/a.dart', '''
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
''');
    source('packages/plugins/item_tracker/plugin_item_tracker/lib/a.dart', '''
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
''');
    source('packages/core/core_share/lib/a.dart', '''
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
''');

    expect(rules(), <String>['Regla 9', 'Regla 9', 'Regla 9', 'Regla 9']);
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
