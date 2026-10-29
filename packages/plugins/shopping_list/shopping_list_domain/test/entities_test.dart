import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:test/test.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 1, 18);

  ShoppingItem item({
    ShoppingItemStatus status = ShoppingItemStatus.pending,
    Recurrence? recurrence,
    DateTime? lastPurchasedAt,
  }) =>
      ShoppingItem(
        id: 'i1',
        name: 'Huevos',
        urgency: Urgency.normal,
        status: status,
        recurrence: recurrence,
        lastPurchasedAt: lastPurchasedAt,
        createdAt: t0,
        updatedAt: t0,
      );

  group('ShoppingItem.stateAt', () {
    test('un item normal está pendiente o comprado según su estado', () {
      expect(item().stateAt(t0), ShoppingItemState.pending);
      expect(item(status: ShoppingItemStatus.purchased).stateAt(t0), ShoppingItemState.purchased);
      expect(item().isRecurring, isFalse);
    });

    test('un item recurrente sigue su ventana', () {
      final ShoppingItem eggs = item(recurrence: Recurrence.between(8, 15), lastPurchasedAt: t0);

      expect(eggs.isRecurring, isTrue);
      expect(eggs.stateAt(t0.add(const Duration(days: 7))), ShoppingItemState.waiting);
      expect(eggs.stateAt(t0.add(const Duration(days: 8))), ShoppingItemState.pending);
      expect(eggs.stateAt(t0.add(const Duration(days: 16))), ShoppingItemState.overdue);
    });

    test('un item recurrente que nunca se compró está pendiente', () {
      expect(item(recurrence: Recurrence.fixed(7)).stateAt(t0), ShoppingItemState.pending);
    });

    test('isToBuy: atrasado y pendiente', () {
      expect(
        ShoppingItemState.values.where((ShoppingItemState state) => state.isToBuy),
        <ShoppingItemState>[ShoppingItemState.overdue, ShoppingItemState.pending],
      );
    });
  });

  test('ShoppingItem.copyWith cambia solo lo indicado y puede vaciar los opcionales', () {
    final ShoppingItem eggs = item(recurrence: Recurrence.fixed(7), lastPurchasedAt: t0);
    final DateTime t1 = t0.add(const Duration(days: 1));

    final ShoppingItem changed = eggs.copyWith(
      name: 'Huevos camperos',
      notes: 'Del mercado',
      quantity: '1 docena',
      urgency: Urgency.high,
      status: ShoppingItemStatus.purchased,
      categoryIds: <String>['c1'],
      recurrence: () => null,
      lastPurchasedAt: () => null,
      updatedAt: t1,
    );

    expect(
      changed,
      ShoppingItem(
        id: 'i1',
        name: 'Huevos camperos',
        notes: 'Del mercado',
        quantity: '1 docena',
        urgency: Urgency.high,
        status: ShoppingItemStatus.purchased,
        categoryIds: const <String>['c1'],
        createdAt: t0,
        updatedAt: t1,
      ),
    );
    expect(eggs.copyWith(), eggs);
    expect(eggs.toString(), contains('Huevos'));
  });

  group('ShoppingCategory', () {
    test('copyWith conserva la clave por defecto', () {
      const ShoppingCategory food = ShoppingCategory(id: 'c1', sortOrder: 0, defaultKey: 'food');

      expect(
        food.copyWith(name: 'Comestibles', sortOrder: 2),
        const ShoppingCategory(id: 'c1', sortOrder: 2, name: 'Comestibles', defaultKey: 'food'),
      );
      expect(food.copyWith(), food);
      expect(food.toString(), contains('food'));
    });

    test('las categorías por defecto usan su nombre como clave', () {
      expect(DefaultShoppingCategory.values.map((DefaultShoppingCategory category) => category.key),
          <String>['food', 'hygiene', 'cleaning', 'home', 'pharmacy']);
    });
  });

  test('ShoppingPurchase: igualdad por valor', () {
    expect(
      ShoppingPurchase(id: 'p1', itemId: 'i1', purchasedAt: t0),
      ShoppingPurchase(id: 'p1', itemId: 'i1', purchasedAt: t0),
    );
  });
}
