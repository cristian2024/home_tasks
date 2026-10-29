import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';
import 'package:shopping_list_contract/testing.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  shoppingListCapabilitiesContract('ShoppingListApi', create: () {
    final ShoppingListApi api = TestUseCases().api;
    return (query: api, writer: api);
  });

  late TestUseCases uc;
  late ShoppingListApi api;

  setUp(() {
    uc = TestUseCases();
    api = uc.api;
  });

  test('pendingItems incluye los atrasados con sus categorías, y no lo comprado ni lo que espera', () async {
    final ShoppingCategory food = await uc.createCategory('Comida');
    final ShoppingItem eggs = await uc.createItem(
      name: 'Huevos',
      quantity: '2 docenas',
      categoryIds: <String>[food.id],
      recurrence: Recurrence.between(8, 15),
    );
    final ShoppingItem milk = await uc.createItem(name: 'Leche', recurrence: Recurrence.fixed(7));
    final ShoppingItem bread = await uc.createItem(name: 'Pan');
    await uc.markPurchased(eggs.id);
    await uc.markPurchased(bread.id);
    uc.clock.advance(const Duration(days: 20));
    await uc.markPurchased(milk.id);

    expect(await api.pendingItems(), <ShoppingItemSummary>[
      ShoppingItemSummary(
        id: eggs.id,
        name: 'Huevos',
        urgency: Urgency.normal,
        quantity: '2 docenas',
        categoryNames: const <String>['Comida'],
        isOverdue: true,
      ),
    ]);
  });

  test('watchPendingItems emite los pendientes', () async {
    await uc.createItem(name: 'Pan');

    expect((await api.watchPendingItems().first).single.name, 'Pan');
  });

  test('addItem reutiliza un item comprado con el mismo nombre y lo vuelve a pendiente', () async {
    final ShoppingItem bread = await uc.createItem(name: 'Pan');
    await uc.markPurchased(bread.id);

    expect(await api.addItem(ShoppingItemRequest(name: 'pan', urgency: Urgency.high)), bread.id);

    final ShoppingItem pending = (await uc.repository.getItem(bread.id))!;
    expect(pending.status, ShoppingItemStatus.pending);
    expect(pending.urgency, Urgency.high);
  });

  test('addItem crea uno nuevo si el del mismo nombre es recurrente y aún espera', () async {
    final ShoppingItem eggs = await uc.createItem(name: 'Huevos', recurrence: Recurrence.fixed(7));
    await uc.markPurchased(eggs.id);

    final String id = await api.addItem(ShoppingItemRequest(name: 'Huevos', quantity: '6', notes: 'ya'));

    expect(id, isNot(eggs.id));
    final ShoppingItem created = (await uc.repository.getItem(id))!;
    expect((created.quantity, created.notes), ('6', 'ya'));
  });
}
