import 'package:core_sync/core_sync.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:test/test.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 30);

Hlc _hlc(int at, {String device = 'a'}) => Hlc(wallTime: _t0.millisecondsSinceEpoch + at, counter: 0, deviceId: device);

SyncedEntity _entity(String collection, String id, Map<String, Object?> fields, Hlc hlc) =>
    SyncedEntity(collection: collection, id: id).apply(FieldDiff.between(null, fields), hlc);

SyncedEntity _item({Recurrence? recurrence}) => _entity(
      ShoppingListCollections.items,
      'eggs',
      ShoppingListCodec.itemFields(ShoppingItem(
        id: 'eggs',
        name: 'Huevos',
        urgency: Urgency.normal,
        status: ShoppingItemStatus.pending,
        recurrence: recurrence,
        createdAt: _t0,
        updatedAt: _t0,
      )),
      _hlc(1),
    );

SyncedEntity _purchase(String id, {required int days, required Hlc hlc}) => _entity(
      ShoppingListCollections.purchases,
      id,
      ShoppingListCodec.purchaseFields(
        ShoppingPurchase(id: id, itemId: 'eggs', purchasedAt: _t0.add(Duration(days: days))),
        previousPurchase: null,
      ),
      hlc,
    );

void main() {
  group('ShoppingListCodec', () {
    test('un item con su recurrencia ida y vuelta', () {
      final ShoppingItem? item = ShoppingListCodec.itemOf(_item(recurrence: Recurrence.between(8, 15)));

      expect(item?.recurrence, Recurrence.between(8, 15));
      expect(item?.lastPurchasedAt, isNull);
    });

    test('una recurrencia inválida se lee como ninguna', () {
      for (final Object? recurrence in <Object?>[
        <String, Object?>{'minDays': 9, 'maxDays': 2},
        <String, Object?>{'minDays': 'x', 'maxDays': 2},
        'x',
      ]) {
        final SyncedEntity entity = _item().apply(<FieldChange>[ValueChange('recurrence', recurrence)], _hlc(2));

        expect(ShoppingListCodec.itemOf(entity)?.recurrence, isNull);
      }
    });

    test('las entidades incompletas no se leen', () {
      expect(ShoppingListCodec.itemOf(SyncedEntity(collection: ShoppingListCollections.items, id: 'x')), isNull);
      expect(
        ShoppingListCodec.categoryOf(_entity(ShoppingListCollections.categories, 'c', <String, Object?>{'sortOrder': 1}, _hlc(1))),
        isNull,
      );
      expect(ShoppingListCodec.purchaseOf(SyncedEntity(collection: ShoppingListCollections.purchases, id: 'p')), isNull);
    });
  });

  group('ShoppingListResolver', () {
    const ShoppingListResolver resolver = ShoppingListResolver();

    test('en un item que se repite, dos compras a más de minDays días no son dobles', () {
      final ShoppingSyncView view = resolver.resolve(
        <SyncedEntity>[_item(recurrence: Recurrence.between(8, 15))],
        const <SyncedEntity>[],
        <SyncedEntity>[_purchase('p-1', days: 0, hlc: _hlc(10)), _purchase('p-2', days: 9, hlc: _hlc(11, device: 'b'))],
      );

      expect(view.conflicts, isEmpty);
      expect(view.purchases.values.where((ShoppingResolved<ShoppingPurchase> p) => p.isDeleted), isEmpty);
    });

    test('en un item que se repite, dos compras dentro de su ventana son dobles', () {
      final ShoppingSyncView view = resolver.resolve(
        <SyncedEntity>[_item(recurrence: Recurrence.between(8, 15))],
        const <SyncedEntity>[],
        <SyncedEntity>[_purchase('p-1', days: 0, hlc: _hlc(10)), _purchase('p-2', days: 1, hlc: _hlc(11, device: 'b'))],
      );

      expect(view.conflicts.single.entityIds, <String>['eggs', 'p-1', 'p-2']);
      expect(view.purchases['p-2']?.isDeleted, isTrue);
    });

    test('con la misma marca cuenta la de id menor', () {
      final ShoppingSyncView view = resolver.resolve(
        <SyncedEntity>[_item()],
        const <SyncedEntity>[],
        <SyncedEntity>[_purchase('p-2', days: 0, hlc: _hlc(10)), _purchase('p-1', days: 0, hlc: _hlc(10))],
      );

      expect(view.conflicts.single.entityIds, <String>['eggs', 'p-1', 'p-2']);
    });

    test('una compra sin metadatos va antes que las demás', () {
      final SyncedEntity bare = SyncedEntity(
        collection: ShoppingListCollections.purchases,
        id: 'p-9',
        fields: _purchase('p-9', days: 0, hlc: _hlc(1)).fields,
      );

      final ShoppingSyncView view = resolver.resolve(
        <SyncedEntity>[_item()],
        const <SyncedEntity>[],
        <SyncedEntity>[_purchase('p-1', days: 0, hlc: _hlc(10)), bare],
      );

      expect(view.conflicts.single.entityIds, <String>['eggs', 'p-9', 'p-1']);
      expect(view.conflicts.single.detectedAt, _t0.add(const Duration(milliseconds: 10)));
    });

    test('la vista y el commit se comparan por valor', () {
      final ShoppingSyncView view = resolver.resolve(<SyncedEntity>[_item()], const <SyncedEntity>[], const <SyncedEntity>[]);

      expect(view, resolver.resolve(<SyncedEntity>[_item()], const <SyncedEntity>[], const <SyncedEntity>[]));
      expect(ShoppingListSyncCommit().isEmpty, isTrue);
      expect(ShoppingListSyncCommit(entities: const <SyncedEntity>[]), ShoppingListSyncCommit());
    });
  });
}
