import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases uc;

  setUp(() => uc = TestUseCases());

  group('CreateShoppingItem', () {
    test('crea un item pendiente con los textos recortados', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');

      final ShoppingItem item = await uc.createItem(
        name: ' Huevos ',
        notes: ' camperos ',
        quantity: ' 2 docenas ',
        urgency: Urgency.high,
        categoryIds: <String>[food.id, food.id],
        recurrence: Recurrence.between(8, 15),
      );

      expect(
        item,
        ShoppingItem(
          id: item.id,
          name: 'Huevos',
          notes: 'camperos',
          quantity: '2 docenas',
          urgency: Urgency.high,
          status: ShoppingItemStatus.pending,
          categoryIds: <String>[food.id],
          recurrence: Recurrence.between(8, 15),
          createdAt: t0,
          updatedAt: t0,
        ),
      );
      expect(await uc.repository.getItem(item.id), item);
    });

    test('rechaza un nombre vacío y categorías que no existen', () async {
      await expectLater(uc.createItem(name: ' '), throwsA(isA<ShoppingValidationException>()));
      await expectLater(
        uc.createItem(name: 'Pan', categoryIds: <String>['nada']),
        throwsA(isA<ShoppingCategoryNotFoundException>()),
      );
      expect(await uc.repository.getItems(), isEmpty);
    });
  });

  group('UpdateShoppingItem', () {
    test('cambia lo indicado y actualiza updatedAt', () async {
      final ShoppingCategory food = await uc.createCategory('Comida');
      final ShoppingItem item = await uc.createItem(name: 'Huevos', recurrence: Recurrence.fixed(7));
      uc.clock.advance(const Duration(hours: 1));

      final ShoppingItem updated = await uc.updateItem(
        item.id,
        name: 'Huevos camperos',
        notes: 'del mercado',
        quantity: '1 docena',
        urgency: Urgency.low,
        categoryIds: <String>[food.id],
        recurrence: () => null,
      );

      expect(updated.name, 'Huevos camperos');
      expect(updated.notes, 'del mercado');
      expect(updated.quantity, '1 docena');
      expect(updated.urgency, Urgency.low);
      expect(updated.categoryIds, <String>[food.id]);
      expect(updated.recurrence, isNull);
      expect(updated.updatedAt, t0.add(const Duration(hours: 1)));
      expect(await uc.repository.getItem(item.id), updated);
    });

    test('si nada cambia no escribe', () async {
      final ShoppingItem item = await uc.createItem(name: 'Huevos');
      uc.clock.advance(const Duration(hours: 1));

      expect(await uc.updateItem(item.id, name: ' Huevos '), item);
      expect((await uc.repository.getItem(item.id))!.updatedAt, t0);
    });

    test('un item que no existe lanza ShoppingItemNotFoundException', () async {
      await expectLater(uc.updateItem('nada', name: 'x'), throwsA(isA<ShoppingItemNotFoundException>()));
      await expectLater(uc.getItem('nada'), throwsA(isA<ShoppingItemNotFoundException>()));
    });
  });

  test('GetShoppingItem y DeleteShoppingItems', () async {
    final ShoppingItem item = await uc.createItem(name: 'Pan');

    expect(await uc.getItem(item.id), item);
    await uc.deleteItems(<String>[item.id]);
    expect(await uc.repository.getItems(), isEmpty);
  });
}
