import 'dart:async';

import 'package:core_utils/core_utils.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import 'category_use_cases.dart';
import 'item_use_cases.dart';
import 'list_queries.dart';
import 'purchase_use_cases.dart';

/// Capacidades públicas de la lista ([ShoppingListQuery] y
/// [ShoppingListWriter]). El plugin las registra en su scope mientras está
/// activo. Pasa `shoppingListCapabilitiesContract`.
class ShoppingListApi implements ShoppingListQuery, ShoppingListWriter {
  ShoppingListApi({
    required ShoppingListRepository repository,
    required Clock clock,
    required CreateShoppingItem createItem,
    required MarkShoppingItemPending markPending,
    required ShoppingCategoryNamer categoryName,
  })  : _repository = repository,
        _watchList = WatchShoppingList(repository, clock),
        _clock = clock,
        _createItem = createItem,
        _markPending = markPending,
        _categoryName = categoryName;

  final ShoppingListRepository _repository;
  final WatchShoppingList _watchList;
  final Clock _clock;
  final CreateShoppingItem _createItem;
  final MarkShoppingItemPending _markPending;
  final ShoppingCategoryNamer _categoryName;

  @override
  Future<List<ShoppingItemSummary>> pendingItems() async => _summaries(
        ShoppingListView.entries(await _repository.getItems(), await _repository.getCategories(), _clock.nowUtc()),
      );

  @override
  Stream<List<ShoppingItemSummary>> watchPendingItems() =>
      _watchList().map((ShoppingListSnapshot snapshot) => _summaries(snapshot.entries));

  /// Un item por comprar con el mismo nombre se reutiliza (subiendo su
  /// urgencia si hace falta); uno normal ya comprado vuelve a pendiente.
  @override
  Future<String> addItem(ShoppingItemRequest request) async {
    final String key = ShoppingValidator.normalize(request.name);
    final List<ShoppingListEntry> entries =
        ShoppingListView.entries(await _repository.getItems(), const <ShoppingCategory>[], _clock.nowUtc());
    final List<ShoppingListEntry> sameName = <ShoppingListEntry>[
      for (final ShoppingListEntry entry in entries)
        if (ShoppingValidator.normalize(entry.item.name) == key) entry,
    ];
    for (final ShoppingListEntry entry in sameName) {
      if (entry.state.isToBuy) {
        if (request.urgency.isMoreUrgentThan(entry.item.urgency)) {
          await _markPending(entry.item.id, urgency: request.urgency);
        }
        return entry.item.id;
      }
    }
    for (final ShoppingListEntry entry in sameName) {
      if (entry.state == ShoppingItemState.purchased) {
        await _markPending(entry.item.id, urgency: request.urgency);
        return entry.item.id;
      }
    }
    final ShoppingItem item = await _createItem(
      name: request.name,
      quantity: request.quantity ?? '',
      notes: request.notes ?? '',
      urgency: request.urgency,
    );
    return item.id;
  }

  List<ShoppingItemSummary> _summaries(List<ShoppingListEntry> entries) => <ShoppingItemSummary>[
        for (final ShoppingListEntry entry in entries)
          if (entry.state.isToBuy)
            ShoppingItemSummary(
              id: entry.item.id,
              name: entry.item.name,
              urgency: entry.item.urgency,
              quantity: entry.item.quantity.isEmpty ? null : entry.item.quantity,
              categoryNames: entry.categories.map(_categoryName).toList(),
              isOverdue: entry.state == ShoppingItemState.overdue,
            ),
      ]..sort((ShoppingItemSummary a, ShoppingItemSummary b) {
          final int byUrgency = a.urgency.compareTo(b.urgency);
          return byUrgency != 0 ? byUrgency : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
}
