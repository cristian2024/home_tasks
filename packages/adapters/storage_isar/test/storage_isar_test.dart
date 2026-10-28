import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:core_di/core_di.dart';
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
}
