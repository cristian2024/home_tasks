import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_isar/src/mappers/shopping_data_mapper.dart';
import 'package:shopping_list_isar/src/models/isar_shopping_item.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 28, 9);

  test('un item con todos los campos va y vuelve sin cambios', () {
    final ShoppingItem item = ShoppingItem(
      id: 'i1',
      name: 'Huevos',
      notes: 'Camperos',
      quantity: '2 docenas',
      urgency: Urgency.high,
      status: ShoppingItemStatus.pending,
      categoryIds: const <String>['c1', 'c2'],
      recurrence: Recurrence.between(8, 15),
      lastPurchasedAt: t0,
      createdAt: t0,
      updatedAt: t0,
    );

    expect(ShoppingDataMapper.fromIsarItem(ShoppingDataMapper.toIsarItem(item)), item);
  });

  test('un item sin recurrencia ni compras va y vuelve sin cambios', () {
    final ShoppingItem item = ShoppingItem(
      id: 'i1',
      name: 'Pan',
      urgency: Urgency.normal,
      status: ShoppingItemStatus.purchased,
      createdAt: t0,
      updatedAt: t0,
    );

    final IsarShoppingItem model = ShoppingDataMapper.toIsarItem(item);

    expect(model.recurrenceMinDays, isNull);
    expect(model.recurrenceMaxDays, isNull);
    expect(ShoppingDataMapper.fromIsarItem(model), item);
  });

  test('una recurrencia incompleta se lee como sin recurrencia', () {
    final ShoppingItem item = ShoppingItem(
      id: 'i1',
      name: 'Pan',
      urgency: Urgency.normal,
      status: ShoppingItemStatus.pending,
      createdAt: t0,
      updatedAt: t0,
    );

    final IsarShoppingItem model = ShoppingDataMapper.toIsarItem(item)..recurrenceMinDays = 3;

    expect(ShoppingDataMapper.fromIsarItem(model).recurrence, isNull);
  });

  test('las fechas guardadas en hora local se leen en UTC', () {
    final ShoppingItem item = ShoppingItem(
      id: 'i1',
      name: 'Pan',
      urgency: Urgency.normal,
      status: ShoppingItemStatus.pending,
      lastPurchasedAt: t0,
      createdAt: t0,
      updatedAt: t0,
    );
    final IsarShoppingItem model = ShoppingDataMapper.toIsarItem(item)
      ..createdAt = t0.toLocal()
      ..updatedAt = t0.toLocal()
      ..lastPurchasedAt = t0.toLocal();

    final ShoppingItem read = ShoppingDataMapper.fromIsarItem(model);

    expect(read.createdAt.isUtc && read.updatedAt.isUtc && read.lastPurchasedAt!.isUtc, isTrue);
    expect(read, item);
  });

  test('categorías y compras van y vuelven sin cambios', () {
    const ShoppingCategory category = ShoppingCategory(id: 'c1', sortOrder: 2, name: 'Comestibles', defaultKey: 'food');
    final ShoppingPurchase purchase = ShoppingPurchase(id: 'p1', itemId: 'i1', purchasedAt: t0);

    expect(ShoppingDataMapper.fromIsarCategory(ShoppingDataMapper.toIsarCategory(category)), category);
    expect(
      ShoppingDataMapper.fromIsarPurchase(ShoppingDataMapper.toIsarPurchase(purchase)..purchasedAt = t0.toLocal()),
      purchase,
    );
  });
}
