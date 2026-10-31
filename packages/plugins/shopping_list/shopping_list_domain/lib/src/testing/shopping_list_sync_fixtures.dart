import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';
import '../repositories/shopping_list_repository.dart';
import '../sync/shopping_list_codec.dart';
import '../sync/shopping_list_resolver.dart';
import '../sync/shopping_list_sync_participant.dart';

/// Lo que necesita [shoppingListSyncContract]: un repositorio que se
/// sincroniza, su participante y el log donde registra.
class ShoppingListSyncSubject {
  ShoppingListSyncSubject({required this.repository, required this.participant, required this.log});

  final ShoppingListRepository repository;
  final ShoppingListSyncParticipant participant;
  final ChangeLog log;
}

/// Crea un [ShoppingListSyncSubject] vacío. Los cambios locales los hace el
/// dispositivo `device-local`, con marcas posteriores a las de
/// [shoppingListSyncRecords].
typedef ShoppingListSyncFactory = FutureOr<ShoppingListSyncSubject> Function();

const int _t0 = 1761827400000;

/// Cambios de tres dispositivos con ediciones concurrentes y un caso de cada
/// regla (spec §10.4.4):
/// - `milk` renombrado a la vez en A y B: gana B («Leche desnatada»);
/// - A y B sembraron su categoría «food»: queda `cat-a-food` y `bread`, de B,
///   pasa a ella;
/// - B añade `cat-pets` a `milk` mientras C la borra: la referencia se ignora;
/// - A y B compran `eggs` sin saber uno del otro: cuenta la de A
///   (`doublePurchase`) y `eggs` toma su fecha;
/// - A compra `rice` y lo deshace mientras B cambia la cantidad;
/// - C borra `soap` mientras A cambia sus notas: queda borrado;
/// - `milk` y `milk-2` se llaman igual: quedan los dos.
List<ChangeRecord> shoppingListSyncRecords() {
  ChangeRecord record(String device, int seq, String collection, String entityId, int at, List<FieldChange> changes) =>
      ChangeRecord(
        opId: '$device-$seq',
        deviceId: device,
        seq: seq,
        collection: collection,
        entityId: entityId,
        hlc: Hlc(wallTime: _t0 + at, counter: 0, deviceId: device),
        changes: changes,
      );
  List<FieldChange> values(Map<String, Object?> fields) => FieldDiff.between(null, fields);
  List<FieldChange> item(String id, String name, int at, {Set<String> categoryIds = const <String>{}}) =>
      values(ShoppingListCodec.itemFields(_item(id, name, at, categoryIds: categoryIds.toList())));
  List<FieldChange> category(String id, int sortOrder, {String? name, String? defaultKey}) =>
      values(ShoppingListCodec.categoryFields(ShoppingCategory(id: id, sortOrder: sortOrder, name: name, defaultKey: defaultKey)));
  List<FieldChange> purchase(String id, String itemId, int at) => values(ShoppingListCodec.purchaseFields(
        ShoppingPurchase(id: id, itemId: itemId, purchasedAt: _at(at)),
        previousPurchase: null,
      ));
  /// Comprado en [at] o, sin [at], la compra deshecha en 36.
  List<FieldChange> bought(int? at) => <FieldChange>[
        ValueChange('status', (at == null ? ShoppingItemStatus.pending : ShoppingItemStatus.purchased).name),
        ValueChange(ShoppingListCodec.lastPurchasedAt, at == null ? null : _at(at).toIso8601String()),
        ValueChange('updatedAt', _at(at ?? 36).toIso8601String()),
      ];
  List<FieldChange> deletion(int at) => values(ShoppingListCodec.deletion(_at(at)));
  const String items = ShoppingListCollections.items;
  const String categories = ShoppingListCollections.categories;
  const String purchases = ShoppingListCollections.purchases;
  return <ChangeRecord>[
    record('device-a', 1, categories, 'cat-a-food', 1, category('cat-a-food', 0, defaultKey: 'food')),
    record('device-a', 2, categories, 'cat-pets', 2, category('cat-pets', 5, name: 'Mascotas')),
    record('device-a', 3, items, 'milk', 3, item('milk', 'Leche', 3, categoryIds: <String>{'cat-a-food'})),
    record('device-a', 4, items, 'eggs', 4, item('eggs', 'Huevos', 4)),
    record('device-a', 5, items, 'rice', 5, item('rice', 'Arroz', 5)),
    record('device-a', 6, items, 'milk', 10, <FieldChange>[ValueChange('name', 'Leche entera')]),
    record('device-a', 7, purchases, 'p-a', 30, purchase('p-a', 'eggs', 30)),
    record('device-a', 8, items, 'eggs', 30, bought(30)),
    record('device-a', 9, purchases, 'p-rice', 35, purchase('p-rice', 'rice', 35)),
    record('device-a', 10, items, 'rice', 35, bought(35)),
    record('device-a', 11, purchases, 'p-rice', 36, deletion(36)),
    record('device-a', 12, items, 'rice', 36, bought(null)),
    record('device-a', 13, items, 'soap', 60, <FieldChange>[ValueChange('notes', 'El de lavanda')]),
    record('device-b', 1, categories, 'cat-b-food', 1, category('cat-b-food', 0, defaultKey: 'food')),
    record('device-b', 2, items, 'bread', 6, item('bread', 'Pan', 6, categoryIds: <String>{'cat-b-food'})),
    record('device-b', 3, items, 'milk-2', 7, item('milk-2', 'Leche', 7)),
    record('device-b', 4, items, 'milk', 11, <FieldChange>[ValueChange('name', 'Leche desnatada')]),
    record('device-b', 5, purchases, 'p-b', 32, purchase('p-b', 'eggs', 32)),
    record('device-b', 6, items, 'eggs', 32, bought(32)),
    record('device-b', 7, items, 'rice', 37, <FieldChange>[ValueChange('quantity', '2 kg')]),
    record('device-b', 8, items, 'milk', 40, <FieldChange>[ElementChange(ShoppingListCodec.categoryIds, 'cat-pets', present: true)]),
    record('device-c', 1, items, 'soap', 8, item('soap', 'Jabón', 8)),
    record('device-c', 2, categories, 'cat-pets', 39, deletion(39)),
    record('device-c', 3, items, 'soap', 61, deletion(61)),
  ];
}

/// Ids de los items de [shoppingListSyncRecords].
const List<String> shoppingListSyncItemIds = <String>['bread', 'eggs', 'milk', 'milk-2', 'rice', 'soap'];

/// Lo que se ve de la lista de compras a través del repositorio: items
/// activos (con sus categorías ordenadas, que no tienen orden propio),
/// categorías y compras de [itemIds]. Comparable con `==`.
Future<Map<String, Object?>> readShoppingListState(ShoppingListRepository repository, Iterable<String> itemIds) async {
  final List<ShoppingItem> items = (await repository.getItems())
      .map((ShoppingItem item) => item.copyWith(categoryIds: List<String>.of(item.categoryIds)..sort()))
      .toList()
    ..sort((ShoppingItem a, ShoppingItem b) => a.id.compareTo(b.id));
  return <String, Object?>{
    'items': items,
    'categories': await repository.getCategories(),
    for (final String id in itemIds) 'purchases:$id': await repository.getPurchases(id),
  };
}

/// Tests de sincronización de la lista de compras. Todo repositorio que se
/// sincroniza debe pasarlos con su participante.
void shoppingListSyncContract(String implementation, {required ShoppingListSyncFactory create}) {
  group('shopping_list sincronizado ($implementation)', () {
    late ShoppingListSyncSubject subject;
    final Map<ShoppingListSyncParticipant, ShoppingListRepository> repositories =
        <ShoppingListSyncParticipant, ShoppingListRepository>{};

    setUp(() async => subject = await create());

    syncParticipantContract<ShoppingListSyncParticipant>(
      implementation,
      create: () async {
        final ShoppingListSyncSubject created = await create();
        repositories[created.participant] = created.repository;
        return created.participant;
      },
      records: shoppingListSyncRecords(),
      readState: (ShoppingListSyncParticipant participant) =>
          readShoppingListState(repositories[participant]!, shoppingListSyncItemIds),
    );

    test('fusiona por campo y aplica las resoluciones provisionales', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(shoppingListSyncRecords());
      final ShoppingListRepository repository = subject.repository;

      expect((await repository.getItem('milk'))?.name, 'Leche desnatada');
      expect((await repository.getItem('milk'))?.categoryIds, <String>['cat-a-food']);
      expect((await repository.getItem('milk-2'))?.name, 'Leche');
      expect((await repository.getItem('bread'))?.categoryIds, <String>['cat-a-food']);
      expect((await repository.getCategories()).map((ShoppingCategory category) => category.id), <String>['cat-a-food']);
      expect((await repository.getItem('eggs'))?.lastPurchasedAt, _at(30));
      expect(await repository.getPurchases('eggs'), <ShoppingPurchase>[_purchase('p-a', 'eggs', 30)]);
      expect(await repository.getItem('rice'), _item('rice', 'Arroz', 5).copyWith(quantity: '2 kg', updatedAt: _at(36)));
      expect(await repository.getPurchases('rice'), isEmpty);
      expect(await repository.getItem('soap'), isNull);
      expect(conflicts.single.kind, ShoppingListResolver.doublePurchase);
      expect(conflicts.single.entityIds, <String>['eggs', 'p-a', 'p-b']);
    });

    test('las escrituras locales se registran y otro dispositivo las aplica igual', () async {
      final ShoppingListRepository repository = subject.repository;
      final ShoppingItem coffee = _item('coffee', 'Café', 100, categoryIds: <String>['c-2', 'c-1']);
      await repository.seedDefaultCategories(<ShoppingCategory>[
        const ShoppingCategory(id: 'c-1', sortOrder: 0, defaultKey: 'food'),
        const ShoppingCategory(id: 'c-2', sortOrder: 1, name: 'Desayuno'),
      ]);
      await repository.saveItem(coffee);
      await repository.saveItem(_item('tea', 'Té', 100));
      await repository.recordPurchase(coffee.copyWith(lastPurchasedAt: () => _at(101)), _purchase('p-1', 'coffee', 101));
      await repository.recordPurchase(coffee.copyWith(lastPurchasedAt: () => _at(102)), _purchase('p-2', 'coffee', 102));
      await repository.undoPurchase(coffee.copyWith(lastPurchasedAt: () => _at(101)), 'p-2', deletedAt: _at(103));
      await repository.deleteCategory('c-2', updatedAt: _at(104));
      await repository.deleteItems(<String>['tea'], deletedAt: _at(105));
      final ShoppingListSyncSubject other = await create();

      final List<ChangeRecord> records = await subject.log.missingFor(VersionVector.empty);
      final List<SyncConflict> conflicts = await other.participant.applyRemote(records);

      expect(records.map((ChangeRecord record) => record.seq), List<int>.generate(records.length, (int i) => i + 1));
      expect(conflicts, isEmpty);
      expect(await readShoppingListState(other.repository, <String>['coffee', 'tea']),
          await readShoppingListState(repository, <String>['coffee', 'tea']));
    });

    test('lo borrado no vuelve con una escritura normal', () async {
      await subject.participant.applyRemote(shoppingListSyncRecords());

      await subject.repository.saveItem(_item('soap', 'Jabón', 100));
      await subject.repository.saveCategories(<ShoppingCategory>[const ShoppingCategory(id: 'cat-pets', sortOrder: 0, name: 'Gatos')]);

      expect(await subject.repository.getItem('soap'), isNull);
      expect((await subject.repository.getCategories()).map((ShoppingCategory category) => category.id), <String>['cat-a-food']);
    });

    test('contar una sola compra borra la otra y el conflicto desaparece', () async {
      final SyncConflict conflict = (await subject.participant.applyRemote(shoppingListSyncRecords())).single;
      final VersionVector before = await subject.log.vector();

      await subject.participant.resolveConflict(conflict, ShoppingListResolver.oneOption);

      final List<ChangeRecord> recorded = await subject.log.missingFor(before);
      expect(recorded.map((ChangeRecord record) => record.entityId), containsAll(<String>['eggs', 'p-b']));
      expect(await subject.repository.getPurchases('eggs'), <ShoppingPurchase>[_purchase('p-a', 'eggs', 30)]);
      expect(await subject.participant.applyRemote(const <ChangeRecord>[]), isEmpty);
    });

    test('contar las dos compras las muestra y el item toma la más reciente', () async {
      final SyncConflict conflict = (await subject.participant.applyRemote(shoppingListSyncRecords())).single;

      await subject.participant.resolveConflict(conflict, ShoppingListResolver.twoOption);

      expect(await subject.repository.getPurchases('eggs'), <ShoppingPurchase>[
        _purchase('p-b', 'eggs', 32),
        _purchase('p-a', 'eggs', 30),
      ]);
      expect((await subject.repository.getItem('eggs'))?.lastPurchasedAt, _at(32));
      expect(await subject.participant.applyRemote(const <ChangeRecord>[]), isEmpty);
    });

    test('resolver el conflicto de un item que ya no existe no hace nada', () async {
      final SyncConflict conflict = (await subject.participant.applyRemote(shoppingListSyncRecords())).single;
      await subject.repository.deleteItems(<String>['eggs'], deletedAt: _at(200));
      final VersionVector before = await subject.log.vector();

      await subject.participant.resolveConflict(conflict, ShoppingListResolver.twoOption);

      expect(await subject.log.vector(), before);
    });
  });
}

DateTime _at(int offset) => DateTime.fromMillisecondsSinceEpoch(_t0 + offset, isUtc: true);

ShoppingItem _item(String id, String name, int at, {List<String> categoryIds = const <String>[]}) => ShoppingItem(
      id: id,
      name: name,
      urgency: Urgency.normal,
      status: ShoppingItemStatus.pending,
      categoryIds: categoryIds,
      createdAt: _at(at),
      updatedAt: _at(at),
    );

ShoppingPurchase _purchase(String id, String itemId, int at) => ShoppingPurchase(id: id, itemId: itemId, purchasedAt: _at(at));
