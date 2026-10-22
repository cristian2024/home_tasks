import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Contributor implements StorageSchemaContributor {
  @override
  List<CollectionSchema<dynamic>> get storageSchemas => LocalDatabase.coreSchemas;
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
  List<RouteBase> get routes => const [];

  @override
  Widget buildDashboardTile(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}
}

void main() {
  late Directory directory;
  late Isar isar;
  late IsarPluginPreferenceRepository repository;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('core_storage_test');
    isar = await LocalDatabase.open(directory: directory.path);
    repository = IsarPluginPreferenceRepository(isar);
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
    directory.deleteSync(recursive: true);
  });

  const a = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);
  const b = UserPluginPreference(pluginId: 'b', isEnabled: false, sortOrder: 1);

  test('getAll devuelve vacío sin preferencias', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('save inserta y reemplaza por pluginId', () async {
    await repository.save(a);
    await repository.save(a.copyWith(isEnabled: false));

    expect(await repository.getAll(), [a.copyWith(isEnabled: false)]);
  });

  test('saveAll guarda varias preferencias', () async {
    await repository.saveAll([a, b]);

    expect(await repository.getAll(), unorderedEquals([a, b]));
  });

  test('watch emite el estado inicial y cada cambio', () async {
    final emissions = repository.watch().take(3).toList();

    await repository.save(a);
    await repository.save(b);

    final result = await emissions;
    expect(result[0], isEmpty);
    expect(result[1], [a]);
    expect(result[2], unorderedEquals([a, b]));
  });

  test('las preferencias sobreviven al cierre de la base de datos', () async {
    await repository.saveAll([a, b]);
    await isar.close();

    isar = await LocalDatabase.open(directory: directory.path);

    expect(await IsarPluginPreferenceRepository(isar).getAll(), unorderedEquals([a, b]));
  });

  test('AC-02: la desactivación persiste tras reiniciar la app', () async {
    final registry = PluginRegistry()..register(_Plugin('item_tracker'));
    await PluginLifecycleManager(registry: registry, preferences: repository)
        .setEnabled('item_tracker', enabled: false);
    await isar.close();

    isar = await LocalDatabase.open(directory: directory.path);
    final states = await PluginLifecycleManager(
      registry: registry,
      preferences: IsarPluginPreferenceRepository(isar),
    ).load();

    expect(states.single.status, PluginStatus.disabled);
  });

  group('LocalDatabase', () {
    test('open devuelve la instancia ya abierta', () async {
      expect(await LocalDatabase.open(directory: directory.path), same(isar));
    });

    test('collectSchemas incluye los esquemas core y elimina duplicados idénticos', () {
      final schemas = LocalDatabase.collectSchemas([_Contributor(), _Contributor()]);

      expect(schemas, LocalDatabase.coreSchemas);
    });
  });
}
