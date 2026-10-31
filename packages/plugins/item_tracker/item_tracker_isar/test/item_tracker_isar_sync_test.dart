import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_domain/testing.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_isar/sync_isar.dart';

import 'helpers/isar_fixtures.dart';

/// item_tracker y la sincronización sobre Isar, como los compone una app.
/// Sin [synced], la app no compuso la sincronización (no hay `HlcClock`).
Future<ServiceLocator> _open({bool synced = true}) async {
  final Directory directory = Directory.systemTemp.createTempSync('item_tracker_isar_sync_test');
  final ServiceLocator services = ServiceLocator();
  await IsarStorage(directory: directory.path, features: const <IsarFeature>[ItemTrackerIsar(), SyncIsar()])
      .register(services);
  if (synced) {
    _composeSync(services);
  }
  addTearDown(() async {
    await services.reset();
    directory.deleteSync(recursive: true);
  });
  return services;
}

void _composeSync(ServiceLocator services) => services.registerSingleton<HlcClock>(
      HlcClock(deviceId: 'device-local', clock: FixedClock(DateTime.utc(2026, 10, 31))),
    );

Future<ItemTrackerSyncSubject> _subject() async {
  final ServiceLocator services = await _open();
  return ItemTrackerSyncSubject(
    repository: services.get<HouseholdItemRepository>(),
    participant: SyncParticipants.of(services).forCollection(ItemTrackerCollections.items)! as ItemTrackerSyncParticipant,
    log: services.get<ChangeLog>(),
  );
}

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  itemTrackerSyncContract('Isar', create: _subject);
  householdItemRepositoryContract(
    'Isar, sincronizado',
    create: () async => (await _open()).get<HouseholdItemRepository>(),
  );

  group('ItemTrackerIsar con sincronización', () {
    test('añade su participante a SyncParticipants', () async {
      final ServiceLocator services = await _open();

      expect(SyncParticipants.of(services).all.single, isA<ItemTrackerSyncParticipant>());
      expect(SyncParticipants.of(services).forCollection(ItemTrackerCollections.events), isNotNull);
    });

    test('sin la sincronización compuesta no registra nada', () async {
      final ServiceLocator services = await _open(synced: false);
      final HouseholdItemRepository repository = services.get<HouseholdItemRepository>();

      await repository.createItem(item(), identifier: identifier(), events: <ItemEvent>[event('e1')]);

      expect(await services.get<ChangeLog>().vector(), VersionVector.empty);
      expect(await (repository as ItemTrackerSyncStore).syncedEntities(ItemTrackerCollections.items), isEmpty);
    });

    test('migra una vez lo guardado antes, con marcas de sus fechas', () async {
      final ServiceLocator services = await _open(synced: false);
      final HouseholdItemRepository repository = services.get<HouseholdItemRepository>();
      final ItemTrackerSyncStore store = repository as ItemTrackerSyncStore;
      await repository.createItem(item(), identifier: identifier(), events: <ItemEvent>[event('e1')]);
      await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const <ItemEvent>[]);
      await repository.deleteItems(<String>['item-2'], deletedAt: t0.add(const Duration(hours: 1)), events: const <ItemEvent>[]);
      _composeSync(services);

      final List<SyncedEntity> items = await store.syncedEntities(ItemTrackerCollections.items);
      await store.syncedEntities(ItemTrackerCollections.items);

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.collection), <String>[
        ItemTrackerCollections.items,
        ItemTrackerCollections.items,
        ItemTrackerCollections.identifiers,
        ItemTrackerCollections.events,
      ]);
      expect(records.first.hlc, Hlc(wallTime: t0.millisecondsSinceEpoch, counter: 0, deviceId: 'device-local'));
      expect(items.map(ItemTrackerCodec.itemOf).map((HouseholdItem? item) => item?.id), unorderedEquals(<String>['item-1', 'item-2']));
      expect(items.map(ItemTrackerCodec.deletedAtOf).whereType<DateTime>(), <DateTime>[t0.add(const Duration(hours: 1))]);
    });

    test('la migración también se hace al escribir y no se repite', () async {
      final ServiceLocator services = await _open(synced: false);
      final HouseholdItemRepository repository = services.get<HouseholdItemRepository>();
      await repository.createItem(item(), events: const <ItemEvent>[]);
      _composeSync(services);

      await repository.updateItem(item(name: 'Caja azul'), event('e2'));
      await repository.addEvent(event('e3'));

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.seq), <int>[1, 2, 3, 4]);
      expect(records[1].changes, <FieldChange>[ValueChange('name', 'Caja azul')]);
    });
  });
}
