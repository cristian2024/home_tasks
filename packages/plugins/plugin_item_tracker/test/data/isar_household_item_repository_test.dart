import 'dart:io';

import 'package:core_events/core_events.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/data/models/isar_physical_identifier.dart';

import '../helpers/domain_fixtures.dart';

class _Plugin implements StorageSchemaContributor {
  @override
  List<CollectionSchema<dynamic>> get storageSchemas => itemTrackerSchemas;
}

void main() {
  late Directory directory;
  late Isar isar;
  late IsarHouseholdItemRepository repository;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('item_tracker_test');
    isar = await LocalDatabase.open(directory: directory.path, contributors: [_Plugin()]);
    repository = IsarHouseholdItemRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    directory.deleteSync(recursive: true);
  });

  ItemEvent event(String id, {String itemId = 'item-1', ItemEventKind kind = ItemEventKind.note, DateTime? at}) =>
      ItemEvent(id: id, itemId: itemId, kind: kind, title: id, description: '', timestamp: at ?? t0);

  PhysicalIdentifier ident(String id, String rawValue, IdentifierType type, {String itemId = 'item-1'}) =>
      PhysicalIdentifier(id: id, rawValue: rawValue, type: type, itemId: itemId, boundAt: t0);

  test('createItem guarda el objeto, su identificador y sus eventos', () async {
    final original = item(metadata: ItemMetadata({'peso_kg': 12.5}));
    await repository.createItem(
      original,
      identifier: ident('i1', 'QR-123', IdentifierType.qr),
      events: [event('e1', kind: ItemEventKind.created)],
    );

    final stored = await repository.getById('item-1');
    expect(stored, original);
    expect(stored!.createdAt.isUtc, isTrue);
    expect(await repository.findIdentifier('QR-123', IdentifierType.qr), ident('i1', 'QR-123', IdentifierType.qr));
    expect((await repository.watchEvents('item-1').first).single.id, 'e1');
  });

  test('AC-03/AC-04: busca por identificador conocido y desconocido', () async {
    await repository.createItem(item(), identifier: ident('i1', 'QR-123', IdentifierType.qr), events: const []);

    final found = await FindItemByIdentifier(repository)(rawValue: 'QR-123', type: IdentifierType.qr);

    expect(found?.name, 'Caja A');
    expect(await FindItemByIdentifier(repository)(rawValue: 'UNKNOWN-99', type: IdentifierType.qr), isNull);
  });

  test('AC-05: dos identificadores de distinto tipo devuelven el mismo objeto', () async {
    await repository.createItem(item(name: 'Cama'), identifier: ident('i1', 'QR-BED', IdentifierType.qr), events: const []);
    await repository.bindIdentifier(ident('i2', 'NFC-BED', IdentifierType.nfc), event('e1'));

    final find = FindItemByIdentifier(repository);
    final byQr = await find(rawValue: 'QR-BED', type: IdentifierType.qr);
    final byNfc = await find(rawValue: 'NFC-BED', type: IdentifierType.nfc);

    expect(byQr, isNotNull);
    expect(byQr, byNfc);
    expect((await repository.watchIdentifiers('item-1').first).map((i) => i.rawValue), ['QR-BED', 'NFC-BED']);
  });

  test('el mismo valor con distinto tipo son identificadores distintos', () async {
    await repository.createItem(item(), identifier: ident('i1', '12345', IdentifierType.qr), events: const []);
    await repository.bindIdentifier(ident('i2', '12345', IdentifierType.barcode), event('e1'));

    expect(await repository.watchIdentifiers('item-1').first, hasLength(2));
  });

  test('el índice único rechaza un identificador repetido aunque no se haya comprobado antes', () async {
    await repository.createItem(item(), identifier: ident('i1', 'QR-123', IdentifierType.qr), events: const []);
    await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const []);

    await expectLater(
      repository.bindIdentifier(ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'), event('e1', itemId: 'item-2')),
      throwsA(isA<IdentifierAlreadyBoundException>().having((e) => e.boundItemId, 'boundItemId', 'item-1')),
    );
    expect(await repository.watchEvents('item-2').first, isEmpty, reason: 'la transacción no debe dejar el evento');
  });

  group('quitar un identificador (borrado lógico)', () {
    setUp(() async {
      await repository.createItem(item(), identifier: ident('i1', 'QR-123', IdentifierType.qr), events: const []);
      await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const []);
    });

    test('deja de contar en búsquedas y listados pero se conserva marcado', () async {
      final deletedAt = t0.add(const Duration(hours: 1));
      await repository.unbindIdentifier('i1', deletedAt: deletedAt, event: event('e1', kind: ItemEventKind.identifierUnbound));

      expect(await repository.findIdentifier('QR-123', IdentifierType.qr), isNull);
      expect(await repository.getIdentifier('i1'), isNull);
      expect(await repository.watchIdentifiers('item-1').first, isEmpty);
      expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.identifierUnbound);
      final stored = await isar.isarPhysicalIdentifiers.getById('i1');
      expect(stored?.isDeleted, isTrue);
      expect(stored?.deletedAt?.toUtc(), deletedAt);
    });

    test('el mismo valor y tipo se puede asociar de nuevo, y quitar otra vez', () async {
      await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e1'));
      await repository.bindIdentifier(ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'), event('e2', itemId: 'item-2'));

      expect((await repository.findIdentifier('QR-123', IdentifierType.qr))?.itemId, 'item-2');

      await repository.unbindIdentifier('i2', deletedAt: t0, event: event('e3', itemId: 'item-2'));
      await repository.bindIdentifier(ident('i3', 'QR-123', IdentifierType.qr), event('e4'));
      expect((await repository.findIdentifier('QR-123', IdentifierType.qr))?.id, 'i3');
      expect(await isar.isarPhysicalIdentifiers.count(), 3);
    });

    test('quitar uno ya quitado no hace nada', () async {
      await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e1'));
      await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e2'));

      expect(await repository.watchEvents('item-1').first, hasLength(1));
    });
  });

  test('createItem es atómico: si el identificador choca no guarda el objeto', () async {
    await repository.createItem(item(), identifier: ident('i1', 'QR-123', IdentifierType.qr), events: const []);

    await expectLater(
      repository.createItem(
        item(id: 'item-2'),
        identifier: ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'),
        events: [event('e1', itemId: 'item-2')],
      ),
      throwsA(isA<IdentifierAlreadyBoundException>()),
    );
    expect(await repository.getById('item-2'), isNull);
  });

  test('updateItem reemplaza el objeto y registra el evento', () async {
    await repository.createItem(item(), events: const []);
    final updated = item(name: 'Caja B', updatedAt: t0.add(const Duration(hours: 1)));

    await repository.updateItem(updated, event('e1', kind: ItemEventKind.updated));

    expect(await repository.getById('item-1'), updated);
    expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.updated);
  });

  test('watchAll ordena por modificación y searchByName ignora mayúsculas', () async {
    await repository.createItem(item(id: 'a', name: 'Caja de herramientas'), events: const []);
    await repository.createItem(
      item(id: 'b', name: 'Cama', updatedAt: t0.add(const Duration(hours: 2))),
      events: const [],
    );
    await repository.createItem(
      item(id: 'c', name: 'Mesa', updatedAt: t0.add(const Duration(hours: 1))),
      events: const [],
    );

    expect((await repository.watchAll().first).map((i) => i.id), ['b', 'c', 'a']);
    expect((await repository.searchByName('CA')).map((i) => i.id), ['b', 'a']);
    expect(await repository.searchByName(''), hasLength(3));
  });

  test('watchById emite null si no existe y el objeto cuando se crea', () async {
    final emissions = repository.watchById('item-1').take(2).toList();

    await repository.createItem(item(), events: const []);

    expect(await emissions, [null, item()]);
  });

  test('watchEvents devuelve el historial del más reciente al más antiguo', () async {
    await repository.createItem(item(), events: [event('e1', at: t0)]);
    await repository.addEvent(event('e3', at: t0.add(const Duration(hours: 2))));
    await repository.addEvent(event('e2', at: t0.add(const Duration(hours: 1))));
    await repository.addEvent(event('other', itemId: 'item-2'));

    expect((await repository.watchEvents('item-1').first).map((e) => e.id), ['e3', 'e2', 'e1']);
  });

  test('los casos de uso funcionan de extremo a extremo sobre Isar', () async {
    final eventBus = EventBus();
    addTearDown(eventBus.dispose);
    final created = await CreateItem(repository, SequentialIdGenerator(), FixedClock(t0), eventBus)(
      name: 'Caja A',
      identifier: (rawValue: 'QR-123', type: IdentifierType.qr),
    );
    await BindIdentifier(repository, SequentialIdGenerator(10), FixedClock(t0))(
      created.id,
      rawValue: 'NFC-1',
      type: IdentifierType.nfc,
    );

    final history = await repository.watchEvents(created.id).first;
    expect(history.map((e) => e.kind).toSet(), {ItemEventKind.created, ItemEventKind.identifierBound});
  });
}
