import 'dart:io';

import 'package:core_events/core_events.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/data/models/isar_physical_identifier.dart';
import 'package:plugin_item_tracker/testing.dart';

import '../helpers/domain_fixtures.dart';

class _Plugin implements StorageSchemaContributor {
  @override
  List<CollectionSchema<dynamic>> get storageSchemas => itemTrackerSchemas;
}

/// Base Isar en un directorio temporal, que se borra al cerrarla.
Future<({Isar isar, Directory directory})> _openDatabase() async {
  final Directory directory = Directory.systemTemp.createTempSync('item_tracker_test');
  final Isar isar =
      await LocalDatabase.open(directory: directory.path, contributors: <StorageSchemaContributor>[_Plugin()]);
  return (isar: isar, directory: directory);
}

Future<void> _closeDatabase(({Isar isar, Directory directory}) database) async {
  await database.isar.close(deleteFromDisk: true);
  database.directory.deleteSync(recursive: true);
}

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  final Map<HouseholdItemRepository, ({Isar isar, Directory directory})> databases =
      <HouseholdItemRepository, ({Isar isar, Directory directory})>{};
  householdItemRepositoryContract(
    'Isar',
    create: () async {
      final ({Isar isar, Directory directory}) database = await _openDatabase();
      final IsarHouseholdItemRepository repository = IsarHouseholdItemRepository(database.isar);
      databases[repository] = database;
      return repository;
    },
    dispose: (HouseholdItemRepository repository) => _closeDatabase(databases.remove(repository)!),
  );

  // Lo propio de Isar (borrado lógico en la colección) y los casos de uso
  // sobre la base real. El resto lo cubre el contrato.
  group('IsarHouseholdItemRepository', () {
    late ({Isar isar, Directory directory}) database;
    late Isar isar;
    late IsarHouseholdItemRepository repository;

    setUp(() async {
      database = await _openDatabase();
      isar = database.isar;
      repository = IsarHouseholdItemRepository(isar);
    });

    tearDown(() => _closeDatabase(database));

    ItemEvent event(String id, {String itemId = 'item-1', ItemEventKind kind = ItemEventKind.note}) =>
        ItemEvent(id: id, itemId: itemId, kind: kind, title: id, description: '', timestamp: t0);

    PhysicalIdentifier ident(String id, String rawValue, IdentifierType type, {String itemId = 'item-1'}) =>
        PhysicalIdentifier(id: id, rawValue: rawValue, type: type, itemId: itemId, boundAt: t0);

    test('AC-03/AC-04: busca por identificador conocido y desconocido', () async {
      await repository.createItem(
        item(),
        identifier: ident('i1', 'QR-123', IdentifierType.qr),
        events: const <ItemEvent>[],
      );

      final HouseholdItem? found = await FindItemByIdentifier(repository)(rawValue: 'QR-123', type: IdentifierType.qr);

      expect(found?.name, 'Caja A');
      expect(await FindItemByIdentifier(repository)(rawValue: 'UNKNOWN-99', type: IdentifierType.qr), isNull);
    });

    test('AC-05: dos identificadores de distinto tipo devuelven el mismo objeto', () async {
      await repository.createItem(
        item(name: 'Cama'),
        identifier: ident('i1', 'QR-BED', IdentifierType.qr),
        events: const <ItemEvent>[],
      );
      await repository.bindIdentifier(ident('i2', 'NFC-BED', IdentifierType.nfc), event('e1'));

      final FindItemByIdentifier find = FindItemByIdentifier(repository);
      final HouseholdItem? byQr = await find(rawValue: 'QR-BED', type: IdentifierType.qr);
      final HouseholdItem? byNfc = await find(rawValue: 'NFC-BED', type: IdentifierType.nfc);

      expect(byQr, isNotNull);
      expect(byQr, byNfc);
      expect(
        (await repository.watchIdentifiers('item-1').first).map((PhysicalIdentifier i) => i.rawValue),
        <String>['QR-BED', 'NFC-BED'],
      );
    });

    group('quitar un identificador (borrado lógico)', () {
      setUp(() async {
        await repository.createItem(
          item(),
          identifier: ident('i1', 'QR-123', IdentifierType.qr),
          events: const <ItemEvent>[],
        );
        await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const <ItemEvent>[]);
      });

      test('deja de contar en búsquedas y listados pero se conserva marcado', () async {
        expect(await repository.getIdentifier('i1'), ident('i1', 'QR-123', IdentifierType.qr));
        final DateTime deletedAt = t0.add(const Duration(hours: 1));
        await repository.unbindIdentifier(
          'i1',
          deletedAt: deletedAt,
          event: event('e1', kind: ItemEventKind.identifierUnbound),
        );

        expect(await repository.findIdentifier('QR-123', IdentifierType.qr), isNull);
        expect(await repository.getIdentifier('i1'), isNull);
        expect(await repository.watchIdentifiers('item-1').first, isEmpty);
        expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.identifierUnbound);
        final IsarPhysicalIdentifier? stored = await isar.isarPhysicalIdentifiers.getById('i1');
        expect(stored?.isDeleted, isTrue);
        expect(stored?.deletedAt?.toUtc(), deletedAt);
      });

      test('el mismo valor y tipo se puede asociar de nuevo, y quitar otra vez', () async {
        await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e1'));
        await repository.bindIdentifier(
          ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'),
          event('e2', itemId: 'item-2'),
        );

        expect((await repository.findIdentifier('QR-123', IdentifierType.qr))?.itemId, 'item-2');

        await repository.unbindIdentifier('i2', deletedAt: t0, event: event('e3', itemId: 'item-2'));
        await repository.bindIdentifier(ident('i3', 'QR-123', IdentifierType.qr), event('e4'));
        expect((await repository.findIdentifier('QR-123', IdentifierType.qr))?.id, 'i3');
        expect(await isar.isarPhysicalIdentifiers.count(), 3);
      });
    });

    test('los casos de uso funcionan de extremo a extremo sobre Isar', () async {
      final EventBus eventBus = EventBus();
      addTearDown(eventBus.dispose);
      final HouseholdItem created = await CreateItem(repository, SequentialIdGenerator(), FixedClock(t0), eventBus)(
        name: 'Caja A',
        identifier: (rawValue: 'QR-123', type: IdentifierType.qr),
      );
      await BindIdentifier(repository, SequentialIdGenerator(10), FixedClock(t0))(
        created.id,
        rawValue: 'NFC-1',
        type: IdentifierType.nfc,
      );

      final List<ItemEvent> history = await repository.watchEvents(created.id).first;
      expect(
        history.map((ItemEvent e) => e.kind).toSet(),
        <ItemEventKind>{ItemEventKind.created, ItemEventKind.identifierBound},
      );
    });
  });
}
