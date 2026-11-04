import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_isar/sync_isar.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 28, 9);

/// La lista de compras y la sincronización sobre Isar, como las compone una
/// app. Sin [synced], la app no compuso la sincronización (no hay
/// `HlcClock`).
Future<ServiceLocator> _open({bool synced = true}) async {
  final Directory directory = Directory.systemTemp.createTempSync('shopping_list_isar_sync_test');
  final ServiceLocator services = ServiceLocator();
  await IsarStorage(directory: directory.path, features: const <IsarFeature>[ShoppingListIsar(), SyncIsar()])
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

Future<ShoppingListSyncSubject> _subject() async {
  final ServiceLocator services = await _open();
  return ShoppingListSyncSubject(
    repository: services.get<ShoppingListRepository>(),
    participant:
        SyncParticipants.of(services).forCollection(ShoppingListCollections.items)! as ShoppingListSyncParticipant,
    log: services.get<ChangeLog>(),
  );
}

ShoppingItem _item(String id, {DateTime? updatedAt}) => ShoppingItem(
      id: id,
      name: 'Huevos',
      urgency: Urgency.normal,
      status: ShoppingItemStatus.pending,
      createdAt: _t0,
      updatedAt: updatedAt ?? _t0,
    );

ShoppingPurchase _purchase(String id, int day) =>
    ShoppingPurchase(id: id, itemId: 'i1', purchasedAt: _t0.add(Duration(days: day)));

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  shoppingListSyncContract('Isar', create: _subject);
  shoppingListRepositoryContract(
    'Isar, sincronizado',
    create: () async => (await _open()).get<ShoppingListRepository>(),
  );

  group('ShoppingListIsar con sincronización', () {
    test('añade su participante a SyncParticipants', () async {
      final ServiceLocator services = await _open();

      expect(SyncParticipants.of(services).all.single, isA<ShoppingListSyncParticipant>());
      expect(SyncParticipants.of(services).forCollection(ShoppingListCollections.purchases), isNotNull);
    });

    test('sin la sincronización compuesta no registra nada', () async {
      final ServiceLocator services = await _open(synced: false);
      final ShoppingListRepository repository = services.get<ShoppingListRepository>();

      await repository.saveItem(_item('i1'));

      expect(await services.get<ChangeLog>().vector(), VersionVector.empty);
      expect(await (repository as ShoppingListSyncStore).syncedEntities(ShoppingListCollections.items), isEmpty);
    });

    test('migra una vez lo guardado antes: lo borrado, borrado, y las compras encadenadas', () async {
      final ServiceLocator services = await _open(synced: false);
      final ShoppingListRepository repository = services.get<ShoppingListRepository>();
      final ShoppingListSyncStore store = repository as ShoppingListSyncStore;
      await repository.seedDefaultCategories(<ShoppingCategory>[const ShoppingCategory(id: 'c1', sortOrder: 0, defaultKey: 'food')]);
      await repository.saveItem(_item('i1'));
      await repository.saveItem(_item('i2'));
      await repository.recordPurchase(_item('i1'), _purchase('p2', 2));
      await repository.recordPurchase(_item('i1'), _purchase('p1', 1));
      await repository.deleteItems(<String>['i2'], deletedAt: _t0.add(const Duration(hours: 1)));
      _composeSync(services);

      final List<SyncedEntity> items = await store.syncedEntities(ShoppingListCollections.items);
      final List<SyncedEntity> purchases = await store.syncedEntities(ShoppingListCollections.purchases);
      await store.syncedEntities(ShoppingListCollections.items);

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.collection), <String>[
        ShoppingListCollections.categories,
        ShoppingListCollections.items,
        ShoppingListCollections.items,
        ShoppingListCollections.purchases,
        ShoppingListCollections.purchases,
      ]);
      expect(records.first.hlc, Hlc(wallTime: 0, counter: 0, deviceId: 'device-local'));
      expect(items.map(ShoppingListCodec.deletedAtOf).whereType<DateTime>(), <DateTime>[_t0.add(const Duration(hours: 1))]);
      expect(
        <String, String?>{for (final SyncedEntity p in purchases) p.id: ShoppingListCodec.previousPurchaseOf(p)},
        <String, String?>{'p1': null, 'p2': 'p1'},
      );
    });

    test('la migración también se hace al escribir y no se repite', () async {
      final ServiceLocator services = await _open(synced: false);
      final ShoppingListRepository repository = services.get<ShoppingListRepository>();
      await repository.saveItem(_item('i1'));
      _composeSync(services);

      await repository.saveItem(_item('i1', updatedAt: _t0.add(const Duration(days: 1))));
      await repository.saveItem(_item('i2'));

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.seq), <int>[1, 2, 3]);
      expect(records[1].changes, <FieldChange>[ValueChange('updatedAt', _t0.add(const Duration(days: 1)).toIso8601String())]);
    });
  });
}
