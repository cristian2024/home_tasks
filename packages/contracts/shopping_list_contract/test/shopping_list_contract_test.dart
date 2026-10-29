import 'package:core_events/core_events.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';
import 'package:shopping_list_contract/testing.dart';
import 'package:test/test.dart';

void main() {
  shoppingListCapabilitiesContract('InMemoryShoppingList', create: () {
    final InMemoryShoppingList list = InMemoryShoppingList();
    return (query: list, writer: list);
  });

  group('ShoppingItemRequest', () {
    test('recorta el nombre y usa urgencia normal por defecto', () {
      final ShoppingItemRequest request = ShoppingItemRequest(name: '  Huevos ');

      expect(request.name, 'Huevos');
      expect(request.urgency, Urgency.normal);
      expect(request, ShoppingItemRequest(name: 'Huevos'));
    });

    test('rechaza un nombre vacío o demasiado largo', () {
      expect(() => ShoppingItemRequest(name: '  '), throwsArgumentError);
      expect(() => ShoppingItemRequest(name: 'a' * 121), throwsArgumentError);
      expect(ShoppingItemRequest(name: 'a' * 120).name, hasLength(120));
    });

    test('normalizeName ignora mayúsculas y espacios de sobra', () {
      expect(ShoppingItemRequest.normalizeName('  Papel   Higiénico '), 'papel higiénico');
    });
  });

  test('ShoppingItemPurchased usa la fecha de compra como emittedAt', () {
    final DateTime at = DateTime.utc(2026, 10, 28, 10);
    final ShoppingItemPurchased event = ShoppingItemPurchased(itemId: '1', itemName: 'Huevos', purchasedAt: at);

    expect(event, isA<CrossPluginEvent>());
    expect(event.purchasedAt, at);
    expect(event.emittedAt, at);
  });

  test('ShoppingItemSummary: igualdad por valor', () {
    ShoppingItemSummary summary(Urgency urgency) =>
        ShoppingItemSummary(id: '1', name: 'Huevos', urgency: urgency, categoryNames: const <String>['Comida']);

    expect(summary(Urgency.high), summary(Urgency.high));
    expect(summary(Urgency.high), isNot(summary(Urgency.low)));
  });

  test('InMemoryShoppingList.remove quita el item y avisa', () async {
    final InMemoryShoppingList list = InMemoryShoppingList();
    final String id = await list.addItem(ShoppingItemRequest(name: 'Pan'));
    final Future<List<ShoppingItemSummary>> afterRemove = list.watchPendingItems().skip(1).first;

    list.remove(id);

    expect(await afterRemove, isEmpty);
    expect(await list.pendingItems(), isEmpty);
  });
}
