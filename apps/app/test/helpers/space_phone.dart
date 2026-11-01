import 'dart:io';
import 'dart:math';

import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_app_shortcuts/testing.dart';
import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_secrets/testing.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_spaces/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:home_utility_app/spaces/device_environment.dart';
import 'package:home_utility_app/spaces/space_bootstrap.dart';
import 'package:home_utility_app/spaces/space_switcher.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_isar/sync_isar.dart';

import 'in_memory_app_settings_repository.dart';

/// Hardware falso en lugar de los adaptadores nativos.
class _FakeHardware implements DependencyModule {
  const _FakeHardware();

  @override
  Future<void> register(ServiceLocator services) async => services
    ..registerFactory<CameraIdentifierScanner>(FakeCameraScanner.new)
    ..registerFactory<NfcIdentifierScanner>(FakeNfcScanner.new)
    ..registerSingleton<HardwarePermissions>(FakeHardwarePermissions());
}

/// El almacén de secretos del teléfono (compartido por todos sus espacios,
/// como el Keychain), cifrado falso y la red en memoria.
class _FakeSyncPlatform implements DependencyModule {
  const _FakeSyncPlatform(this.network, this.secrets);

  final InMemorySyncNetwork network;
  final SecretStore secrets;

  @override
  Future<void> register(ServiceLocator services) async {
    services
      ..registerSingleton<SecretStore>(secrets)
      ..registerSingleton<SyncCipher>(FakeSyncCipher(random: Random(secrets.hashCode)));
    SyncTransports.of(services).add(network.transport());
  }
}

/// Un teléfono con espacios de datos: Isar real en su carpeta temporal, la
/// lista de espacios y los accesos rápidos en memoria, un almacén de secretos
/// para todos sus espacios y la sincronización sobre [network]. Arranca como
/// `main` ([start]).
class SpacePhone {
  SpacePhone(this.name, {required this.network}) : folder = Directory.systemTemp.createTempSync('spaces_$name');

  final String name;
  final InMemorySyncNetwork network;
  final Directory folder;
  final InMemoryDataSpaceDirectory spaces = InMemoryDataSpaceDirectory();
  final InMemorySecretStore secrets = InMemorySecretStore();
  final FakeAppShortcutService shortcuts = FakeAppShortcutService();
  late final DeviceEnvironment device = DeviceEnvironment(
    locator: ServiceLocator()
      ..registerSingleton<DataSpaceDirectory>(spaces)
      ..registerSingleton<AppShortcutService>(shortcuts),
    spaceStorage: IsarSpaceStorage(directory: folder.path),
  );
  late SpaceSwitcher switcher;

  /// Espacios que no se pueden abrir (para probar la vuelta atrás).
  final Set<String> failingSpaces = <String>{};

  AppEnvironment get app => switcher.state.environment;

  Future<AppEnvironment> open(DataSpace space, {String? deviceName}) async {
    if (failingSpaces.contains(space.id)) {
      throw StateError('No se puede abrir ${space.id}');
    }
    return bootstrapApp(
      systemLanguageCode: 'es',
      device: device,
      space: space,
      settingsRepository: InMemoryAppSettingsRepository(),
      locator: ServiceLocator(),
      localization: LocalizationCoordinator(),
      adapters: <DependencyModule>[
        IsarStorage(
          directory: folder.path,
          name: space.databaseName,
          features: const <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar(), SyncIsar()],
        ),
        const _FakeHardware(),
        _FakeSyncPlatform(network, secrets),
        SyncModule(deviceName: deviceName ?? name, debounce: const Duration(milliseconds: 10)),
      ],
    );
  }

  /// Como `main`: el espacio activo (o el primero, sobre la base de siempre)
  /// y su entorno.
  Future<SpaceSwitcher> start() async => switcher = await bootstrapSpaces(
        device: device,
        open: open,
        defaultName: 'Mi espacio',
        newSpaceName: (int number) => 'Espacio $number',
      );

  /// Espera a que [condition] se cumpla (p. ej. que el hogar se anote en la
  /// lista), como mucho unos segundos.
  Future<void> until(Future<bool> Function() condition) async {
    for (int i = 0; i < 200; i++) {
      if (await condition()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('No se cumplió la condición a tiempo');
  }

  Future<void> dispose() async {
    await app.dispose();
    await switcher.close();
    await shortcuts.dispose();
    folder.deleteSync(recursive: true);
  }
}
