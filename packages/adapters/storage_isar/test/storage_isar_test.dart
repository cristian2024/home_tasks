import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:storage_isar/src/plugin_preferences/isar_plugin_preference.dart';
import 'package:storage_isar/storage_isar.dart';

class _Module implements IsarSchemaModule {
  @override
  List<CollectionSchema<dynamic>> get schemas => IsarDatabase.coreSchemas;
}

class _Plugin implements HomePlugin {
  _Plugin(this.id);

  @override
  final String id;

  @override
  String get nameKey => id;

  @override
  String get descriptionKey => id;

  @override
  IconData get icon => const IconData(0xe000);

  @override
  String get version => '1.0.0';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> initialize() async {}

  @override
  List<RouteBase> get routes => const <RouteBase>[];

  @override
  Widget buildDashboardTile(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}
}

void main() {
  late Directory directory;
  late Isar isar;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('storage_isar_test');
    isar = await IsarDatabase.open(directory: directory.path);
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    directory.deleteSync(recursive: true);
  });

  pluginPreferenceRepositoryContract(
    'Isar',
    create: () async {
      await isar.writeTxn(isar.clear);
      return IsarPluginPreferenceRepository(isar);
    },
  );

  group('IsarPluginPreferenceRepository', () {
    const UserPluginPreference a = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);
    const UserPluginPreference b = UserPluginPreference(pluginId: 'b', isEnabled: false, sortOrder: 1);

    test('las preferencias sobreviven al cierre de la base de datos', () async {
      await IsarPluginPreferenceRepository(isar).saveAll(<UserPluginPreference>[a, b]);
      await isar.close();

      isar = await IsarDatabase.open(directory: directory.path);

      expect(await IsarPluginPreferenceRepository(isar).getAll(), unorderedEquals(<UserPluginPreference>[a, b]));
    });

    test('AC-02: la desactivación persiste tras reiniciar la app', () async {
      final PluginRegistry registry = PluginRegistry()..register(_Plugin('item_tracker'));
      await PluginLifecycleManager(registry: registry, preferences: IsarPluginPreferenceRepository(isar))
          .setEnabled('item_tracker', enabled: false);
      await isar.close();

      isar = await IsarDatabase.open(directory: directory.path);
      final List<PluginState> states = await PluginLifecycleManager(
        registry: registry,
        preferences: IsarPluginPreferenceRepository(isar),
      ).load();

      expect(states.single.status, PluginStatus.disabled);
    });

    test('la colección conserva el nombre y el id de core_storage: los datos guardados se siguen leyendo', () {
      expect(IsarPluginPreferenceSchema.name, 'IsarPluginPreference');
      expect(IsarPluginPreferenceSchema.id, 8780927744613002501);
    });
  });

  group('IsarDatabase', () {
    test('open devuelve la instancia ya abierta', () async {
      expect(await IsarDatabase.open(directory: directory.path), same(isar));
    });

    test('collectSchemas incluye los esquemas core y elimina duplicados idénticos', () {
      expect(IsarDatabase.collectSchemas(<IsarSchemaModule>[_Module(), _Module()]), IsarDatabase.coreSchemas);
    });
  });
}
