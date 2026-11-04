import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_spaces/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/src/isar_database.dart';
import 'package:storage_isar/src/plugin_preferences/isar_plugin_preference.dart';
import 'package:storage_isar/src/plugin_preferences/isar_plugin_preference_repository.dart';
import 'package:storage_isar/storage_isar.dart';

/// Funcionalidad de prueba: anota con qué base y locator la conectan.
class _Feature implements IsarFeature {
  Isar? isar;
  ServiceLocator? services;

  @override
  List<CollectionSchema<dynamic>> get schemas => IsarDatabase.coreSchemas;

  @override
  void register(ServiceLocator services, Isar isar) {
    this.services = services;
    this.isar = isar;
  }
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

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() => directory = Directory.systemTemp.createTempSync('storage_isar_test'));
  tearDown(() => directory.deleteSync(recursive: true));

  group('IsarPluginPreferenceRepository', () {
    late Isar isar;

    setUp(() async => isar = await IsarDatabase.open(directory: directory.path));
    tearDown(() async {
      if (isar.isOpen) {
        await isar.close(deleteFromDisk: true);
      }
    });

    pluginPreferenceRepositoryContract(
      'Isar',
      create: () async {
        await isar.writeTxn(isar.clear);
        return IsarPluginPreferenceRepository(isar);
      },
    );

    test('las preferencias sobreviven al cierre de la base de datos', () async {
      const UserPluginPreference a = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);
      const UserPluginPreference b = UserPluginPreference(pluginId: 'b', isEnabled: false, sortOrder: 1);
      await IsarPluginPreferenceRepository(isar).saveAll(<UserPluginPreference>[a, b]);
      await isar.close();

      isar = await IsarDatabase.open(directory: directory.path);

      expect(await IsarPluginPreferenceRepository(isar).getAll(), unorderedEquals(<UserPluginPreference>[a, b]));
    });

    test('la colección conserva el nombre y el id de core_storage: los datos guardados se siguen leyendo', () {
      expect(IsarPluginPreferenceSchema.name, 'IsarPluginPreference');
      expect(IsarPluginPreferenceSchema.id, 8780927744613002501);
    });
  });

  group('IsarStorage', () {
    late ServiceLocator services;

    setUp(() => services = ServiceLocator());
    tearDown(() => services.reset());

    test('registra PluginPreferenceRepository y conecta cada funcionalidad a la misma base', () async {
      final _Feature first = _Feature();
      final _Feature second = _Feature();

      await IsarStorage(directory: directory.path, features: <IsarFeature>[first, second]).register(services);

      expect(services.get<PluginPreferenceRepository>(), isA<IsarPluginPreferenceRepository>());
      expect(first.services, same(services));
      expect(first.isar?.isOpen, isTrue);
      expect(second.isar, same(first.isar));
    });

    test('reset del locator cierra la base de datos', () async {
      final _Feature feature = _Feature();
      await IsarStorage(directory: directory.path, features: <IsarFeature>[feature]).register(services);

      await services.reset();

      expect(feature.isar?.isOpen, isFalse);
    });

    test('AC-02: la desactivación persiste tras reiniciar la app', () async {
      final PluginRegistry registry = PluginRegistry()..register(_Plugin('item_tracker'));
      await IsarStorage(directory: directory.path).register(services);
      await PluginLifecycleManager(registry: registry, preferences: services.get<PluginPreferenceRepository>())
          .setEnabled('item_tracker', enabled: false);
      await services.reset();

      await IsarStorage(directory: directory.path).register(services);
      final List<PluginState> states = await PluginLifecycleManager(
        registry: registry,
        preferences: services.get<PluginPreferenceRepository>(),
      ).load();

      expect(states.single.status, PluginStatus.disabled);
    });
  });

  group('IsarDatabase', () {
    test('open devuelve la instancia ya abierta', () async {
      final Isar isar = await IsarDatabase.open(directory: directory.path);
      addTearDown(isar.close);

      expect(await IsarDatabase.open(directory: directory.path), same(isar));
    });

    test('collectSchemas incluye los esquemas core y elimina duplicados idénticos', () {
      expect(IsarDatabase.collectSchemas(<IsarFeature>[_Feature(), _Feature()]), IsarDatabase.coreSchemas);
    });
  });

  group('IsarSpaceStorage', () {
    dataSpaceStorageContract('IsarSpaceStorage', create: () {
      final Directory folder = Directory.systemTemp.createTempSync('isar_space_storage_test');
      addTearDown(() => folder.deleteSync(recursive: true));
      final Map<String, Isar> open = <String, Isar>{};
      addTearDown(() async {
        for (final Isar isar in open.values) {
          if (isar.isOpen) {
            await isar.close();
          }
        }
      });
      Future<Isar> openDatabase(String name) async =>
          open[name] = await IsarDatabase.open(directory: folder.path, name: name);
      return DataSpaceStorageHarness(
        storage: IsarSpaceStorage(directory: folder.path),
        create: (String name) async {
          final Isar isar = await openDatabase(name);
          await IsarPluginPreferenceRepository(isar)
              .saveAll(const <UserPluginPreference>[UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0)]);
          await isar.close();
        },
        open: (String name) async => openDatabase(name),
        close: (String name) async => open[name]!.close(),
      );
    });

    test('databaseNames de una carpeta que no existe está vacío', () async {
      expect(await IsarSpaceStorage(directory: '${directory.path}/nada').databaseNames(), isEmpty);
    });

    test('una base borrada se vuelve a abrir vacía', () async {
      final IsarSpaceStorage storage = IsarSpaceStorage(directory: directory.path);
      final Isar isar = await IsarDatabase.open(directory: directory.path, name: 'space_a');
      await IsarPluginPreferenceRepository(isar)
          .saveAll(const <UserPluginPreference>[UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0)]);
      await isar.close();

      await storage.delete('space_a');
      final Isar reopened = await IsarDatabase.open(directory: directory.path, name: 'space_a');
      addTearDown(reopened.close);

      expect(await IsarPluginPreferenceRepository(reopened).getAll(), isEmpty);
    });
  });

  test('dos espacios (bases con otro nombre) no comparten datos ni preferencias', () async {
    final ServiceLocator first = ServiceLocator();
    final ServiceLocator second = ServiceLocator();
    await IsarStorage(directory: directory.path, name: DataSpace.databaseNameFor('casa')).register(first);
    await IsarStorage(directory: directory.path, name: DataSpace.databaseNameFor('oficina')).register(second);

    await first
        .get<PluginPreferenceRepository>()
        .saveAll(const <UserPluginPreference>[UserPluginPreference(pluginId: 'a', isEnabled: false, sortOrder: 0)]);

    expect(await second.get<PluginPreferenceRepository>().getAll(), isEmpty);
    expect(await first.get<PluginPreferenceRepository>().getAll(), hasLength(1));
    await first.reset();
    await second.reset();
  });
}
