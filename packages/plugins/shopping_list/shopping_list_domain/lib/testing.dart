/// Dobles de prueba y tests de contrato del dominio de la lista de compras.
library;

import 'dart:async';

import 'shopping_list_domain.dart';

export 'src/testing/shopping_list_repository_contract.dart';

/// [ShoppingListRepository] en memoria, para tests y apps de ejemplo. Cumple
/// `shoppingListRepositoryContract`.
class InMemoryShoppingListRepository implements ShoppingListRepository {
  final Map<String, ShoppingItem> _items = <String, ShoppingItem>{};
  final Map<String, ShoppingCategory> _categories = <String, ShoppingCategory>{};
  final Map<String, ShoppingPurchase> _purchases = <String, ShoppingPurchase>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  bool _seeded = false;

  @override
  Future<void> saveItem(ShoppingItem item) async {
    _items[item.id] = item;
    _changed();
  }

  @override
  Future<ShoppingItem?> getItem(String id) async => _items[id];

  @override
  Future<List<ShoppingItem>> getItems() async => _items.values.toList();

  @override
  Stream<List<ShoppingItem>> watchItems() => _watch(() => _items.values.toList());

  @override
  Future<void> deleteItems(List<String> ids) async {
    for (final String id in ids) {
      _items.remove(id);
      _purchases.removeWhere((String _, ShoppingPurchase purchase) => purchase.itemId == id);
    }
    _changed();
  }

  @override
  Future<void> saveCategories(List<ShoppingCategory> categories) async {
    for (final ShoppingCategory category in categories) {
      _categories[category.id] = category;
    }
    _changed();
  }

  @override
  Future<List<ShoppingCategory>> getCategories() async => _sortedCategories();

  @override
  Stream<List<ShoppingCategory>> watchCategories() => _watch(_sortedCategories);

  @override
  Future<void> deleteCategory(String id, {required DateTime updatedAt}) async {
    if (_categories.remove(id) == null) {
      return;
    }
    for (final ShoppingItem item in _items.values.toList()) {
      if (item.categoryIds.contains(id)) {
        _items[item.id] = item.copyWith(
          categoryIds: <String>[for (final String categoryId in item.categoryIds) if (categoryId != id) categoryId],
          updatedAt: updatedAt,
        );
      }
    }
    _changed();
  }

  @override
  Future<bool> seedDefaultCategories(List<ShoppingCategory> defaults) async {
    if (_seeded) {
      return false;
    }
    _seeded = true;
    await saveCategories(defaults);
    return true;
  }

  @override
  Future<void> recordPurchase(ShoppingItem item, ShoppingPurchase purchase) async {
    _items[item.id] = item;
    _purchases[purchase.id] = purchase;
    _changed();
  }

  @override
  Future<void> undoPurchase(ShoppingItem item, String purchaseId) async {
    _items[item.id] = item;
    _purchases.remove(purchaseId);
    _changed();
  }

  @override
  Future<List<ShoppingPurchase>> getPurchases(String itemId) async => _purchases.values
      .where((ShoppingPurchase purchase) => purchase.itemId == itemId)
      .toList()
    ..sort((ShoppingPurchase a, ShoppingPurchase b) => b.purchasedAt.compareTo(a.purchasedAt));

  /// Libera los streams abiertos.
  Future<void> close() => _changes.close();

  List<ShoppingCategory> _sortedCategories() => ShoppingListView.sortCategories(_categories.values.toList());

  void _changed() => _changes.add(null);

  /// Emite [read] al suscribirse y con cada cambio. El valor inicial se emite
  /// en `onListen`, así que no se pierde una escritura hecha justo después de
  /// suscribirse.
  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
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
}
