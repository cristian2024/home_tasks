import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
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
///
/// `combineLatest2` espera a que terminen las cancelaciones al cancelar, así
/// que en `testWidgets` no hay que usar `first` sobre este stream: con el reloj
/// simulado no termina. Para leer una vez, usar el repositorio.
class WatchShoppingList {
  const WatchShoppingList(this._repository, this._clock);

  final ShoppingListRepository _repository;
  final Clock _clock;

  Stream<ShoppingListSnapshot> call() => Rx.combineLatest2(
        _repository.watchItems(),
        _repository.watchCategories(),
        (List<ShoppingItem> items, List<ShoppingCategory> categories) => ShoppingListSnapshot(
          categories: ShoppingListView.sortCategories(categories),
          entries: ShoppingListView.entries(items, categories, _clock.nowUtc()),
        ),
      );
}

class WatchShoppingCategories {
  const WatchShoppingCategories(this._repository);

  final ShoppingListRepository _repository;

  Stream<List<ShoppingCategory>> call() => _repository.watchCategories();
}
