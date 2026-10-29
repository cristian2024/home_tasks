/// Doble de prueba y tests de contrato de `shopping_list_contract`, para los
/// plugins que usan la lista de compras.
library;

import 'dart:async';

import 'shopping_list_contract.dart';

export 'src/testing/shopping_list_capabilities_contract.dart';

/// Lista de compras en memoria que implementa sus dos capacidades. Cumple
/// `shoppingListCapabilitiesContract`.
class InMemoryShoppingList implements ShoppingListQuery, ShoppingListWriter {
  final Map<String, ShoppingItemSummary> _items = <String, ShoppingItemSummary>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  int _nextId = 1;

  /// Quita el item [id], como si se hubiera comprado o borrado.
  void remove(String id) {
    _items.remove(id);
    _changes.add(null);
  }

  @override
  Future<String> addItem(ShoppingItemRequest request) async {
    final String key = ShoppingItemRequest.normalizeName(request.name);
    for (final ShoppingItemSummary item in _items.values) {
      if (ShoppingItemRequest.normalizeName(item.name) == key) {
        if (request.urgency.isMoreUrgentThan(item.urgency)) {
          _put(ShoppingItemSummary(
            id: item.id,
            name: item.name,
            urgency: request.urgency,
            quantity: item.quantity,
            categoryNames: item.categoryNames,
            isOverdue: item.isOverdue,
          ));
        }
        return item.id;
      }
    }
    final String id = 'shopping-${_nextId++}';
    _put(ShoppingItemSummary(id: id, name: request.name, urgency: request.urgency, quantity: request.quantity));
    return id;
  }

  @override
  Future<List<ShoppingItemSummary>> pendingItems() async => _sorted();

  @override
  Stream<List<ShoppingItemSummary>> watchPendingItems() {
    late final StreamController<List<ShoppingItemSummary>> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<List<ShoppingItemSummary>>(
      onListen: () {
        controller.add(_sorted());
        changes = _changes.stream.listen((_) => controller.add(_sorted()));
      },
      // No devuelve el futuro de cancel(): `first` lo esperaría y, con el
      // reloj simulado de testWidgets, no se completa.
      onCancel: () {
        unawaited(changes?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  void _put(ShoppingItemSummary item) {
    _items[item.id] = item;
    _changes.add(null);
  }

  List<ShoppingItemSummary> _sorted() => _items.values.toList()
    ..sort((ShoppingItemSummary a, ShoppingItemSummary b) {
      final int byUrgency = a.urgency.compareTo(b.urgency);
      return byUrgency != 0 ? byUrgency : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
}
