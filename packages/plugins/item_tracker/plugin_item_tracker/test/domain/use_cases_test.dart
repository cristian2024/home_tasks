import 'package:core_events/core_events.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late MockHouseholdItemRepository repository;
  late SequentialIdGenerator ids;
  late FixedClock clock;
  late EventBus eventBus;

  setUpAll(registerDomainFallbacks);

  setUp(() {
    repository = MockHouseholdItemRepository();
    ids = SequentialIdGenerator();
    clock = FixedClock(t0);
    eventBus = EventBus();
    when(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')))
        .thenAnswer((_) async {});
    when(() => repository.updateItem(any(), any())).thenAnswer((_) async {});
    when(() => repository.bindIdentifier(any(), any())).thenAnswer((_) async {});
    when(() => repository.addEvent(any())).thenAnswer((_) async {});
    when(
      () => repository.unbindIdentifier(any(), deletedAt: any(named: 'deletedAt'), event: any(named: 'event')),
    ).thenAnswer((_) async {});
    when(() => repository.getIdentifier(any())).thenAnswer((_) async => null);
    when(() => repository.findIdentifier(any(), any())).thenAnswer((_) async => null);
    when(() => repository.getById(any())).thenAnswer((_) async => null);
    when(() => repository.getAll()).thenAnswer((_) async => const <HouseholdItem>[]);
    when(() => repository.moveItem(any(), any())).thenAnswer((_) async {});
    when(
      () => repository.deleteItems(
        any(),
        deletedAt: any(named: 'deletedAt'),
        moved: any(named: 'moved'),
        events: any(named: 'events'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => eventBus.dispose());

  group('CreateItem', () {
    late CreateItem createItem;

    setUp(() => createItem = CreateItem(repository, ids, clock, eventBus));

    test('crea el objeto con evento técnico y publica ItemCreatedCrossEvent', () async {
      final Future<ItemCreatedCrossEvent> published = eventBus.on<ItemCreatedCrossEvent>().first;

      final HouseholdItem created =
          await createItem(name: '  Caja A ', description: 'Garaje', metadata: <String, Object?>{'fragil': true});

      expect(
        created,
        item(id: 'id-1', description: 'Garaje', metadata: ItemMetadata(<String, Object?>{'fragil': true})),
      );
      final List<dynamic> captured = verify(
        () => repository.createItem(captureAny(), identifier: captureAny(named: 'identifier'), events: captureAny(named: 'events')),
      ).captured;
      // mocktail captura los argumentos con nombre en orden alfabético.
      expect(captured[0], created);
      expect(captured[2], isNull);
      expect(captured[1], <ItemEvent>[
        ItemEvent(id: 'id-2', itemId: 'id-1', kind: ItemEventKind.created, title: 'Caja A', description: '', timestamp: t0),
      ]);
      final ItemCreatedCrossEvent event = await published;
      expect(event.itemId, 'id-1');
      expect(event.emittedAt, t0);
    });

    test('asocia el identificador inicial y registra su evento', () async {
      await createItem(name: 'Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr));

      final List<dynamic> captured = verify(
        () => repository.createItem(any(), identifier: captureAny(named: 'identifier'), events: captureAny(named: 'events')),
      ).captured;
      final List<ItemEvent> events = captured[0] as List<ItemEvent>;
      expect(
        captured[1],
        PhysicalIdentifier(id: 'id-2', rawValue: 'QR-123', type: IdentifierType.qr, itemId: 'id-1', boundAt: t0),
      );
      expect(
        events.map((ItemEvent e) => e.kind),
        <ItemEventKind>[ItemEventKind.created, ItemEventKind.identifierBound],
      );
      expect(events.last.description, 'QR-123');
    });

    test('rechaza un identificador ya asociado sin escribir nada', () async {
      when(() => repository.findIdentifier('QR-123', IdentifierType.qr))
          .thenAnswer((_) async => identifier(itemId: 'other'));

      await expectLater(
        createItem(name: 'Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr)),
        throwsA(
          isA<IdentifierAlreadyBoundException>()
              .having((IdentifierAlreadyBoundException e) => e.boundItemId, 'boundItemId', 'other'),
        ),
      );
      verifyNever(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')));
    });

    test('valida nombre, metadatos e identificador antes de escribir', () async {
      await expectLater(createItem(name: ' '), throwsValidation(ValidationField.name, ValidationReason.empty));
      await expectLater(
        createItem(name: 'A', metadata: <String, Object?>{'Mal': 1}),
        throwsValidation(ValidationField.metadata, ValidationReason.invalidFormat),
      );
      await expectLater(
        createItem(name: 'A', identifier: (rawValue: '', type: IdentifierType.nfc)),
        throwsValidation(ValidationField.identifierValue, ValidationReason.empty),
      );
      verifyNever(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')));
    });
  });

  group('CreateItem dentro de un contenedor', () {
    late CreateItem createItem;

    setUp(() => createItem = CreateItem(repository, ids, clock, eventBus, const ContainmentPolicy(maxDepth: 3)));

    test('lo crea dentro y registra childAdded en el contenedor', () async {
      when(() => repository.getAll()).thenAnswer((_) async => <HouseholdItem>[item(id: 'box', name: 'Organizador')]);

      final HouseholdItem created = await createItem(name: 'Cajón 1', parentId: 'box');

      expect(created.parentId, 'box');
      final List<ItemEvent> events = verify(
        () => repository.createItem(any(), identifier: any(named: 'identifier'), events: captureAny(named: 'events')),
      ).captured.single as List<ItemEvent>;
      expect(
        events.last,
        ItemEvent(id: 'id-3', itemId: 'box', kind: ItemEventKind.childAdded, title: 'Cajón 1', description: 'id-1', timestamp: t0),
      );
    });

    test('rechaza un contenedor que no existe', () async {
      await expectLater(
        createItem(name: 'Cajón 1', parentId: 'missing'),
        throwsA(isA<ItemNotFoundException>().having((ItemNotFoundException e) => e.itemId, 'itemId', 'missing')),
      );
    });

    test('rechaza crear por debajo del nivel máximo', () async {
      when(() => repository.getAll()).thenAnswer(
        (_) async => <HouseholdItem>[item(id: 'a'), item(id: 'b', parentId: 'a'), item(id: 'c', parentId: 'b')],
      );

      await expectLater(
        createItem(name: 'Demasiado hondo', parentId: 'c'),
        throwsA(
          isA<ItemContainmentTooDeepException>()
              .having((ItemContainmentTooDeepException e) => e.maxDepth, 'maxDepth', 3),
        ),
      );
      verifyNever(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')));
    });
  });

  group('MoveItem', () {
    late MoveItem moveItem;

    // Mueble › Organizador › Cajón 1, y Tijeras y Caja sueltas.
    final HouseholdItem furniture = item(id: 'furniture', name: 'Mueble');
    final HouseholdItem organizer = item(id: 'organizer', name: 'Organizador', parentId: 'furniture');
    final HouseholdItem drawer = item(id: 'drawer', name: 'Cajón 1', parentId: 'organizer');
    final HouseholdItem scissors = item(id: 'scissors', name: 'Tijeras');
    final HouseholdItem box = item(id: 'box', name: 'Caja');

    setUp(() {
      moveItem = MoveItem(repository, ids, clock, const ContainmentPolicy(maxDepth: 4));
      when(() => repository.getAll())
          .thenAnswer((_) async => <HouseholdItem>[furniture, organizer, drawer, scissors, box]);
    });

    ItemEvent event(String id, String itemId, ItemEventKind kind, String title, String description) =>
        ItemEvent(id: id, itemId: itemId, kind: kind, title: title, description: description, timestamp: t0);

    test('mete un objeto suelto en un contenedor', () async {
      clock.advance(const Duration(hours: 1));

      final HouseholdItem moved = await moveItem('scissors', parentId: 'drawer');

      expect(moved, scissors.copyWith(parentId: () => 'drawer', updatedAt: t0.add(const Duration(hours: 1))));
      final List<ItemEvent> events =
          verify(() => repository.moveItem(moved, captureAny())).captured.single as List<ItemEvent>;
      expect(
        events.map((ItemEvent e) => (e.itemId, e.kind, e.title, e.description)),
        <(String, ItemEventKind, String, String)>[
          ('scissors', ItemEventKind.moved, 'Cajón 1', 'drawer'),
          ('drawer', ItemEventKind.childAdded, 'Tijeras', 'scissors'),
        ],
      );
    });

    test('al cambiar de contenedor registra la salida en el anterior', () async {
      final HouseholdItem moved = await moveItem('drawer', parentId: 'box');

      final List<ItemEvent> events =
          verify(() => repository.moveItem(moved, captureAny())).captured.single as List<ItemEvent>;
      expect(events, <ItemEvent>[
        event('id-1', 'drawer', ItemEventKind.moved, 'Caja', 'box'),
        event('id-2', 'organizer', ItemEventKind.childRemoved, 'Cajón 1', 'drawer'),
        event('id-3', 'box', ItemEventKind.childAdded, 'Cajón 1', 'drawer'),
      ]);
    });

    test('sacarlo de su contenedor deja moved sin nombre', () async {
      final HouseholdItem moved = await moveItem('drawer', parentId: null);

      expect(moved.parentId, isNull);
      final List<ItemEvent> events =
          verify(() => repository.moveItem(moved, captureAny())).captured.single as List<ItemEvent>;
      expect(events.first, event('id-1', 'drawer', ItemEventKind.moved, '', ''));
      expect(events, hasLength(2));
    });

    test('si el contenedor no cambia no escribe nada', () async {
      expect(await moveItem('drawer', parentId: 'organizer'), drawer);
      expect(await moveItem('box', parentId: null), box);
      verifyNever(() => repository.moveItem(any(), any()));
    });

    test('impide meter un objeto en sí mismo o en algo que contiene', () async {
      await expectLater(
        moveItem('organizer', parentId: 'organizer'),
        throwsA(isA<ItemContainmentCycleException>()),
      );
      await expectLater(
        moveItem('furniture', parentId: 'drawer'),
        throwsA(
          isA<ItemContainmentCycleException>()
              .having((ItemContainmentCycleException e) => e.itemId, 'itemId', 'furniture')
              .having((ItemContainmentCycleException e) => e.parentId, 'parentId', 'drawer'),
        ),
      );
      verifyNever(() => repository.moveItem(any(), any()));
    });

    test('cuenta todo lo que contiene el objeto al comprobar el nivel máximo', () async {
      // Organizador ocupa 2 niveles (con su cajón): dentro de Caja (nivel 1)
      // llega al nivel 3; dentro de Cajón 1 de otro mueble no cabría.
      await moveItem('organizer', parentId: 'box');

      when(() => repository.getAll()).thenAnswer(
        (_) async => <HouseholdItem>[
          furniture,
          organizer,
          drawer,
          item(id: 'shelf', parentId: 'furniture'),
          item(id: 'bin', parentId: 'shelf'),
        ],
      );
      await expectLater(
        moveItem('organizer', parentId: 'bin'),
        throwsA(
          isA<ItemContainmentTooDeepException>()
              .having((ItemContainmentTooDeepException e) => e.maxDepth, 'maxDepth', 4),
        ),
      );
    });

    test('lanza ItemNotFoundException si falta el objeto o el contenedor', () async {
      await expectLater(moveItem('missing', parentId: null), throwsA(isA<ItemNotFoundException>()));
      await expectLater(
        moveItem('scissors', parentId: 'missing'),
        throwsA(isA<ItemNotFoundException>().having((ItemNotFoundException e) => e.itemId, 'itemId', 'missing')),
      );
    });
  });

  group('UpdateItem', () {
    late UpdateItem updateItem;

    setUp(() => updateItem = UpdateItem(repository, ids, clock));

    test('lanza ItemNotFoundException si el objeto no existe', () async {
      await expectLater(updateItem('missing', name: 'X'), throwsA(isA<ItemNotFoundException>()));
    });

    test('sin cambios no escribe nada', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      final HouseholdItem result =
          await updateItem('item-1', name: ' Caja A ', description: '', metadata: <String, Object?>{});

      expect(result, item());
      verifyNever(() => repository.updateItem(any(), any()));
    });

    test('actualiza updatedAt y registra los campos cambiados', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());
      clock.advance(const Duration(hours: 1));

      final HouseholdItem result =
          await updateItem('item-1', name: 'Caja B', metadata: <String, Object?>{'peso_kg': 2});

      final DateTime later = t0.add(const Duration(hours: 1));
      expect(result, item(name: 'Caja B', metadata: ItemMetadata(<String, Object?>{'peso_kg': 2}), updatedAt: later));
      verify(
        () => repository.updateItem(
          result,
          ItemEvent(
            id: 'id-1',
            itemId: 'item-1',
            kind: ItemEventKind.updated,
            title: '',
            description: 'name,metadata',
            timestamp: later,
          ),
        ),
      ).called(1);
    });

    test('detecta el cambio de descripción', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      await updateItem('item-1', description: 'Nueva');

      final ItemEvent event = verify(() => repository.updateItem(any(), captureAny())).captured.single as ItemEvent;
      expect(event.description, 'description');
    });

    test('valida los campos nuevos', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      await expectLater(
        updateItem('item-1', description: 'a' * 2001),
        throwsValidation(ValidationField.description, ValidationReason.tooLong),
      );
    });
  });

  group('BindIdentifier', () {
    late BindIdentifier bindIdentifier;

    setUp(() => bindIdentifier = BindIdentifier(repository, ids, clock));

    test('AC-05: asocia un segundo identificador al mismo objeto', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      final PhysicalIdentifier bound = await bindIdentifier('item-1', rawValue: 'NFC-BED', type: IdentifierType.nfc);

      expect(
        bound,
        PhysicalIdentifier(id: 'id-1', rawValue: 'NFC-BED', type: IdentifierType.nfc, itemId: 'item-1', boundAt: t0),
      );
      verify(
        () => repository.bindIdentifier(
          bound,
          ItemEvent(
            id: 'id-2',
            itemId: 'item-1',
            kind: ItemEventKind.identifierBound,
            title: 'nfc',
            description: 'NFC-BED',
            timestamp: t0,
          ),
        ),
      ).called(1);
    });

    test('lanza ItemNotFoundException si el objeto no existe', () async {
      await expectLater(
        bindIdentifier('missing', rawValue: 'QR', type: IdentifierType.qr),
        throwsA(isA<ItemNotFoundException>()),
      );
    });

    test('rechaza un identificador ya asociado, también al mismo objeto', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());
      when(() => repository.findIdentifier('QR-123', IdentifierType.qr)).thenAnswer((_) async => identifier());

      await expectLater(
        bindIdentifier('item-1', rawValue: 'QR-123', type: IdentifierType.qr),
        throwsA(
          isA<IdentifierAlreadyBoundException>()
              .having((IdentifierAlreadyBoundException e) => e.boundItemId, 'boundItemId', 'item-1'),
        ),
      );
      verifyNever(() => repository.bindIdentifier(any(), any()));
    });

    test('valida el valor del identificador', () async {
      await expectLater(
        bindIdentifier('item-1', rawValue: 'a\x00', type: IdentifierType.qr),
        throwsValidation(ValidationField.identifierValue, ValidationReason.invalidFormat),
      );
    });
  });

  group('UnbindIdentifier', () {
    late UnbindIdentifier unbindIdentifier;

    setUp(() => unbindIdentifier = UnbindIdentifier(repository, ids, clock));

    test('quita el identificador con borrado lógico y registra su evento', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());
      when(() => repository.getIdentifier('ident-1')).thenAnswer((_) async => identifier());

      final PhysicalIdentifier removed = await unbindIdentifier('item-1', identifierId: 'ident-1');

      expect(removed, identifier());
      verify(
        () => repository.unbindIdentifier(
          'ident-1',
          deletedAt: t0,
          event: ItemEvent(
            id: 'id-1',
            itemId: 'item-1',
            kind: ItemEventKind.identifierUnbound,
            title: 'qr',
            description: 'QR-123',
            timestamp: t0,
          ),
        ),
      ).called(1);
    });

    test('lanza ItemNotFoundException si el objeto no existe', () async {
      await expectLater(
        unbindIdentifier('missing', identifierId: 'ident-1'),
        throwsA(isA<ItemNotFoundException>()),
      );
    });

    test('lanza IdentifierNotFoundException si no existe, ya se quitó o es de otro objeto', () async {
      when(() => repository.getById('item-2')).thenAnswer((_) async => item(id: 'item-2'));

      await expectLater(
        unbindIdentifier('item-2', identifierId: 'ident-1'),
        throwsA(
          isA<IdentifierNotFoundException>()
              .having((IdentifierNotFoundException e) => e.identifierId, 'identifierId', 'ident-1'),
        ),
      );
      when(() => repository.getIdentifier('ident-1')).thenAnswer((_) async => identifier());
      await expectLater(
        unbindIdentifier('item-2', identifierId: 'ident-1'),
        throwsA(isA<IdentifierNotFoundException>()),
      );
      verifyNever(
        () => repository.unbindIdentifier(any(), deletedAt: any(named: 'deletedAt'), event: any(named: 'event')),
      );
    });
  });

  group('DeleteItem', () {
    late DeleteItem deleteItem;

    // Mueble › Caja › (Destornillador › Puntas) y Llave.
    final HouseholdItem furniture = item(id: 'furniture', name: 'Mueble');
    final HouseholdItem box = item(id: 'box', name: 'Caja', parentId: 'furniture');
    final HouseholdItem screwdriver = item(id: 'screwdriver', name: 'Destornillador', parentId: 'box');
    final HouseholdItem bits = item(id: 'bits', name: 'Puntas', parentId: 'screwdriver');
    final HouseholdItem wrench = item(id: 'wrench', name: 'Llave', parentId: 'box');

    ItemEvent technical(String id, String itemId, ItemEventKind kind, HouseholdItem? subject) => ItemEvent(
          id: id,
          itemId: itemId,
          kind: kind,
          title: subject?.name ?? '',
          description: subject?.id ?? '',
          timestamp: t0,
        );

    setUp(() {
      deleteItem = DeleteItem(repository, ids, clock);
      when(() => repository.getAll())
          .thenAnswer((_) async => <HouseholdItem>[furniture, box, screwdriver, bits, wrench]);
    });

    test('sacar el contenido lo deja en el contenedor del borrado, con sus eventos', () async {
      await deleteItem('box', contents: DeletedContents.moveToParent);

      verify(
        () => repository.deleteItems(
          <String>['box'],
          deletedAt: t0,
          moved: <HouseholdItem>[
            screwdriver.copyWith(parentId: () => 'furniture', updatedAt: t0),
            wrench.copyWith(parentId: () => 'furniture', updatedAt: t0),
          ],
          events: <ItemEvent>[
            technical('id-1', 'furniture', ItemEventKind.childRemoved, box),
            technical('id-2', 'screwdriver', ItemEventKind.moved, furniture),
            technical('id-3', 'furniture', ItemEventKind.childAdded, screwdriver),
            technical('id-4', 'wrench', ItemEventKind.moved, furniture),
            technical('id-5', 'furniture', ItemEventKind.childAdded, wrench),
          ],
        ),
      ).called(1);
    });

    test('sin contenedor, el contenido queda suelto', () async {
      await deleteItem('furniture', contents: DeletedContents.moveToParent);

      verify(
        () => repository.deleteItems(
          <String>['furniture'],
          deletedAt: t0,
          moved: <HouseholdItem>[box.copyWith(parentId: () => null, updatedAt: t0)],
          events: <ItemEvent>[technical('id-1', 'box', ItemEventKind.moved, null)],
        ),
      ).called(1);
    });

    test('borrar todo incluye el contenido a cualquier profundidad', () async {
      await deleteItem('box', contents: DeletedContents.deleteAll);

      verify(
        () => repository.deleteItems(
          <String>['box', 'screwdriver', 'bits', 'wrench'],
          deletedAt: t0,
          events: <ItemEvent>[technical('id-1', 'furniture', ItemEventKind.childRemoved, box)],
        ),
      ).called(1);
    });

    test('un objeto sin contenido se borra solo, con la salida en su contenedor', () async {
      await deleteItem('bits', contents: DeletedContents.deleteAll);

      verify(
        () => repository.deleteItems(
          <String>['bits'],
          deletedAt: t0,
          events: <ItemEvent>[technical('id-1', 'screwdriver', ItemEventKind.childRemoved, bits)],
        ),
      ).called(1);
    });

    test('lanza ItemNotFoundException si el objeto no existe', () async {
      await expectLater(
        deleteItem('missing', contents: DeletedContents.deleteAll),
        throwsA(isA<ItemNotFoundException>()),
      );
      verifyNever(
        () => repository.deleteItems(
          any(),
          deletedAt: any(named: 'deletedAt'),
          moved: any(named: 'moved'),
          events: any(named: 'events'),
        ),
      );
    });
  });

  group('AddItemEvent', () {
    late AddItemEvent addItemEvent;

    setUp(() => addItemEvent = AddItemEvent(repository, ids, clock));

    test('añade una nota del usuario', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      final ItemEvent event = await addItemEvent('item-1', title: ' Cambio de Ubicación ', description: 'Al altillo.');

      expect(
        event,
        ItemEvent(
          id: 'id-1',
          itemId: 'item-1',
          kind: ItemEventKind.note,
          title: 'Cambio de Ubicación',
          description: 'Al altillo.',
          timestamp: t0,
        ),
      );
      verify(() => repository.addEvent(event)).called(1);
    });

    test('lanza ItemNotFoundException si el objeto no existe', () async {
      await expectLater(addItemEvent('missing', title: 'X'), throwsA(isA<ItemNotFoundException>()));
    });

    test('exige título', () async {
      await expectLater(addItemEvent('item-1', title: ''), throwsValidation(ValidationField.eventTitle, ValidationReason.empty));
    });
  });

  group('FindItemByIdentifier', () {
    late FindItemByIdentifier find;

    setUp(() => find = FindItemByIdentifier(repository));

    test('AC-04: devuelve null para un identificador desconocido', () async {
      expect(await find(rawValue: 'UNKNOWN-99', type: IdentifierType.qr), isNull);
    });

    test('AC-03: devuelve el objeto ligado al identificador', () async {
      when(() => repository.findIdentifier('QR-123', IdentifierType.qr)).thenAnswer((_) async => identifier());
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      expect(await find(rawValue: 'QR-123', type: IdentifierType.qr), item());
    });

    test('valida el valor buscado', () async {
      await expectLater(
        find(rawValue: '', type: IdentifierType.qr),
        throwsValidation(ValidationField.identifierValue, ValidationReason.empty),
      );
    });
  });

  group('consultas', () {
    test('GetItem devuelve el objeto o lanza ItemNotFoundException', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      expect(await GetItem(repository)('item-1'), item());
      await expectLater(GetItem(repository)('missing'), throwsA(isA<ItemNotFoundException>()));
    });

    test('SearchItems recorta la consulta', () async {
      when(() => repository.searchByName(any())).thenAnswer((_) async => <HouseholdItem>[item()]);

      expect(await SearchItems(repository)('  caja '), <HouseholdItem>[item()]);
      verify(() => repository.searchByName('caja')).called(1);
    });

    test('los casos de observación delegan en el repositorio', () {
      final Stream<HouseholdItem?> itemStream = Stream<HouseholdItem?>.value(item());
      final Stream<List<HouseholdItem>> itemsStream = Stream<List<HouseholdItem>>.value(<HouseholdItem>[item()]);
      final Stream<List<PhysicalIdentifier>> identifiersStream =
          Stream<List<PhysicalIdentifier>>.value(<PhysicalIdentifier>[identifier()]);
      final Stream<List<ItemEvent>> eventsStream = Stream<List<ItemEvent>>.value(const <ItemEvent>[]);
      when(() => repository.watchById('item-1')).thenAnswer((_) => itemStream);
      when(() => repository.watchAll()).thenAnswer((_) => itemsStream);
      when(() => repository.watchIdentifiers('item-1')).thenAnswer((_) => identifiersStream);
      when(() => repository.watchEvents('item-1')).thenAnswer((_) => eventsStream);

      expect(WatchItem(repository)('item-1'), same(itemStream));
      expect(WatchItems(repository)(), same(itemsStream));
      expect(WatchItemIdentifiers(repository)('item-1'), same(identifiersStream));
      expect(WatchItemEvents(repository)('item-1'), same(eventsStream));
    });

    test('WatchItemTree convierte el listado en un árbol', () async {
      when(() => repository.watchAll()).thenAnswer(
        (_) => Stream<List<HouseholdItem>>.value(<HouseholdItem>[item(id: 'box'), item(id: 'drawer', parentId: 'box')]),
      );

      final ItemTree tree = await WatchItemTree(repository)().first;

      expect(tree.depthOf('drawer'), 2);
    });
  });
}
