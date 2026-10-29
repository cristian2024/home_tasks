import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../repositories/household_item_repository.dart';
import '../value_objects/item_metadata.dart';

/// Tests de contrato de [HouseholdItemRepository]. Toda implementación (en
/// memoria o de cualquier motor de base de datos) debe pasarlos.
///
/// [create] devuelve un repositorio vacío para cada test y [dispose] lo
/// libera. Lo propio de cada motor (p. ej. cómo se marca un identificador
/// quitado) se prueba aparte, en el paquete de la implementación.
///
/// ```dart
/// householdItemRepositoryContract('Isar', create: () => ..., dispose: (_) => ...);
/// ```
void householdItemRepositoryContract(
  String implementation, {
  required FutureOr<HouseholdItemRepository> Function() create,
  FutureOr<void> Function(HouseholdItemRepository repository)? dispose,
}) {
  group('HouseholdItemRepository ($implementation)', () {
    late HouseholdItemRepository repository;

    final DateTime t0 = DateTime.utc(2026, 10, 21, 14, 30);

    HouseholdItem item({
      String id = 'item-1',
      String name = 'Caja A',
      ItemMetadata metadata = const ItemMetadata.empty(),
      DateTime? updatedAt,
      String? parentId,
    }) =>
        HouseholdItem(
          id: id,
          name: name,
          description: '',
          metadata: metadata,
          createdAt: t0,
          updatedAt: updatedAt ?? t0,
          parentId: parentId,
        );

    ItemEvent event(String id, {String itemId = 'item-1', ItemEventKind kind = ItemEventKind.note, DateTime? at}) =>
        ItemEvent(id: id, itemId: itemId, kind: kind, title: id, description: '', timestamp: at ?? t0);

    PhysicalIdentifier ident(String id, String rawValue, IdentifierType type, {String itemId = 'item-1'}) =>
        PhysicalIdentifier(id: id, rawValue: rawValue, type: type, itemId: itemId, boundAt: t0);

    setUp(() async => repository = await create());
    tearDown(() async => dispose?.call(repository));

    group('objetos', () {
      test('createItem guarda el objeto, su identificador y sus eventos', () async {
        final HouseholdItem original = item(metadata: ItemMetadata(<String, Object?>{'peso_kg': 12.5, 'fragil': true}));
        await repository.createItem(
          original,
          identifier: ident('i1', 'QR-123', IdentifierType.qr),
          events: <ItemEvent>[event('e1', kind: ItemEventKind.created)],
        );

        final HouseholdItem? stored = await repository.getById('item-1');
        expect(stored, original);
        expect(stored!.createdAt.isUtc, isTrue);
        expect(stored.updatedAt.isUtc, isTrue);
        expect(await repository.findIdentifier('QR-123', IdentifierType.qr), ident('i1', 'QR-123', IdentifierType.qr));
        expect(await repository.watchEvents('item-1').first, <ItemEvent>[event('e1', kind: ItemEventKind.created)]);
      });

      test('getById devuelve null si el objeto no existe', () async {
        expect(await repository.getById('missing'), isNull);
      });

      test('createItem es atómico: si el identificador choca no guarda nada', () async {
        await repository.createItem(
          item(),
          identifier: ident('i1', 'QR-123', IdentifierType.qr),
          events: const <ItemEvent>[],
        );

        await expectLater(
          repository.createItem(
            item(id: 'item-2'),
            identifier: ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'),
            events: <ItemEvent>[event('e1', itemId: 'item-2')],
          ),
          throwsA(
            isA<IdentifierAlreadyBoundException>()
                .having((IdentifierAlreadyBoundException e) => e.boundItemId, 'boundItemId', 'item-1'),
          ),
        );
        expect(await repository.getById('item-2'), isNull);
        expect(await repository.watchEvents('item-2').first, isEmpty);
      });

      test('updateItem reemplaza el objeto y registra el evento', () async {
        await repository.createItem(item(), events: const <ItemEvent>[]);
        final HouseholdItem updated = item(
          name: 'Caja B',
          metadata: ItemMetadata(<String, Object?>{'unidades': 3}),
          updatedAt: t0.add(const Duration(hours: 1)),
        );

        await repository.updateItem(updated, event('e1', kind: ItemEventKind.updated));

        expect(await repository.getById('item-1'), updated);
        expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.updated);
      });

      test('moveItem guarda el contenedor y los eventos de todos los objetos', () async {
        await repository.createItem(item(id: 'box', name: 'Caja'), events: const <ItemEvent>[]);
        await repository.createItem(item(), events: const <ItemEvent>[]);

        await repository.moveItem(
          item(parentId: 'box', updatedAt: t0.add(const Duration(hours: 1))),
          <ItemEvent>[event('e1', kind: ItemEventKind.moved), event('e2', itemId: 'box', kind: ItemEventKind.childAdded)],
        );

        expect((await repository.getById('item-1'))?.parentId, 'box');
        expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.moved);
        expect((await repository.watchEvents('box').first).single.kind, ItemEventKind.childAdded);

        await repository.moveItem(item(updatedAt: t0.add(const Duration(hours: 2))), const <ItemEvent>[]);
        expect((await repository.getById('item-1'))?.parentId, isNull);
      });

      test('getAll devuelve todos los objetos', () async {
        expect(await repository.getAll(), isEmpty);

        await repository.createItem(item(id: 'a'), events: const <ItemEvent>[]);
        await repository.createItem(item(id: 'b', parentId: 'a'), events: const <ItemEvent>[]);

        expect(await repository.getAll(), unorderedEquals(<HouseholdItem>[item(id: 'a'), item(id: 'b', parentId: 'a')]));
      });

      test('watchAll y searchByName ordenan del modificado más recientemente al más antiguo', () async {
        await repository.createItem(item(id: 'a', name: 'Caja de herramientas'), events: const <ItemEvent>[]);
        await repository.createItem(
          item(id: 'b', name: 'Cama', updatedAt: t0.add(const Duration(hours: 2))),
          events: const <ItemEvent>[],
        );
        await repository.createItem(
          item(id: 'c', name: 'Mesa', updatedAt: t0.add(const Duration(hours: 1))),
          events: const <ItemEvent>[],
        );

        expect((await repository.watchAll().first).map((HouseholdItem i) => i.id), <String>['b', 'c', 'a']);
        expect((await repository.searchByName('CA')).map((HouseholdItem i) => i.id), <String>['b', 'a']);
        expect(await repository.searchByName(''), hasLength(3));
        expect(await repository.searchByName('sofá'), isEmpty);
      });

      group('borrar objetos', () {
        setUp(() async {
          await repository.createItem(
            item(id: 'box', name: 'Caja'),
            identifier: ident('i1', 'QR-BOX', IdentifierType.qr, itemId: 'box'),
            events: const <ItemEvent>[],
          );
          await repository.createItem(
            item(name: 'Destornillador', parentId: 'box'),
            identifier: ident('i2', 'NFC-1', IdentifierType.nfc),
            events: const <ItemEvent>[],
          );
          await repository.createItem(item(id: 'other', name: 'Mesa'), events: const <ItemEvent>[]);
        });

        test('dejan de aparecer en consultas, listados y búsquedas', () async {
          await repository.deleteItems(<String>['box', 'item-1'], deletedAt: t0, events: const <ItemEvent>[]);

          expect(await repository.getById('box'), isNull);
          expect(await repository.getById('item-1'), isNull);
          expect(await repository.watchById('box').first, isNull);
          expect((await repository.getAll()).map((HouseholdItem i) => i.id), <String>['other']);
          expect((await repository.watchAll().first).map((HouseholdItem i) => i.id), <String>['other']);
          expect((await repository.searchByName('')).map((HouseholdItem i) => i.id), <String>['other']);
        });

        test('liberan sus identificadores, que se pueden asociar a otro objeto', () async {
          await repository.deleteItems(<String>['box'], deletedAt: t0, events: const <ItemEvent>[]);

          expect(await repository.findIdentifier('QR-BOX', IdentifierType.qr), isNull);
          expect(await repository.getIdentifier('i1'), isNull);
          expect(await repository.watchIdentifiers('box').first, isEmpty);
          expect(await repository.getIdentifier('i2'), isNotNull);

          await repository.bindIdentifier(ident('i3', 'QR-BOX', IdentifierType.qr, itemId: 'other'), event('e1'));
          expect((await repository.findIdentifier('QR-BOX', IdentifierType.qr))?.itemId, 'other');
        });

        test('guardan los objetos movidos y los eventos en la misma operación', () async {
          final HouseholdItem lifted = item(name: 'Destornillador', updatedAt: t0.add(const Duration(hours: 1)));

          await repository.deleteItems(
            <String>['box'],
            deletedAt: t0,
            moved: <HouseholdItem>[lifted],
            events: <ItemEvent>[event('e1', kind: ItemEventKind.moved)],
          );

          expect(await repository.getById('item-1'), lifted);
          expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.moved);
        });

        test('ignora los que no existen o ya se borraron', () async {
          await repository.deleteItems(<String>['other'], deletedAt: t0, events: const <ItemEvent>[]);
          await repository.deleteItems(<String>['other', 'missing'], deletedAt: t0, events: const <ItemEvent>[]);

          expect((await repository.getAll()).map((HouseholdItem i) => i.id), unorderedEquals(<String>['box', 'item-1']));
        });
      });
    });

    group('identificadores', () {
      test('dos identificadores de distinto tipo llevan al mismo objeto', () async {
        await repository.createItem(
          item(name: 'Cama'),
          identifier: ident('i1', 'QR-BED', IdentifierType.qr),
          events: const <ItemEvent>[],
        );
        await repository.bindIdentifier(ident('i2', 'NFC-BED', IdentifierType.nfc), event('e1'));

        expect((await repository.findIdentifier('QR-BED', IdentifierType.qr))?.itemId, 'item-1');
        expect((await repository.findIdentifier('NFC-BED', IdentifierType.nfc))?.itemId, 'item-1');
        expect(await repository.findIdentifier('UNKNOWN-99', IdentifierType.qr), isNull);
        expect(await repository.getIdentifier('i2'), ident('i2', 'NFC-BED', IdentifierType.nfc));
        expect(await repository.getIdentifier('missing'), isNull);
        expect((await repository.watchEvents('item-1').first).single.id, 'e1');
      });

      test('watchIdentifiers devuelve los del objeto, del más antiguo al más reciente', () async {
        await repository.createItem(item(), events: const <ItemEvent>[]);
        await repository.createItem(item(id: 'item-2'), events: const <ItemEvent>[]);
        await repository.bindIdentifier(
          PhysicalIdentifier(
            id: 'late',
            rawValue: 'NFC-1',
            type: IdentifierType.nfc,
            itemId: 'item-1',
            boundAt: t0.add(const Duration(hours: 1)),
          ),
          event('e1'),
        );
        await repository.bindIdentifier(ident('early', 'QR-1', IdentifierType.qr), event('e2'));
        await repository.bindIdentifier(ident('other', 'QR-2', IdentifierType.qr, itemId: 'item-2'), event('e3'));

        expect(
          (await repository.watchIdentifiers('item-1').first).map((PhysicalIdentifier i) => i.id),
          <String>['early', 'late'],
        );
      });

      test('el mismo valor con distinto tipo son identificadores distintos', () async {
        await repository.createItem(
          item(),
          identifier: ident('i1', '12345', IdentifierType.qr),
          events: const <ItemEvent>[],
        );
        await repository.bindIdentifier(ident('i2', '12345', IdentifierType.barcode), event('e1'));

        expect(await repository.watchIdentifiers('item-1').first, hasLength(2));
      });

      test('bindIdentifier rechaza un identificador ya asociado y no registra el evento', () async {
        await repository.createItem(
          item(),
          identifier: ident('i1', 'QR-123', IdentifierType.qr),
          events: const <ItemEvent>[],
        );
        await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const <ItemEvent>[]);

        await expectLater(
          repository.bindIdentifier(
            ident('i2', 'QR-123', IdentifierType.qr, itemId: 'item-2'),
            event('e1', itemId: 'item-2'),
          ),
          throwsA(
            isA<IdentifierAlreadyBoundException>()
                .having((IdentifierAlreadyBoundException e) => e.rawValue, 'rawValue', 'QR-123')
                .having((IdentifierAlreadyBoundException e) => e.type, 'type', IdentifierType.qr)
                .having((IdentifierAlreadyBoundException e) => e.boundItemId, 'boundItemId', 'item-1'),
          ),
        );
        expect(await repository.watchEvents('item-2').first, isEmpty);
        expect(await repository.watchIdentifiers('item-2').first, isEmpty);
      });

      group('quitar un identificador', () {
        setUp(() async {
          await repository.createItem(
            item(),
            identifier: ident('i1', 'QR-123', IdentifierType.qr),
            events: const <ItemEvent>[],
          );
          await repository.createItem(item(id: 'item-2', name: 'Caja B'), events: const <ItemEvent>[]);
        });

        test('deja de contar en búsquedas y listados, y registra el evento', () async {
          await repository.unbindIdentifier(
            'i1',
            deletedAt: t0.add(const Duration(hours: 1)),
            event: event('e1', kind: ItemEventKind.identifierUnbound),
          );

          expect(await repository.findIdentifier('QR-123', IdentifierType.qr), isNull);
          expect(await repository.getIdentifier('i1'), isNull);
          expect(await repository.watchIdentifiers('item-1').first, isEmpty);
          expect((await repository.watchEvents('item-1').first).single.kind, ItemEventKind.identifierUnbound);
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
        });

        test('quitar uno ya quitado o inexistente no hace nada', () async {
          await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e1'));
          await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e2'));
          await repository.unbindIdentifier('missing', deletedAt: t0, event: event('e3'));

          expect((await repository.watchEvents('item-1').first).map((ItemEvent e) => e.id), <String>['e1']);
        });
      });
    });

    group('historial', () {
      test('watchEvents devuelve los eventos del objeto, del más reciente al más antiguo', () async {
        await repository.createItem(item(), events: <ItemEvent>[event('e1', at: t0)]);
        await repository.addEvent(event('e3', at: t0.add(const Duration(hours: 2))));
        await repository.addEvent(event('e2', at: t0.add(const Duration(hours: 1))));
        await repository.addEvent(event('other', itemId: 'item-2'));

        final List<ItemEvent> history = await repository.watchEvents('item-1').first;
        expect(history.map((ItemEvent e) => e.id), <String>['e3', 'e2', 'e1']);
        expect(history.every((ItemEvent e) => e.timestamp.isUtc), isTrue);
      });

      test('conserva el tipo, el título y la descripción de cada evento', () async {
        final ItemEvent note = ItemEvent(
          id: 'n1',
          itemId: 'item-1',
          kind: ItemEventKind.note,
          title: 'Mudanza',
          description: 'Va al trastero',
          timestamp: t0.add(const Duration(hours: 1)),
        );
        await repository.createItem(item(), events: const <ItemEvent>[]);
        for (final ItemEventKind kind in ItemEventKind.values) {
          await repository.addEvent(event(kind.name, kind: kind));
        }
        await repository.addEvent(note);

        final List<ItemEvent> history = await repository.watchEvents('item-1').first;
        expect(history.map((ItemEvent e) => e.kind).toSet(), ItemEventKind.values.toSet());
        expect(history.firstWhere((ItemEvent e) => e.id == 'n1'), note);
      });
    });

    // Una base de datos calcula el estado inicial de forma asíncrona: cada
    // test espera esa primera emisión antes de escribir, y después acepta
    // emisiones intermedias hasta ver el estado esperado.
    group('streams', () {
      test('watchById emite null si no existe, el objeto al crearse y cada cambio', () async {
        final StreamQueue<HouseholdItem?> queue = StreamQueue<HouseholdItem?>(repository.watchById('item-1'));
        addTearDown(() => queue.cancel(immediate: true));

        expect(await queue.next, isNull);
        await repository.createItem(item(), events: const <ItemEvent>[]);
        await expectLater(queue, emitsThrough(item()));
        await repository.updateItem(item(name: 'Caja B'), event('e1'));
        await expectLater(queue, emitsThrough(item(name: 'Caja B')));
        await repository.deleteItems(<String>['item-1'], deletedAt: t0, events: const <ItemEvent>[]);
        await expectLater(queue, emitsThrough(isNull));
      });

      test('watchAll emite el estado actual al suscribirse y la lista completa en cada cambio', () async {
        await repository.createItem(item(id: 'a'), events: const <ItemEvent>[]);
        final StreamQueue<List<String>> queue = StreamQueue<List<String>>(
          repository.watchAll().map((List<HouseholdItem> items) => items.map((HouseholdItem i) => i.id).toList()),
        );
        addTearDown(() => queue.cancel(immediate: true));

        expect(await queue.next, <String>['a']);
        await repository.createItem(
          item(id: 'b', updatedAt: t0.add(const Duration(hours: 1))),
          events: const <ItemEvent>[],
        );
        await expectLater(queue, emitsThrough(<String>['b', 'a']));
      });

      test('watchIdentifiers emite al asociar y al quitar', () async {
        await repository.createItem(item(), events: const <ItemEvent>[]);
        final StreamQueue<int> queue = StreamQueue<int>(
          repository.watchIdentifiers('item-1').map((List<PhysicalIdentifier> identifiers) => identifiers.length),
        );
        addTearDown(() => queue.cancel(immediate: true));

        expect(await queue.next, 0);
        await repository.bindIdentifier(ident('i1', 'QR-1', IdentifierType.qr), event('e1'));
        await expectLater(queue, emitsThrough(1));
        await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e2'));
        await expectLater(queue, emitsThrough(0));
      });

      test('watchEvents emite el historial completo en cada evento nuevo', () async {
        await repository.createItem(item(), events: const <ItemEvent>[]);
        final StreamQueue<List<String>> queue = StreamQueue<List<String>>(
          repository.watchEvents('item-1').map((List<ItemEvent> events) => events.map((ItemEvent e) => e.id).toList()),
        );
        addTearDown(() => queue.cancel(immediate: true));

        expect(await queue.next, isEmpty);
        await repository.addEvent(event('e1'));
        await expectLater(queue, emitsThrough(<String>['e1']));
      });
    });
  });
}
