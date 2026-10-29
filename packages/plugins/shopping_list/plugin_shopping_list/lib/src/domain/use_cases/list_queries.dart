import 'dart:async';

import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

/// La lista en un momento: categorías ordenadas e items con su estado.
class ShoppingListSnapshot extends Equatable {
  const ShoppingListSnapshot({required this.categories, required this.entries});

  final List<ShoppingCategory> categories;
  final List<ShoppingListEntry> entries;

  /// Lo que hay que comprar ahora (pendiente o atrasado).
  List<ShoppingListEntry> get toBuy =>
      entries.where((ShoppingListEntry entry) => entry.state.isToBuy).toList();

  @override
  List<Object?> get props => <Object?>[categories, entries];
}

/// Items y categorías juntos, al suscribirse y cada vez que cambia algo. El
/// estado de cada item se calcula con la hora del momento en que se emite.
class WatchShoppingList {
  const WatchShoppingList(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Stream<ShoppingListSnapshot> call() {
    late final StreamController<ShoppingListSnapshot> controller;
    StreamSubscription<List<ShoppingItem>>? items;
    StreamSubscription<List<ShoppingCategory>>? categories;
    List<ShoppingItem>? lastItems;
    List<ShoppingCategory>? lastCategories;

    void emit() {
      final List<ShoppingItem>? currentItems = lastItems;
      final List<ShoppingCategory>? currentCategories = lastCategories;
      if (currentItems != null && currentCategories != null) {
        controller.add(ShoppingListSnapshot(
          categories: ShoppingListView.sortCategories(currentCategories),
          entries: ShoppingListView.entries(currentItems, currentCategories, _clock.nowUtc()),
        ));
      }
    }

    controller = StreamController<ShoppingListSnapshot>(
      onListen: () {
        items = _repository.watchItems().listen((List<ShoppingItem> value) {
          lastItems = value;
          emit();
        }, onError: controller.addError);
        categories = _repository.watchCategories().listen((List<ShoppingCategory> value) {
          lastCategories = value;
          emit();
        }, onError: controller.addError);
      },
      // No devuelve los futuros de cancel(): con el reloj simulado de
      // testWidgets no se completan.
      onCancel: () {
        unawaited(items?.cancel());
        unawaited(categories?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }
}

class WatchShoppingCategories {
  const WatchShoppingCategories(this._repository);

  final ShoppingListRepository _repository;

  Stream<List<ShoppingCategory>> call() => _repository.watchCategories();
}
