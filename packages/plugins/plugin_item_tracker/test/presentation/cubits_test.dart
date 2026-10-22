import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/presentation/add_event/add_event_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/associate/associate_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/detail/item_detail_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/form/item_form_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/list/item_list_cubit.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late TestUseCases useCases;

  setUp(() => useCases = TestUseCases());

  group('ItemListCubit', () {
    test('lista los objetos y filtra por nombre sin distinguir mayúsculas', () async {
      await useCases.createItem(name: 'Caja de herramientas');
      await useCases.createItem(name: 'Cama');
      final cubit = ItemListCubit(WatchItems(useCases.repository));
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.visible, hasLength(2));

      cubit.search('  CAJA ');
      expect(cubit.state.visible.map((i) => i.name), ['Caja de herramientas']);
    });
  });

  group('ItemDetailCubit', () {
    ItemDetailCubit build(String id) => ItemDetailCubit(
          id,
          watchItem: WatchItem(useCases.repository),
          watchItemIdentifiers: WatchItemIdentifiers(useCases.repository),
          watchItemEvents: WatchItemEvents(useCases.repository),
        );

    test('combina objeto, identificadores e historial y reacciona a cambios', () async {
      final item = await useCases.createItem(name: 'Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
      final cubit = build(item.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ItemDetailStatus.loaded);
      expect(cubit.state.item, item);
      expect(cubit.state.identifiers.single.rawValue, 'QR-BED');
      expect(cubit.state.events, hasLength(2));

      await useCases.bindIdentifier(item.id, rawValue: 'NFC-BED', type: IdentifierType.nfc);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.identifiers, hasLength(2));
      expect(cubit.state.events, hasLength(3));
    });

    test('informa missing si el objeto no existe', () async {
      final cubit = build('missing');
      addTearDown(cubit.close);
      expect(cubit.state.status, ItemDetailStatus.loading);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ItemDetailStatus.missing);
    });
  });

  group('ItemFormCubit', () {
    ItemFormCubit create({({String rawValue, IdentifierType type})? identifier}) =>
        ItemFormCubit.create(createItem: useCases.createItem, identifier: identifier);

    test('crea el objeto con metadatos tipados y el identificador inicial', () async {
      final cubit = create(identifier: (rawValue: 'UNKNOWN-99', type: IdentifierType.qr));
      addTearDown(cubit.close);
      cubit
        ..addEntry()
        ..addEntry()
        ..addEntry()
        ..addEntry();
      final [color, weight, fragile, empty] = cubit.state.entries;
      cubit
        ..updateEntry(color.copyWith(key: 'color_etiqueta', text: 'Azul'))
        ..updateEntry(weight.copyWith(key: 'peso_kg', type: MetadataValueType.number, text: '12,5'))
        ..updateEntry(fragile.copyWith(key: 'fragil', type: MetadataValueType.boolean, flag: true))
        ..updateEntry(empty); // Fila vacía: se ignora.

      await cubit.submit(name: 'Caja A', description: '');

      expect(cubit.state.status, ItemFormStatus.saved);
      final saved = (await useCases.repository.getById(cubit.state.savedItemId!))!;
      expect(saved.metadata.values, {'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'fragil': true});
      expect(await useCases.findItemByIdentifier(rawValue: 'UNKNOWN-99', type: IdentifierType.qr), saved);
    });

    test('señala claves repetidas y números inválidos en su fila', () async {
      final cubit = create();
      addTearDown(cubit.close);
      cubit
        ..addEntry()
        ..addEntry();
      final [first, second] = cubit.state.entries;
      cubit
        ..updateEntry(first.copyWith(key: 'a', text: '1'))
        ..updateEntry(second.copyWith(key: 'a', text: '2'));

      await cubit.submit(name: 'X', description: '');
      expect(cubit.state.error, ItemFormDuplicatedKey('a', second.id));

      cubit.updateEntry(second.copyWith(key: 'b', type: MetadataValueType.number, text: 'doce'));
      await cubit.submit(name: 'X', description: '');
      expect(cubit.state.error, ItemFormInvalidNumber(second.id));
      expect(cubit.state.status, ItemFormStatus.editing);
    });

    test('mapea los errores de validación al campo o a la fila', () async {
      final cubit = create();
      addTearDown(cubit.close);
      await cubit.submit(name: ' ', description: '');
      expect(
        cubit.state.error,
        const ItemFormValidationError(ItemValidationException(ValidationField.name, ValidationReason.empty)),
      );

      cubit.addEntry();
      final entry = cubit.state.entries.single;
      cubit.updateEntry(entry.copyWith(key: 'Mal', text: 'x'));
      await cubit.submit(name: 'Caja', description: '');
      final error = cubit.state.error! as ItemFormValidationError;
      expect(error.entryId, entry.id);
      expect(error.error.reason, ValidationReason.invalidFormat);

      cubit.removeEntry(entry.id);
      expect(cubit.state.entries, isEmpty);
    });

    test('un identificador ya asociado es un error general', () async {
      await useCases.createItem(name: 'Otro', identifier: (rawValue: 'QR', type: IdentifierType.qr));
      final cubit = create(identifier: (rawValue: 'QR', type: IdentifierType.qr));
      addTearDown(cubit.close);

      await cubit.submit(name: 'Caja', description: '');

      expect((cubit.state.error! as ItemFormGeneralError).error, isA<IdentifierAlreadyBoundException>());
    });

    test('edición: carga el objeto con sus metadatos y guarda los cambios', () async {
      final item = await useCases.createItem(name: 'Caja', metadata: {'peso_kg': 3, 'fragil': false, 'color': 'Azul'});
      final cubit = ItemFormCubit.edit(
        item.id,
        getItem: GetItem(useCases.repository),
        updateItem: UpdateItem(useCases.repository, useCases.ids, useCases.clock),
      );
      addTearDown(cubit.close);
      expect(cubit.state.status, ItemFormStatus.loading);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isEditing, isTrue);
      expect(cubit.state.name, 'Caja');
      expect(cubit.state.entries.map((e) => (e.key, e.type, e.text, e.flag)), [
        ('peso_kg', MetadataValueType.number, '3', false),
        ('fragil', MetadataValueType.boolean, '', false),
        ('color', MetadataValueType.text, 'Azul', false),
      ]);

      await cubit.submit(name: 'Caja grande', description: 'Garaje');

      expect(cubit.state.status, ItemFormStatus.saved);
      expect((await useCases.repository.getById(item.id))!.name, 'Caja grande');
    });

    test('edición de un objeto inexistente muestra un error general', () async {
      final cubit = ItemFormCubit.edit(
        'missing',
        getItem: GetItem(useCases.repository),
        updateItem: UpdateItem(useCases.repository, useCases.ids, useCases.clock),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state.error! as ItemFormGeneralError).error, isA<ItemNotFoundException>());
    });
  });

  group('AssociateCubit', () {
    AssociateCubit build() => AssociateCubit(
          identifier: (rawValue: 'NFC-BED', type: IdentifierType.nfc),
          searchItems: SearchItems(useCases.repository),
          bindIdentifier: useCases.bindIdentifier,
        );

    test('AC-05: asocia el identificador al objeto elegido', () async {
      final bed = await useCases.createItem(name: 'Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
      await useCases.createItem(name: 'Mesa');
      final cubit = build();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.results, hasLength(2));

      await cubit.search('cam');
      expect(cubit.state.results.single, bed);

      await cubit.bind(bed);

      expect(cubit.state.status, AssociateStatus.bound);
      expect(cubit.state.boundItem, bed);
      expect(await useCases.findItemByIdentifier(rawValue: 'NFC-BED', type: IdentifierType.nfc), bed);
      expect(await useCases.findItemByIdentifier(rawValue: 'QR-BED', type: IdentifierType.qr), bed);
    });

    test('rechaza un identificador ya asociado', () async {
      final other = await useCases.createItem(name: 'Otro', identifier: (rawValue: 'NFC-BED', type: IdentifierType.nfc));
      final bed = await useCases.createItem(name: 'Cama');
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.bind(bed);

      expect(cubit.state.status, AssociateStatus.ready);
      expect(
        cubit.state.error,
        isA<IdentifierAlreadyBoundException>().having((e) => e.boundItemId, 'boundItemId', other.id),
      );
    });
  });

  group('AddEventCubit', () {
    blocTest<AddEventCubit, AddEventState>(
      'guarda la nota',
      setUp: () async => useCases.createItem(name: 'Caja'),
      build: () => AddEventCubit('id-1', addItemEvent: AddItemEvent(useCases.repository, useCases.ids, useCases.clock)),
      act: (cubit) => cubit.submit(title: 'Mudanza', description: 'Al altillo'),
      expect: () => [
        const AddEventState(status: AddEventStatus.submitting),
        const AddEventState(status: AddEventStatus.saved),
      ],
    );

    blocTest<AddEventCubit, AddEventState>(
      'sin título vuelve a edición con el error',
      build: () => AddEventCubit('id-1', addItemEvent: AddItemEvent(useCases.repository, useCases.ids, useCases.clock)),
      act: (cubit) => cubit.submit(title: '', description: ''),
      expect: () => [
        const AddEventState(status: AddEventStatus.submitting),
        isA<AddEventState>().having((s) => s.error, 'error', isA<ItemValidationException>()),
      ],
    );
  });
}
