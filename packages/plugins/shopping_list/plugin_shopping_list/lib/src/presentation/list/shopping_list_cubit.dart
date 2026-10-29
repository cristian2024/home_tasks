import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../domain/use_cases/purchase_use_cases.dart';

enum ShoppingListStatus { loading, ready }

class ShoppingListState extends Equatable {
  const ShoppingListState({
    this.status = ShoppingListStatus.loading,
    this.snapshot = const ShoppingListSnapshot(categories: <ShoppingCategory>[], entries: <ShoppingListEntry>[]),
    this.filter = const ShoppingListFilter(),
    this.grouping = ShoppingGrouping.category,
    this.showFilters = false,
    this.lastPurchase,
    this.error,
  });

  final ShoppingListStatus status;
  final ShoppingListSnapshot snapshot;
  final ShoppingListFilter filter;
  final ShoppingGrouping grouping;

  /// Si se ve el panel de filtros y agrupación.
  final bool showFilters;

  /// La última compra, para ofrecer deshacerla.
  final ShoppingPurchaseReceipt? lastPurchase;
  final Object? error;

  List<ShoppingListEntry> get filtered => snapshot.entries.where(filter.matches).toList();

  List<ShoppingGroup> get groups => ShoppingListView.group(filtered, grouping);

  bool get hasPurchased =>
      snapshot.entries.any((ShoppingListEntry entry) => entry.state == ShoppingItemState.purchased);

  ShoppingListState copyWith({
    ShoppingListStatus? status,
    ShoppingListSnapshot? snapshot,
    ShoppingListFilter? filter,
    ShoppingGrouping? grouping,
    bool? showFilters,
    ShoppingPurchaseReceipt? Function()? lastPurchase,
    Object? Function()? error,
  }) =>
      ShoppingListState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
        filter: filter ?? this.filter,
        grouping: grouping ?? this.grouping,
        showFilters: showFilters ?? this.showFilters,
        lastPurchase: lastPurchase == null ? this.lastPurchase : lastPurchase(),
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => <Object?>[status, snapshot, filter, grouping, showFilters, lastPurchase, error];
}

/// La lista con sus filtros y agrupación, y las acciones de marcar.
class ShoppingListCubit extends Cubit<ShoppingListState> {
  ShoppingListCubit({
    required WatchShoppingList watchList,
    required MarkShoppingItemPurchased markPurchased,
    required UndoShoppingPurchase undoPurchase,
    required MarkShoppingItemPending markPending,
    required ClearPurchasedShoppingItems clearPurchased,
  })  : _markPurchased = markPurchased,
        _undoPurchase = undoPurchase,
        _markPending = markPending,
        _clearPurchased = clearPurchased,
        super(const ShoppingListState()) {
    _subscription = watchList().listen(
      (ShoppingListSnapshot snapshot) =>
          emit(state.copyWith(status: ShoppingListStatus.ready, snapshot: snapshot)),
      onError: (Object error) => emit(state.copyWith(status: ShoppingListStatus.ready, error: () => error)),
    );
  }

  final MarkShoppingItemPurchased _markPurchased;
  final UndoShoppingPurchase _undoPurchase;
  final MarkShoppingItemPending _markPending;
  final ClearPurchasedShoppingItems _clearPurchased;
  late final StreamSubscription<ShoppingListSnapshot> _subscription;

  void setFilter(ShoppingListFilter filter) => emit(state.copyWith(filter: filter));

  void setGrouping(ShoppingGrouping grouping) => emit(state.copyWith(grouping: grouping));

  void toggleFilters() => emit(state.copyWith(showFilters: !state.showFilters));

  /// Marca o desmarca: un item por comprar pasa a comprado; uno comprado
  /// vuelve a pendiente.
  Future<void> toggle(ShoppingListEntry entry) => _run(() async {
        if (entry.state == ShoppingItemState.purchased) {
          await _markPending(entry.item.id);
          emit(state.copyWith(lastPurchase: () => null));
          return;
        }
        final ShoppingPurchaseReceipt? receipt = await _markPurchased(entry.item.id);
        emit(state.copyWith(lastPurchase: () => receipt));
      });

  Future<void> undoLastPurchase() => _run(() async {
        final ShoppingPurchaseReceipt? receipt = state.lastPurchase;
        if (receipt != null) {
          emit(state.copyWith(lastPurchase: () => null));
          await _undoPurchase(receipt);
        }
      });

  Future<void> clearPurchased() => _run(() async {
        await _clearPurchased();
      });

  void clearError() => emit(state.copyWith(error: () => null));

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      emit(state.copyWith(error: () => error));
    }
  }

  @override
  Future<void> close() {
    // Sin await: ver «Handlers de bloc» en CLAUDE.md.
    unawaited(_subscription.cancel());
    return super.close();
  }
}
