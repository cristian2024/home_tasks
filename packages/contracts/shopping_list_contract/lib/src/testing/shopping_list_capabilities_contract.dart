import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

import '../shopping_item_request.dart';
import '../shopping_item_summary.dart';
import '../shopping_list_query.dart';
import '../shopping_list_writer.dart';

/// Las dos capacidades de una misma lista, para [shoppingListCapabilitiesContract].
typedef ShoppingListCapabilities = ({ShoppingListQuery query, ShoppingListWriter writer});

/// Tests de contrato de [ShoppingListQuery] y [ShoppingListWriter]. Toda
/// implementación (la de la lista de compras o un doble de prueba) debe
/// pasarlos. [create] devuelve una lista vacía para cada test y [dispose] la
/// libera.
void shoppingListCapabilitiesContract(
  String implementation, {
  required FutureOr<ShoppingListCapabilities> Function() create,
  FutureOr<void> Function()? dispose,
}) {
  group('ShoppingListQuery y ShoppingListWriter ($implementation)', () {
    late ShoppingListQuery query;
    late ShoppingListWriter writer;

    setUp(() async {
      final ShoppingListCapabilities capabilities = await create();
      query = capabilities.query;
      writer = capabilities.writer;
    });
    tearDown(() async => dispose?.call());

    List<String> names(List<ShoppingItemSummary> items) =>
        <String>[for (final ShoppingItemSummary item in items) item.name];

    test('una lista vacía no tiene pendientes', () async {
      expect(await query.pendingItems(), isEmpty);
    });

    test('addItem añade un pendiente con lo pedido y devuelve su ID', () async {
      final String id = await writer.addItem(
        ShoppingItemRequest(name: 'Huevos', quantity: '2 docenas', urgency: Urgency.high),
      );

      final ShoppingItemSummary item = (await query.pendingItems()).single;
      expect(item.id, id);
      expect(item.name, 'Huevos');
      expect(item.quantity, '2 docenas');
      expect(item.urgency, Urgency.high);
      expect(item.isOverdue, isFalse);
    });

    test('pendingItems pone primero lo más urgente y, a igual urgencia, ordena por nombre', () async {
      await writer.addItem(ShoppingItemRequest(name: 'pan'));
      await writer.addItem(ShoppingItemRequest(name: 'Leche', urgency: Urgency.low));
      await writer.addItem(ShoppingItemRequest(name: 'Arroz'));
      await writer.addItem(ShoppingItemRequest(name: 'Jabón', urgency: Urgency.immediate));

      expect(names(await query.pendingItems()), <String>['Jabón', 'Arroz', 'pan', 'Leche']);
    });

    test('addItem no duplica un pendiente con el mismo nombre y le sube la urgencia', () async {
      final String id = await writer.addItem(ShoppingItemRequest(name: 'Huevos'));

      expect(await writer.addItem(ShoppingItemRequest(name: '  huevos ', urgency: Urgency.immediate)), id);
      expect(await writer.addItem(ShoppingItemRequest(name: 'HUEVOS', urgency: Urgency.low)), id);

      final ShoppingItemSummary item = (await query.pendingItems()).single;
      expect(item.name, 'Huevos');
      expect(item.urgency, Urgency.immediate);
    });

    test('watchPendingItems emite al suscribirse y con cada cambio', () async {
      final StreamQueue<List<ShoppingItemSummary>> queue =
          StreamQueue<List<ShoppingItemSummary>>(query.watchPendingItems());
      addTearDown(queue.cancel);

      expect(await queue.next, isEmpty);
      await writer.addItem(ShoppingItemRequest(name: 'Pan'));
      await expectLater(queue, emitsThrough(predicate<List<ShoppingItemSummary>>(
        (List<ShoppingItemSummary> items) => names(items).join(',') == 'Pan',
      )));
    });
  });
}
