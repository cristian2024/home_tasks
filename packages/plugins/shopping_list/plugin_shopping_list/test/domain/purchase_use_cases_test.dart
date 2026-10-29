import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases uc;

  setUp(() => uc = TestUseCases());

  group('MarkShoppingItemPurchased', () {
    test('un item normal pasa a comprado, guarda la compra y publica el evento', () async {
      final ShoppingItem item = await uc.createItem(name: 'Pan');
      uc.clock.advance(const Duration(hours: 2));
      final DateTime now = t0.add(const Duration(hours: 2));

      final ShoppingPurchaseReceipt? receipt = await uc.markPurchased(item.id);

      final ShoppingItem bought = (await uc.repository.getItem(item.id))!;
      expect(bought.status, ShoppingItemStatus.purchased);
      expect(bought.lastPurchasedAt, now);
      expect(bought.updatedAt, now);
      expect(receipt, ShoppingPurchaseReceipt(previous: item, purchaseId: receipt!.purchaseId));
      expect(await uc.repository.getPurchases(item.id), <ShoppingPurchase>[
        ShoppingPurchase(id: receipt.purchaseId, itemId: item.id, purchasedAt: now),
      ]);
      final ShoppingItemPurchased event = uc.eventBus.publishedOf<ShoppingItemPurchased>().single;
      expect((event.itemId, event.itemName, event.purchasedAt), (item.id, 'Pan', now));
    });

    test('un item recurrente sigue pendiente y espera a su ventana', () async {
      final ShoppingItem item = await uc.createItem(name: 'Huevos', recurrence: Recurrence.between(8, 15));

      await uc.markPurchased(item.id);

      final ShoppingItem bought = (await uc.repository.getItem(item.id))!;
      expect(bought.status, ShoppingItemStatus.pending);
      expect(bought.stateAt(t0), ShoppingItemState.waiting);
      expect(bought.stateAt(t0.add(const Duration(days: 8))), ShoppingItemState.pending);
    });

    test('un item ya comprado no se vuelve a comprar', () async {
      final ShoppingItem item = await uc.createItem(name: 'Pan');
      await uc.markPurchased(item.id);

      expect(await uc.markPurchased(item.id), isNull);
      expect(await uc.repository.getPurchases(item.id), hasLength(1));
      expect(uc.eventBus.published, hasLength(1));
    });

    test('un item que no existe lanza ShoppingItemNotFoundException', () async {
      await expectLater(uc.markPurchased('nada'), throwsA(isA<ShoppingItemNotFoundException>()));
    });
  });

  test('UndoShoppingPurchase restaura el item y borra la compra', () async {
    final ShoppingItem item = await uc.createItem(name: 'Pan');
    final ShoppingPurchaseReceipt receipt = (await uc.markPurchased(item.id))!;
    uc.clock.advance(const Duration(minutes: 1));

    await uc.undoPurchase(receipt);

    expect(await uc.repository.getItem(item.id), item.copyWith(updatedAt: t0.add(const Duration(minutes: 1))));
    expect(await uc.repository.getPurchases(item.id), isEmpty);
  });

  group('MarkShoppingItemPending', () {
    test('vuelve a pendiente un item comprado y puede cambiar su urgencia', () async {
      final ShoppingItem item = await uc.createItem(name: 'Pan');
      await uc.markPurchased(item.id);

      await uc.markPending(item.id, urgency: Urgency.immediate);

      final ShoppingItem pending = (await uc.repository.getItem(item.id))!;
      expect(pending.status, ShoppingItemStatus.pending);
      expect(pending.urgency, Urgency.immediate);
      expect(await uc.repository.getPurchases(item.id), hasLength(1));
    });

    test('un item ya pendiente con la misma urgencia no se escribe', () async {
      final ShoppingItem item = await uc.createItem(name: 'Pan');
      uc.clock.advance(const Duration(hours: 1));

      await uc.markPending(item.id);
      await uc.markPending(item.id, urgency: Urgency.normal);

      expect(await uc.repository.getItem(item.id), item);
    });

    test('un item que no existe lanza ShoppingItemNotFoundException', () async {
      await expectLater(uc.markPending('nada'), throwsA(isA<ShoppingItemNotFoundException>()));
    });
  });

  test('ClearPurchasedShoppingItems borra solo los comprados', () async {
    final ShoppingItem bread = await uc.createItem(name: 'Pan');
    final ShoppingItem eggs = await uc.createItem(name: 'Huevos', recurrence: Recurrence.fixed(7));
    final ShoppingItem milk = await uc.createItem(name: 'Leche');
    await uc.markPurchased(bread.id);
    await uc.markPurchased(eggs.id);

    expect(await uc.clearPurchased(), 1);
    expect(await uc.clearPurchased(), 0);
    expect(<String>{for (final ShoppingItem item in await uc.repository.getItems()) item.id}, <String>{
      eggs.id,
      milk.id,
    });
  });
}
