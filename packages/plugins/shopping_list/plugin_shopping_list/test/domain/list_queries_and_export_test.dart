import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:list_export/list_export.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases uc;

  setUp(() => uc = TestUseCases());

  group('WatchShoppingList', () {
    test('emite items y categorías juntos, y vuelve a emitir con cada cambio', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');
      final StreamQueue<ShoppingListSnapshot> queue = StreamQueue<ShoppingListSnapshot>(uc.watchList());
      addTearDown(queue.cancel);

      final ShoppingListSnapshot first = await queue.next;
      expect(first.categories, <ShoppingCategory>[food]);
      expect(first.entries, isEmpty);

      await uc.createItem(name: 'Huevos', categoryIds: <String>[food.id]);
      await expectLater(
        queue,
        emitsThrough(predicate<ShoppingListSnapshot>((ShoppingListSnapshot snapshot) =>
            snapshot.entries.length == 1 && snapshot.entries.single.primaryCategory == food)),
      );
    });

    test('ShoppingListSnapshot: igualdad por valor', () async {
      await uc.createItem(name: 'Pan');

      expect(await uc.watchList().first, await uc.watchList().first);
    });

    test('toBuy son los pendientes y atrasados', () async {
      final ShoppingItem bread = await uc.createItem(name: 'Pan');
      await uc.createItem(name: 'Leche');
      await uc.markPurchased(bread.id);

      final ShoppingListSnapshot snapshot = await uc.watchList().first;

      expect(snapshot.toBuy.map((ShoppingListEntry entry) => entry.item.name), <String>['Leche']);
    });

    test('reenvía los errores del repositorio', () async {
      final StreamController<List<ShoppingItem>> items = StreamController<List<ShoppingItem>>();
      final WatchShoppingList watch = WatchShoppingList(_FailingRepository(items.stream), uc.clock);
      final Future<Object?> error = watch().first.then<Object?>((_) => null, onError: (Object error) => error);

      items.addError(StateError('falló'));

      expect(await error, isA<StateError>());
      await items.close();
    });
  });

  test('WatchShoppingCategories emite las categorías', () async {
    final ShoppingCategory food = await uc.createCategory('Comida');

    expect(await uc.watchCategories().first, <ShoppingCategory>[food]);
  });

  group('BuildShoppingExport', () {
    final ShoppingExportTexts texts = ShoppingExportTexts(
      title: 'Compras',
      uncategorized: 'Sin categoría',
      urgency: (Urgency urgency) => urgency.name,
      categoryName: testCategoryName,
      footer: 'hoy',
    );

    Future<List<ShoppingListEntry>> entries() async => (await uc.watchList().first).entries;

    test('por categoría: solo lo que hay que comprar, una vez y con las demás categorías aparte', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');
      final ShoppingCategory home = await uc.createCategory('Hogar');
      await uc.createItem(name: 'Huevos', quantity: '2 docenas', urgency: Urgency.high, categoryIds: <String>[food.id]);
      await uc.createItem(name: 'Jabón', categoryIds: <String>[home.id, food.id]);
      await uc.createItem(name: 'Pilas');
      final ShoppingItem bread = await uc.createItem(name: 'Pan', categoryIds: <String>[food.id]);
      await uc.markPurchased(bread.id);

      expect(
        const BuildShoppingExport()(await entries(), ShoppingGrouping.category, texts),
        const ExportDocument(
          title: 'Compras',
          footer: 'hoy',
          sections: <ExportSection>[
            ExportSection(heading: 'Comida', entries: <ExportEntry>[
              ExportEntry(text: 'Huevos', detail: '2 docenas', emphasized: true),
              ExportEntry(text: 'Jabón', detail: '(Hogar)'),
            ]),
            ExportSection(heading: 'Sin categoría', entries: <ExportEntry>[ExportEntry(text: 'Pilas')]),
          ],
        ),
      );
    });

    test('por urgencia: las categorías van en el detalle', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');
      await uc.createItem(name: 'Huevos', urgency: Urgency.immediate, categoryIds: <String>[food.id]);
      await uc.createItem(name: 'Pilas', quantity: 'AA', urgency: Urgency.low);

      expect(
        const BuildShoppingExport()(await entries(), ShoppingGrouping.urgency, texts).sections,
        const <ExportSection>[
          ExportSection(heading: 'immediate', entries: <ExportEntry>[
            ExportEntry(text: 'Huevos', detail: '(Comida)', emphasized: true),
          ]),
          ExportSection(heading: 'low', entries: <ExportEntry>[ExportEntry(text: 'Pilas', detail: 'AA')]),
        ],
      );
    });
  });
}

/// Repositorio cuyo stream de items lo controla el test.
class _FailingRepository implements ShoppingListRepository {
  _FailingRepository(this._items);

  final Stream<List<ShoppingItem>> _items;

  @override
  Stream<List<ShoppingItem>> watchItems() => _items;

  @override
  Stream<List<ShoppingCategory>> watchCategories() => Stream<List<ShoppingCategory>>.value(<ShoppingCategory>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
