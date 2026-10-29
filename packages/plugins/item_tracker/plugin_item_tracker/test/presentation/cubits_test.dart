import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/src/presentation/add_event/add_event_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/associate/associate_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/detail/item_detail_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/form/item_form_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/list/item_list_cubit.dart';
import 'package:plugin_item_tracker/src/presentation/move/move_item_cubit.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late TestUseCases useCases;

  setUp(() => useCases = TestUseCases());

  group('ItemListCubit', () {
    test('lista los objetos y filtra por nombre sin distinguir mayúsculas', () async {
      await useCases.createItem(name: 'Caja de herramientas');
      await useCases.createItem(name: 'Cama');
      final ItemListCubit cubit = ItemListCubit(useCases.watchItemTree);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.visible, hasLength(2));

      cubit.search('  CAJA ');
      expect(cubit.state.visible.map((HouseholdItem i) => i.name), <String>['Caja de herramientas']);
    });

    test('incluye los objetos que están dentro de otros con su jerarquía', () async {
      final HouseholdItem furniture = await useCases.createItem(name: 'Mueble');
      final HouseholdItem drawer = await useCases.createItem(name: 'Cajón', parentId: furniture.id);
      final ItemListCubit cubit = ItemListCubit(useCases.watchItemTree);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.all.map((HouseholdItem i) => i.name), unorderedEquals(<dynamic>['Cajón', 'Mueble']));
      expect(cubit.state.tree.pathOf(drawer.id), <HouseholdItem>[furniture]);
    });
  });

  group('ItemDetailCubit', () {
    ItemDetailCubit build(String id) => ItemDetailCubit(
          id,
          watchItem: WatchItem(useCases.repository),
          watchItemIdentifiers: WatchItemIdentifiers(useCases.repository),
          watchItemEvents: WatchItemEvents(useCases.repository),
          watchItemTree: useCases.watchItemTree,
          unbindIdentifier: useCases.unbindIdentifier,
          moveItem: useCases.moveItem,
          deleteItem: useCases.deleteItem,
          containmentPolicy: useCases.policy,
        );

    test('combina objeto, identificadores e historial y reacciona a cambios', () async {
      final HouseholdItem item =
          await useCases.createItem(name: 'Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
      final ItemDetailCubit cubit = build(item.id);
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

    test('quita un identificador y el detalle se actualiza; un segundo intento devuelve el error', () async {
      final HouseholdItem item =
          await useCases.createItem(name: 'Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
      final ItemDetailCubit cubit = build(item.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      final PhysicalIdentifier identifier = cubit.state.identifiers.single;

      expect(await cubit.removeIdentifier(identifier), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.identifiers, isEmpty);
      // El reloj fijo da a todos los eventos el mismo instante: no se compara el orden.
      expect(cubit.state.events.map((ItemEvent event) => event.kind), contains(ItemEventKind.identifierUnbound));
      expect(await cubit.removeIdentifier(identifier), isA<IdentifierNotFoundException>());
    });

    test('cuenta todo lo que contiene y lo borra; un segundo intento devuelve el error', () async {
      final HouseholdItem furniture = await useCases.createItem(name: 'Mueble');
      final HouseholdItem organizer = await useCases.createItem(name: 'Organizador', parentId: furniture.id);
      await useCases.createItem(name: 'Cajón', parentId: organizer.id);
      final ItemDetailCubit cubit = build(furniture.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.children, <HouseholdItem>[organizer]);
      expect(cubit.state.descendantCount, 2);

      expect(await cubit.delete(DeletedContents.moveToParent), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ItemDetailStatus.missing);
      expect((await useCases.repository.getById(organizer.id))?.parentId, isNull);
      expect(await cubit.delete(DeletedContents.deleteAll), isA<ItemNotFoundException>());
    });

    test('informa missing si el objeto no existe', () async {
      final ItemDetailCubit cubit = build('missing');
      addTearDown(cubit.close);
      expect(cubit.state.status, ItemDetailStatus.loading);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ItemDetailStatus.missing);
    });

    test('muestra la ruta y el contenido, y saca el objeto de su contenedor', () async {
      final HouseholdItem furniture = await useCases.createItem(name: 'Mueble');
      final HouseholdItem organizer = await useCases.createItem(name: 'Organizador', parentId: furniture.id);
      final HouseholdItem drawer = await useCases.createItem(name: 'Cajón', parentId: organizer.id);
      final ItemDetailCubit cubit = build(organizer.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.path, <HouseholdItem>[furniture]);
      expect(cubit.state.children, <HouseholdItem>[drawer]);
      expect(cubit.state.depth, 2);
      expect(cubit.state.canHoldMore, isTrue);
      expect(cubit.state.isOverflowing, isFalse);

      expect(await cubit.moveOut(), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.path, isEmpty);
      expect(cubit.state.depth, 1);
      expect(cubit.state.item?.parentId, isNull);
    });

    test('señala el contenedor lleno y el desbordado cuando se bajó el límite', () async {
      useCases = TestUseCases(policy: const ContainmentPolicy(maxDepth: 2));
      final HouseholdItem furniture = await useCases.createItem(name: 'Mueble');
      final HouseholdItem organizer = await useCases.createItem(name: 'Organizador', parentId: furniture.id);
      // El cajón quedó en el nivel 3 antes de bajar el límite.
      final HouseholdItem drawer = await useCases.createItem(name: 'Cajón');
      await useCases.repository.moveItem(drawer.copyWith(parentId: () => organizer.id), const <ItemEvent>[]);

      final ItemDetailCubit full = build(furniture.id);
      final ItemDetailCubit overflowing = build(organizer.id);
      final ItemDetailCubit leaf = build(drawer.id);
      addTearDown(full.close);
      addTearDown(overflowing.close);
      addTearDown(leaf.close);
      await Future<void>.delayed(Duration.zero);

      expect(full.state.canHoldMore, isTrue);
      expect(overflowing.state.canHoldMore, isFalse);
      expect(overflowing.state.isOverflowing, isTrue);
      expect(leaf.state.isOverflowing, isFalse);
      expect(leaf.state.maxDepth, 2);
    });

    test('sacar un objeto que ya no existe devuelve el error', () async {
      final ItemDetailCubit cubit = build('missing');
      addTearDown(cubit.close);

      expect(await cubit.moveOut(), isA<ItemNotFoundException>());
    });
  });

  group('ItemFormCubit', () {
    ItemFormCubit create({({String rawValue, IdentifierType type})? identifier}) =>
        ItemFormCubit.create(createItem: useCases.createItem, identifier: identifier);

    test('crea el objeto con metadatos tipados y el identificador inicial', () async {
      final ItemFormCubit cubit = create(identifier: (rawValue: 'UNKNOWN-99', type: IdentifierType.qr));
      addTearDown(cubit.close);
      cubit
        ..addEntry()
        ..addEntry()
        ..addEntry()
        ..addEntry();
      final [MetadataEntry color, MetadataEntry weight, MetadataEntry fragile, MetadataEntry empty] =
          cubit.state.entries;
      cubit
        ..updateEntry(color.copyWith(key: 'color_etiqueta', text: 'Azul'))
        ..updateEntry(weight.copyWith(key: 'peso_kg', type: MetadataValueType.number, text: '12,5'))
        ..updateEntry(fragile.copyWith(key: 'fragil', type: MetadataValueType.boolean, flag: true))
        ..updateEntry(empty); // Fila vacía: se ignora.

      await cubit.submit(name: 'Caja A', description: '');

      expect(cubit.state.status, ItemFormStatus.saved);
      final HouseholdItem saved = (await useCases.repository.getById(cubit.state.savedItemId!))!;
      expect(saved.metadata.values, <String, Object>{'color_etiqueta': 'Azul', 'peso_kg': 12.5, 'fragil': true});
      expect(await useCases.findItemByIdentifier(rawValue: 'UNKNOWN-99', type: IdentifierType.qr), saved);
    });

    test('señala claves repetidas y números inválidos en su fila', () async {
      final ItemFormCubit cubit = create();
      addTearDown(cubit.close);
      cubit
        ..addEntry()
        ..addEntry();
      final [MetadataEntry first, MetadataEntry second] = cubit.state.entries;
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
      final ItemFormCubit cubit = create();
      addTearDown(cubit.close);
      await cubit.submit(name: ' ', description: '');
      expect(
        cubit.state.error,
        const ItemFormValidationError(ItemValidationException(ValidationField.name, ValidationReason.empty)),
      );

      cubit.addEntry();
      final MetadataEntry entry = cubit.state.entries.single;
      cubit.updateEntry(entry.copyWith(key: 'Mal', text: 'x'));
      await cubit.submit(name: 'Caja', description: '');
      final ItemFormValidationError error = cubit.state.error! as ItemFormValidationError;
      expect(error.entryId, entry.id);
      expect(error.error.reason, ValidationReason.invalidFormat);

      cubit.removeEntry(entry.id);
      expect(cubit.state.entries, isEmpty);
    });

    test('un identificador ya asociado es un error general', () async {
      await useCases.createItem(name: 'Otro', identifier: (rawValue: 'QR', type: IdentifierType.qr));
      final ItemFormCubit cubit = create(identifier: (rawValue: 'QR', type: IdentifierType.qr));
      addTearDown(cubit.close);

      await cubit.submit(name: 'Caja', description: '');

      expect((cubit.state.error! as ItemFormGeneralError).error, isA<IdentifierAlreadyBoundException>());
    });

    test('edición: carga el objeto con sus metadatos y guarda los cambios', () async {
      final HouseholdItem item = await useCases.createItem(
        name: 'Caja',
        metadata: <String,
        Object?>{'peso_kg': 3, 'fragil': false, 'color': 'Azul'},
      );
      final ItemFormCubit cubit = ItemFormCubit.edit(
        item.id,
        getItem: GetItem(useCases.repository),
        updateItem: UpdateItem(useCases.repository, useCases.ids, useCases.clock),
      );
      addTearDown(cubit.close);
      expect(cubit.state.status, ItemFormStatus.loading);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isEditing, isTrue);
      expect(cubit.state.name, 'Caja');
      expect(
        cubit.state.entries.map((MetadataEntry e) => (e.key, e.type, e.text, e.flag)),
        <(String, MetadataValueType, String, bool)>[
          ('peso_kg', MetadataValueType.number, '3', false),
          ('fragil', MetadataValueType.boolean, '', false),
          ('color', MetadataValueType.text, 'Azul', false),
        ],
      );

      await cubit.submit(name: 'Caja grande', description: 'Garaje');

      expect(cubit.state.status, ItemFormStatus.saved);
      expect((await useCases.repository.getById(item.id))!.name, 'Caja grande');
    });

    test('edición de un objeto inexistente muestra un error general', () async {
      final ItemFormCubit cubit = ItemFormCubit.edit(
        'missing',
        getItem: GetItem(useCases.repository),
        updateItem: UpdateItem(useCases.repository, useCases.ids, useCases.clock),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state.error! as ItemFormGeneralError).error, isA<ItemNotFoundException>());
    });

    test('crea el objeto dentro del contenedor indicado y muestra su ruta', () async {
      final HouseholdItem furniture = await useCases.createItem(name: 'Mueble');
      final HouseholdItem organizer = await useCases.createItem(name: 'Organizador', parentId: furniture.id);
      final ItemFormCubit cubit = ItemFormCubit.create(
        createItem: useCases.createItem,
        parentId: organizer.id,
        watchItemTree: useCases.watchItemTree,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.parentPath, <HouseholdItem>[furniture, organizer]);

      await cubit.submit(name: 'Cajón', description: '');

      expect(cubit.state.status, ItemFormStatus.saved);
      expect((await useCases.repository.getById(cubit.state.savedItemId!))!.parentId, organizer.id);
    });

    test('si el contenedor ya no existe, no muestra ruta y el error llega al guardar', () async {
      final ItemFormCubit cubit = ItemFormCubit.create(
        createItem: useCases.createItem,
        parentId: 'missing',
        watchItemTree: useCases.watchItemTree,
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.parentPath, isEmpty);

      await cubit.submit(name: 'Cajón', description: '');

      expect((cubit.state.error! as ItemFormGeneralError).error, isA<ItemNotFoundException>());
    });
  });

  group('MoveItemCubit', () {
    late HouseholdItem furniture;
    late HouseholdItem organizer;
    late HouseholdItem drawer;
    late HouseholdItem scissors;

    // Mueble › Organizador › Cajón y Tijeras suelta.
    setUp(() async {
      furniture = await useCases.createItem(name: 'Mueble');
      organizer = await useCases.createItem(name: 'Organizador', parentId: furniture.id);
      drawer = await useCases.createItem(name: 'Cajón', parentId: organizer.id);
      scissors = await useCases.createItem(name: 'Tijeras');
    });

    MoveItemCubit build(String id) => MoveItemCubit(
          id,
          watchItemTree: useCases.watchItemTree,
          moveItem: useCases.moveItem,
          containmentPolicy: useCases.policy,
        );

    test('excluye el objeto y su contenido, y marca el contenedor actual', () async {
      final MoveItemCubit cubit = build(organizer.id);
      addTearDown(cubit.close);
      expect(cubit.state.status, MoveItemStatus.loading);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, MoveItemStatus.ready);
      expect(cubit.state.item, organizer);
      expect(cubit.state.candidates, <MoveCandidate>[
        MoveCandidate(item: furniture, path: const <HouseholdItem>[], block: MoveBlock.current),
        MoveCandidate(item: scissors, path: const <HouseholdItem>[]),
      ]);

      cubit.search(' TIJ ');
      expect(cubit.state.visible.map((MoveCandidate c) => c.item), <HouseholdItem>[scissors]);
    });

    test('bloquea los destinos que superarían el máximo de niveles', () async {
      final MoveItemCubit cubit = MoveItemCubit(
        furniture.id,
        watchItemTree: useCases.watchItemTree,
        moveItem: useCases.moveItem,
        containmentPolicy: const ContainmentPolicy(maxDepth: 3),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      // El mueble ocupa 3 niveles: solo cabe sin contenedor.
      expect(
        cubit.state.candidates.single,
        MoveCandidate(item: scissors, path: const <HouseholdItem>[], block: MoveBlock.tooDeep),
      );
      expect(cubit.maxDepth, 3);
    });

    test('mueve el objeto al contenedor elegido', () async {
      final MoveItemCubit cubit = build(drawer.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      await cubit.moveTo(scissors);

      expect(cubit.state.status, MoveItemStatus.moved);
      expect(cubit.state.destination, scissors);
      expect((await useCases.repository.getById(drawer.id))!.parentId, scissors.id);

      await cubit.moveTo(furniture); // Ya terminó: se ignora.
      expect((await useCases.repository.getById(drawer.id))!.parentId, scissors.id);
    });

    test('muestra el error si el destino dejó de ser válido', () async {
      final MoveItemCubit cubit = build(furniture.id);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      await cubit.moveTo(drawer); // Está dentro del mueble.

      expect(cubit.state.status, MoveItemStatus.ready);
      expect(cubit.state.error, isA<ItemContainmentCycleException>());
    });

    test('informa missing si el objeto no existe', () async {
      final MoveItemCubit cubit = build('missing');
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, MoveItemStatus.missing);
    });
  });

  group('AssociateCubit', () {
    AssociateCubit build() => AssociateCubit(
          identifier: (rawValue: 'NFC-BED', type: IdentifierType.nfc),
          searchItems: SearchItems(useCases.repository),
          bindIdentifier: useCases.bindIdentifier,
        );

    test('AC-05: asocia el identificador al objeto elegido', () async {
      final HouseholdItem bed =
          await useCases.createItem(name: 'Cama', identifier: (rawValue: 'QR-BED', type: IdentifierType.qr));
      await useCases.createItem(name: 'Mesa');
      final AssociateCubit cubit = build();
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
      final HouseholdItem other =
          await useCases.createItem(name: 'Otro', identifier: (rawValue: 'NFC-BED', type: IdentifierType.nfc));
      final HouseholdItem bed = await useCases.createItem(name: 'Cama');
      final AssociateCubit cubit = build();
      addTearDown(cubit.close);

      await cubit.bind(bed);

      expect(cubit.state.status, AssociateStatus.ready);
      expect(
        cubit.state.error,
        isA<IdentifierAlreadyBoundException>()
            .having((IdentifierAlreadyBoundException e) => e.boundItemId, 'boundItemId', other.id),
      );
    });
  });

  group('AddEventCubit', () {
    blocTest<AddEventCubit, AddEventState>(
      'guarda la nota',
      setUp: () async => useCases.createItem(name: 'Caja'),
      build: () => AddEventCubit('id-1', addItemEvent: AddItemEvent(useCases.repository, useCases.ids, useCases.clock)),
      act: (AddEventCubit cubit) => cubit.submit(title: 'Mudanza', description: 'Al altillo'),
      expect: () => <AddEventState>[
        const AddEventState(status: AddEventStatus.submitting),
        const AddEventState(status: AddEventStatus.saved),
      ],
    );

    blocTest<AddEventCubit, AddEventState>(
      'sin título vuelve a edición con el error',
      build: () => AddEventCubit('id-1', addItemEvent: AddItemEvent(useCases.repository, useCases.ids, useCases.clock)),
      act: (AddEventCubit cubit) => cubit.submit(title: '', description: ''),
      expect: () => <Object>[
        const AddEventState(status: AddEventStatus.submitting),
        isA<AddEventState>().having((AddEventState s) => s.error, 'error', isA<ItemValidationException>()),
      ],
    );
  });
}
