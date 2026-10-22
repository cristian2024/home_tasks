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
    when(() => repository.findIdentifier(any(), any())).thenAnswer((_) async => null);
    when(() => repository.getById(any())).thenAnswer((_) async => null);
  });

  tearDown(() => eventBus.dispose());

  group('CreateItem', () {
    late CreateItem createItem;

    setUp(() => createItem = CreateItem(repository, ids, clock, eventBus));

    test('crea el objeto con evento técnico y publica ItemCreatedCrossEvent', () async {
      final published = eventBus.on<ItemCreatedCrossEvent>().first;

      final created = await createItem(name: '  Caja A ', description: 'Garaje', metadata: {'fragil': true});

      expect(created, item(id: 'id-1', description: 'Garaje', metadata: ItemMetadata({'fragil': true})));
      final captured = verify(
        () => repository.createItem(captureAny(), identifier: captureAny(named: 'identifier'), events: captureAny(named: 'events')),
      ).captured;
      // mocktail captura los argumentos con nombre en orden alfabético.
      expect(captured[0], created);
      expect(captured[2], isNull);
      expect(captured[1], [
        ItemEvent(id: 'id-2', itemId: 'id-1', kind: ItemEventKind.created, title: 'Caja A', description: '', timestamp: t0),
      ]);
      expect((await published).itemId, 'id-1');
    });

    test('asocia el identificador inicial y registra su evento', () async {
      await createItem(name: 'Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr));

      final captured = verify(
        () => repository.createItem(any(), identifier: captureAny(named: 'identifier'), events: captureAny(named: 'events')),
      ).captured;
      final events = captured[0] as List<ItemEvent>;
      expect(
        captured[1],
        PhysicalIdentifier(id: 'id-2', rawValue: 'QR-123', type: IdentifierType.qr, itemId: 'id-1', boundAt: t0),
      );
      expect(events.map((e) => e.kind), [ItemEventKind.created, ItemEventKind.identifierBound]);
      expect(events.last.description, 'QR-123');
    });

    test('rechaza un identificador ya asociado sin escribir nada', () async {
      when(() => repository.findIdentifier('QR-123', IdentifierType.qr))
          .thenAnswer((_) async => identifier(itemId: 'other'));

      await expectLater(
        createItem(name: 'Caja A', identifier: (rawValue: 'QR-123', type: IdentifierType.qr)),
        throwsA(isA<IdentifierAlreadyBoundException>().having((e) => e.boundItemId, 'boundItemId', 'other')),
      );
      verifyNever(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')));
    });

    test('valida nombre, metadatos e identificador antes de escribir', () async {
      await expectLater(createItem(name: ' '), throwsValidation(ValidationField.name, ValidationReason.empty));
      await expectLater(
        createItem(name: 'A', metadata: {'Mal': 1}),
        throwsValidation(ValidationField.metadata, ValidationReason.invalidFormat),
      );
      await expectLater(
        createItem(name: 'A', identifier: (rawValue: '', type: IdentifierType.nfc)),
        throwsValidation(ValidationField.identifierValue, ValidationReason.empty),
      );
      verifyNever(() => repository.createItem(any(), identifier: any(named: 'identifier'), events: any(named: 'events')));
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

      final result = await updateItem('item-1', name: ' Caja A ', description: '', metadata: {});

      expect(result, item());
      verifyNever(() => repository.updateItem(any(), any()));
    });

    test('actualiza updatedAt y registra los campos cambiados', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());
      clock.advance(const Duration(hours: 1));

      final result = await updateItem('item-1', name: 'Caja B', metadata: {'peso_kg': 2});

      final later = t0.add(const Duration(hours: 1));
      expect(result, item(name: 'Caja B', metadata: ItemMetadata({'peso_kg': 2}), updatedAt: later));
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

      final event = verify(() => repository.updateItem(any(), captureAny())).captured.single as ItemEvent;
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

      final bound = await bindIdentifier('item-1', rawValue: 'NFC-BED', type: IdentifierType.nfc);

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
        throwsA(isA<IdentifierAlreadyBoundException>().having((e) => e.boundItemId, 'boundItemId', 'item-1')),
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

  group('AddItemEvent', () {
    late AddItemEvent addItemEvent;

    setUp(() => addItemEvent = AddItemEvent(repository, ids, clock));

    test('añade una nota del usuario', () async {
      when(() => repository.getById('item-1')).thenAnswer((_) async => item());

      final event = await addItemEvent('item-1', title: ' Cambio de Ubicación ', description: 'Al altillo.');

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
      when(() => repository.searchByName(any())).thenAnswer((_) async => [item()]);

      expect(await SearchItems(repository)('  caja '), [item()]);
      verify(() => repository.searchByName('caja')).called(1);
    });

    test('los casos de observación delegan en el repositorio', () {
      final itemStream = Stream<HouseholdItem?>.value(item());
      final itemsStream = Stream<List<HouseholdItem>>.value([item()]);
      final identifiersStream = Stream<List<PhysicalIdentifier>>.value([identifier()]);
      final eventsStream = Stream<List<ItemEvent>>.value(const []);
      when(() => repository.watchById('item-1')).thenAnswer((_) => itemStream);
      when(() => repository.watchAll()).thenAnswer((_) => itemsStream);
      when(() => repository.watchIdentifiers('item-1')).thenAnswer((_) => identifiersStream);
      when(() => repository.watchEvents('item-1')).thenAnswer((_) => eventsStream);

      expect(WatchItem(repository)('item-1'), same(itemStream));
      expect(WatchItems(repository)(), same(itemsStream));
      expect(WatchItemIdentifiers(repository)('item-1'), same(identifiersStream));
      expect(WatchItemEvents(repository)('item-1'), same(eventsStream));
    });
  });
}
