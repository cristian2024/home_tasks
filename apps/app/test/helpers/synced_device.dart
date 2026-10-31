import 'dart:math';

import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_secrets/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:home_utility_app/sync/sync_services.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/testing.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:plugin_shopping_list/testing.dart';
import 'package:sync_engine/sync_engine.dart';

import 'app_harness.dart';

/// Un dispositivo de la app con la sincronización compuesta sobre dobles en
/// memoria: estado, log, conflictos, secretos, cifrado y un transporte de
/// [network]. Sus repositorios en memoria registran los cambios y participan
/// en la sincronización, como lo harían los adaptadores Isar.
class SyncedDevice {
  SyncedDevice._(this.name, this.harness);

  /// Lo compone. [harness] es la app de este dispositivo, sin pintar.
  static Future<SyncedDevice> create(String name, {required InMemorySyncNetwork network}) async {
    final ServiceLocator locator = ServiceLocator();
    final InMemorySyncStateRepository state = InMemorySyncStateRepository();
    final DeviceIdentity device = DeviceIdentity(deviceId: const UuidV4Generator().newId(), name: name);
    await state.saveDevice(device);
    final HlcClock hlcClock = HlcClock(deviceId: device.deviceId, clock: const SystemClock());
    final InMemoryChangeLog log = InMemoryChangeLog();
    final InMemoryHouseholdItemRepository items = InMemoryHouseholdItemRepository(hlcClock: hlcClock, changeLog: log);
    final InMemoryShoppingListRepository shopping = InMemoryShoppingListRepository(hlcClock: hlcClock, changeLog: log);
    locator
      ..registerSingleton<HlcClock>(hlcClock)
      ..registerSingleton<ChangeLog>(log)
      ..registerSingleton<SyncStateRepository>(state)
      ..registerSingleton<ConflictRepository>(InMemoryConflictRepository())
      ..registerSingleton<SecretStore>(InMemorySecretStore())
      ..registerSingleton<SyncCipher>(FakeSyncCipher(random: Random(name.hashCode)));
    SyncTransports.of(locator).add(network.transport());
    SyncParticipants.of(locator)
      ..add(ItemTrackerSyncParticipant(store: items, repository: items))
      ..add(ShoppingListSyncParticipant(store: shopping, repository: shopping));
    await const SyncModule(debounce: Duration(milliseconds: 10)).register(locator);
    return SyncedDevice._(
      name,
      AppHarness(
        locator: locator,
        includeShoppingList: true,
        items: items,
        shoppingItems: shopping,
        sync: SyncServices.of(locator),
      ),
    );
  }

  final String name;
  final AppHarness harness;

  SyncServices get sync => harness.environment.sync!;

  /// Arranca la sincronización sin pintar la app (otro teléfono).
  Future<void> startHeadless() async {
    await harness.plugins.load();
    await sync.controller.start();
  }

  Future<void> dispose() => harness.dispose();
}
