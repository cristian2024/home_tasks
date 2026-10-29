import 'dart:async';

import 'package:async/async.dart';
import 'package:recurrence/recurrence.dart';
import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';
import '../repositories/shopping_list_repository.dart';

/// Tests de contrato de [ShoppingListRepository]. Toda implementación (en
/// memoria o de cualquier motor de base de datos) debe pasarlos.
///
/// [create] devuelve un repositorio vacío para cada test y [dispose] lo
/// libera.
///
/// ```dart
/// shoppingListRepositoryContract('Isar', create: () => ..., dispose: (_) => ...);
/// ```
void shoppingListRepositoryContract(
  String implementation, {
  required FutureOr<ShoppingListRepository> Function() create,
  FutureOr<void> Function(ShoppingListRepository repository)? dispose,
}) {
  group('ShoppingListRepository ($implementation)', () {
    late ShoppingListRepository repository;

    final DateTime t0 = DateTime.utc(2026, 10, 28, 9);
    final DateTime t1 = DateTime.utc(2026, 10, 29, 9);

    ShoppingItem item(
      String id, {
      String name = 'Huevos',
      List<String> categoryIds = const <String>[],
      ShoppingItemStatus status = ShoppingItemStatus.pending,
      DateTime? updatedAt,
    }) =>
        ShoppingItem(
          id: id,
          name: name,
          notes: 'Camperos',
          quantity: '2 docenas',
          urgency: Urgency.high,
          status: status,
          categoryIds: categoryIds,
          recurrence: Recurrence.between(8, 15),
          lastPurchasedAt: t0,
          createdAt: t0,
          updatedAt: updatedAt ?? t0,
        );

    ShoppingCategory category(String id, int sortOrder, {String? name, String? defaultKey}) =>
        ShoppingCategory(
          id: id,
          sortOrder: sortOrder,
          name: name ?? (defaultKey == null ? id : null),
          defaultKey: defaultKey,
        );

    ShoppingPurchase purchase(String id, DateTime at, {String itemId = 'i1'}) =>
        ShoppingPurchase(id: id, itemId: itemId, purchasedAt: at);

    Set<String> ids(List<ShoppingItem> items) => <String>{for (final ShoppingItem item in items) item.id};

    setUp(() async => repository = await create());
    tearDown(() async => dispose?.call(repository));

    group('items', () {
      test('saveItem guarda todos los campos y getItem los devuelve', () async {
        await repository.saveItem(item('i1', categoryIds: <String>['c1', 'c2']));

        expect(await repository.getItem('i1'), item('i1', categoryIds: <String>['c1', 'c2']));
        expect(await repository.getItem('nada'), isNull);
      });

      test('guarda un item sin recurrencia, sin compras y con textos vacíos', () async {
        final ShoppingItem plain = ShoppingItem(
          id: 'i1',
          name: 'Pan',
          urgency: Urgency.normal,
          status: ShoppingItemStatus.purchased,
          createdAt: t0,
          updatedAt: t1,
        );

        await repository.saveItem(plain);

        expect(await repository.getItem('i1'), plain);
      });

      test('saveItem reemplaza el item con el mismo ID', () async {
        await repository.saveItem(item('i1'));
        await repository.saveItem(item('i1', name: 'Huevos camperos', updatedAt: t1));

        expect((await repository.getItem('i1'))!.name, 'Huevos camperos');
        expect(await repository.getItems(), hasLength(1));
      });

      test('las fechas se devuelven en UTC', () async {
        await repository.saveItem(item('i1'));

        final ShoppingItem saved = (await repository.getItem('i1'))!;
        expect(saved.createdAt.isUtc && saved.updatedAt.isUtc && saved.lastPurchasedAt!.isUtc, isTrue);
      });

      test('watchItems emite al suscribirse y con cada cambio', () async {
        await repository.saveItem(item('i1'));
        final StreamQueue<List<ShoppingItem>> queue = StreamQueue<List<ShoppingItem>>(repository.watchItems());
        addTearDown(queue.cancel);

        expect(ids(await queue.next), <String>{'i1'});
        await repository.saveItem(item('i2'));
        await expectLater(
          queue,
          emitsThrough(predicate<List<ShoppingItem>>((List<ShoppingItem> items) => items.length == 2)),
        );
        await repository.deleteItems(<String>['i1']);
        await expectLater(
          queue,
          emitsThrough(predicate<List<ShoppingItem>>((List<ShoppingItem> items) => ids(items).join() == 'i2')),
        );
      });

      test('deleteItems borra los items y su historial, e ignora los que no existen', () async {
        await repository.saveItem(item('i1'));
        await repository.saveItem(item('i2'));
        await repository.recordPurchase(item('i1'), purchase('p1', t0));

        await repository.deleteItems(<String>['i1', 'nada']);

        expect(ids(await repository.getItems()), <String>{'i2'});
        expect(await repository.getPurchases('i1'), isEmpty);
      });
    });

    group('categorías', () {
      test('saveCategories guarda y getCategories las devuelve por sortOrder', () async {
        await repository.saveCategories(<ShoppingCategory>[
          category('c2', 1, name: 'Hogar'),
          category('c1', 0, defaultKey: 'food'),
        ]);

        expect(await repository.getCategories(), <ShoppingCategory>[
          category('c1', 0, defaultKey: 'food'),
          category('c2', 1, name: 'Hogar'),
        ]);
      });

      test('saveCategories reemplaza las que tienen el mismo ID (reordenar, renombrar)', () async {
        await repository.saveCategories(<ShoppingCategory>[category('c1', 0), category('c2', 1)]);

        await repository.saveCategories(<ShoppingCategory>[
          category('c1', 1, name: 'Comida'),
          category('c2', 0),
        ]);

        expect(await repository.getCategories(), <ShoppingCategory>[
          category('c2', 0),
          category('c1', 1, name: 'Comida'),
        ]);
      });

      test('watchCategories emite al suscribirse y con cada cambio', () async {
        final StreamQueue<List<ShoppingCategory>> queue =
            StreamQueue<List<ShoppingCategory>>(repository.watchCategories());
        addTearDown(queue.cancel);

        expect(await queue.next, isEmpty);
        await repository.saveCategories(<ShoppingCategory>[category('c1', 0)]);
        await expectLater(queue, emitsThrough(<ShoppingCategory>[category('c1', 0)]));
      });

      test('deleteCategory la borra y la quita de los items que la tienen', () async {
        await repository.saveCategories(<ShoppingCategory>[category('c1', 0), category('c2', 1)]);
        await repository.saveItem(item('i1', categoryIds: <String>['c1', 'c2']));
        await repository.saveItem(item('i2', categoryIds: <String>['c1']));
        await repository.saveItem(item('i3', categoryIds: <String>['c2']));

        await repository.deleteCategory('c1', updatedAt: t1);

        expect(await repository.getCategories(), <ShoppingCategory>[category('c2', 1)]);
        expect(await repository.getItem('i1'), item('i1', categoryIds: <String>['c2'], updatedAt: t1));
        expect(await repository.getItem('i2'), item('i2', updatedAt: t1));
        expect(await repository.getItem('i3'), item('i3', categoryIds: <String>['c2']));
      });

      test('deleteCategory de una categoría que no existe no hace nada', () async {
        await repository.saveItem(item('i1', categoryIds: <String>['c1']));

        await repository.deleteCategory('nada', updatedAt: t1);

        expect(await repository.getItem('i1'), item('i1', categoryIds: <String>['c1']));
      });

      test('seedDefaultCategories solo crea las categorías la primera vez', () async {
        final List<ShoppingCategory> defaults = <ShoppingCategory>[category('c1', 0, defaultKey: 'food')];

        expect(await repository.seedDefaultCategories(defaults), isTrue);
        await repository.deleteCategory('c1', updatedAt: t1);

        expect(await repository.seedDefaultCategories(defaults), isFalse);
        expect(await repository.getCategories(), isEmpty);
      });
    });

    group('compras', () {
      test('recordPurchase guarda el item actualizado y la compra', () async {
        await repository.saveItem(item('i1'));
        final ShoppingItem bought = item('i1', status: ShoppingItemStatus.purchased, updatedAt: t1);

        await repository.recordPurchase(bought, purchase('p1', t1));

        expect(await repository.getItem('i1'), bought);
        expect(await repository.getPurchases('i1'), <ShoppingPurchase>[purchase('p1', t1)]);
      });

      test('getPurchases devuelve las del item, de la más reciente a la más antigua', () async {
        await repository.saveItem(item('i1'));
        await repository.saveItem(item('i2'));
        await repository.recordPurchase(item('i1'), purchase('p1', t0));
        await repository.recordPurchase(item('i1'), purchase('p2', t1));
        await repository.recordPurchase(item('i2'), purchase('p3', t1, itemId: 'i2'));

        expect(await repository.getPurchases('i1'), <ShoppingPurchase>[purchase('p2', t1), purchase('p1', t0)]);
        expect((await repository.getPurchases('i1')).first.purchasedAt.isUtc, isTrue);
      });

      test('undoPurchase restaura el item y borra solo esa compra', () async {
        await repository.saveItem(item('i1'));
        await repository.recordPurchase(item('i1'), purchase('p1', t0));
        await repository.recordPurchase(item('i1', status: ShoppingItemStatus.purchased), purchase('p2', t1));

        await repository.undoPurchase(item('i1', updatedAt: t1), 'p2');

        expect(await repository.getItem('i1'), item('i1', updatedAt: t1));
        expect(await repository.getPurchases('i1'), <ShoppingPurchase>[purchase('p1', t0)]);
      });
    });
  });
}
