import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/item_use_cases.dart';
import '../../domain/use_cases/list_queries.dart';
import '../../domain/use_cases/purchase_use_cases.dart';

enum ShoppingListStatus { loading, ready }

/// Un item recién borrado, para ofrecer deshacerlo.
class ShoppingDeletion extends Equatable {
  const ShoppingDeletion({required this.item, this.showSwipeTip = false});

  final ShoppingItem item;

  /// Si el aviso sugiere deslizar la fila (la primera vez que se borra desde
  /// editar).
  final bool showSwipeTip;

  @override
  List<Object?> get props => <Object?>[item, showSwipeTip];
}

/// Un item que volvió a pendiente, para ofrecer deshacerlo.
class ShoppingReopening extends Equatable {
  const ShoppingReopening({required this.previous});

  /// El item como estaba (comprado).
  final ShoppingItem previous;

  @override
  List<Object?> get props => <Object?>[previous];
}

/// Por qué no se pudo crear un item desde el campo de la lista.
sealed class QuickAddError extends Equatable {
  const QuickAddError();
}

final class QuickAddEmpty extends QuickAddError {
  const QuickAddEmpty();

  @override
  List<Object?> get props => <Object?>[];
}

final class QuickAddTooLong extends QuickAddError {
  const QuickAddTooLong(this.length);

  final int length;

  @override
  List<Object?> get props => <Object?>[length];
}

/// El campo de crear desde la lista.
class QuickAddState extends Equatable {
  const QuickAddState({this.categoryId, this.error});

  /// La categoría que tendrá el item nuevo; `null` es «Sin categoría».
  final String? categoryId;
  final QuickAddError? error;

  @override
  List<Object?> get props => <Object?>[categoryId, error];
}

class ShoppingListState extends Equatable {
  const ShoppingListState({
    this.status = ShoppingListStatus.loading,
    this.snapshot = const ShoppingListSnapshot(categories: <ShoppingCategory>[], entries: <ShoppingListEntry>[]),
    this.filter = ShoppingListFilter.defaults,
    this.grouping = ShoppingGrouping.category,
    this.showFilters = false,
    this.quickAdd,
    this.lastAdded,
    this.lastPurchase,
    this.lastDeletion,
    this.lastReopening,
    this.error,
  });

  final ShoppingListStatus status;
  final ShoppingListSnapshot snapshot;
  final ShoppingListFilter filter;
  final ShoppingGrouping grouping;

  /// Si se ve el panel de filtros y agrupación.
  final bool showFilters;

  /// El campo de crear; `null` si está cerrado.
  final QuickAddState? quickAdd;

  /// El último item creado desde el campo, para resaltarlo y anunciarlo.
  final ShoppingItem? lastAdded;

  /// La última compra, para ofrecer deshacerla.
  final ShoppingPurchaseReceipt? lastPurchase;
  final ShoppingDeletion? lastDeletion;
  final ShoppingReopening? lastReopening;
  final Object? error;

  List<ShoppingListEntry> get filtered => snapshot.entries.where(filter.matches).toList();

  List<ShoppingGroup> get groups => ShoppingListView.group(filtered, grouping);

  /// Lo comprado, de lo más reciente a lo más antiguo.
  List<ShoppingListEntry> get bought => ShoppingListView.bought(snapshot.entries);

  /// Lo que espera a su siguiente ventana.
  List<ShoppingListEntry> get waiting => ShoppingListView.waiting(snapshot.entries);

  /// Si el filtro o la agrupación no son los de por defecto.
  bool get isCustomized => !filter.isDefault || grouping != ShoppingGrouping.category;

  ShoppingListState copyWith({
    ShoppingListStatus? status,
    ShoppingListSnapshot? snapshot,
    ShoppingListFilter? filter,
    ShoppingGrouping? grouping,
    bool? showFilters,
    QuickAddState? Function()? quickAdd,
    ShoppingItem? Function()? lastAdded,
    ShoppingPurchaseReceipt? Function()? lastPurchase,
    ShoppingDeletion? Function()? lastDeletion,
    ShoppingReopening? Function()? lastReopening,
    Object? Function()? error,
  }) =>
      ShoppingListState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
        filter: filter ?? this.filter,
        grouping: grouping ?? this.grouping,
        showFilters: showFilters ?? this.showFilters,
        quickAdd: quickAdd == null ? this.quickAdd : quickAdd(),
        lastAdded: lastAdded == null ? this.lastAdded : lastAdded(),
        lastPurchase: lastPurchase == null ? this.lastPurchase : lastPurchase(),
        lastDeletion: lastDeletion == null ? this.lastDeletion : lastDeletion(),
        lastReopening: lastReopening == null ? this.lastReopening : lastReopening(),
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        snapshot,
        filter,
        grouping,
        showFilters,
        quickAdd,
        lastAdded,
        lastPurchase,
        lastDeletion,
        lastReopening,
        error,
      ];
}

/// La lista con sus filtros y agrupación, y las acciones sobre sus items:
/// marcar, volver a pendiente, borrar y crear desde la lista. También la usan
/// las pantallas de comprados y en espera.
class ShoppingListCubit extends Cubit<ShoppingListState> {
  ShoppingListCubit({
    required WatchShoppingList watchList,
    required MarkShoppingItemPurchased markPurchased,
    required UndoShoppingPurchase undoPurchase,
    required MarkShoppingItemPending markPending,
    required RevertShoppingItem revertItem,
    required ClearPurchasedShoppingItems clearPurchased,
    required CreateShoppingItem createItem,
    required DeleteShoppingItems deleteItems,
    required RestoreShoppingItem restoreItem,
    required ShoppingListPreferences preferences,
  })  : _markPurchased = markPurchased,
        _undoPurchase = undoPurchase,
        _markPending = markPending,
        _revertItem = revertItem,
        _clearPurchased = clearPurchased,
        _createItem = createItem,
        _deleteItems = deleteItems,
        _restoreItem = restoreItem,
        _preferences = preferences,
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
  final RevertShoppingItem _revertItem;
  final ClearPurchasedShoppingItems _clearPurchased;
  final CreateShoppingItem _createItem;
  final DeleteShoppingItems _deleteItems;
  final RestoreShoppingItem _restoreItem;
  final ShoppingListPreferences _preferences;
  late final StreamSubscription<ShoppingListSnapshot> _subscription;

  void setFilter(ShoppingListFilter filter) => emit(state.copyWith(filter: filter));

  /// Vuelve al filtro y la agrupación por defecto.
  void resetFilters() => emit(state.copyWith(filter: ShoppingListFilter.defaults, grouping: ShoppingGrouping.category));

  void setGrouping(ShoppingGrouping grouping) => emit(state.copyWith(grouping: grouping));

  void toggleFilters() => emit(state.copyWith(showFilters: !state.showFilters));

  /// Marca o desmarca: un item por comprar (o en espera) pasa a comprado; uno
  /// comprado vuelve a pendiente.
  Future<void> toggle(ShoppingListEntry entry) => _run(() async {
        if (entry.state == ShoppingItemState.purchased) {
          await _markPending(entry.item.id);
          emit(state.copyWith(lastReopening: () => ShoppingReopening(previous: entry.item), lastPurchase: () => null));
          return;
        }
        final ShoppingPurchaseReceipt? receipt = await _markPurchased(entry.item.id);
        emit(state.copyWith(lastPurchase: () => receipt, lastReopening: () => null));
      });

  Future<void> undoLastPurchase() => _run(() async {
        final ShoppingPurchaseReceipt? receipt = state.lastPurchase;
        if (receipt != null) {
          emit(state.copyWith(lastPurchase: () => null));
          await _undoPurchase(receipt);
        }
      });

  Future<void> undoLastReopening() => _run(() async {
        final ShoppingReopening? reopening = state.lastReopening;
        if (reopening != null) {
          emit(state.copyWith(lastReopening: () => null));
          await _revertItem(reopening.previous);
        }
      });

  /// Borra [item] sin confirmación (p. ej. al deslizarlo).
  Future<void> delete(ShoppingItem item) => _run(() async {
        await _deleteItems(<String>[item.id]);
        emit(state.copyWith(lastDeletion: () => ShoppingDeletion(item: item)));
      });

  /// El formulario borró [item]. La primera vez, el aviso sugiere el gesto de
  /// deslizar, salvo sin [offerSwipeTip] (p. ej. con un lector de pantalla,
  /// que ya tiene la acción de borrar en la fila).
  Future<void> deletedFromForm(ShoppingItem item, {required bool offerSwipeTip}) => _run(() async {
        final bool showTip = offerSwipeTip && !await _preferences.swipeTipShown();
        if (showTip) {
          await _preferences.setSwipeTipShown();
        }
        emit(state.copyWith(lastDeletion: () => ShoppingDeletion(item: item, showSwipeTip: showTip)));
      });

  Future<void> undoLastDeletion() => _run(() async {
        final ShoppingDeletion? deletion = state.lastDeletion;
        if (deletion != null) {
          emit(state.copyWith(lastDeletion: () => null));
          await _restoreItem(deletion.item);
        }
      });

  Future<void> clearPurchased() => _run(() async {
        await _clearPurchased();
      });

  /// Abre el campo de crear con la categoría que corresponde
  /// ([ShoppingListView.quickAddCategory]).
  Future<void> openQuickAdd() => _run(() async {
        final String? categoryId = ShoppingListView.quickAddCategory(
          filter: state.filter,
          lastUsedId: await _preferences.lastQuickAddCategoryId(),
          categories: state.snapshot.categories,
        );
        emit(state.copyWith(quickAdd: () => QuickAddState(categoryId: categoryId)));
      });

  void closeQuickAdd() => emit(state.copyWith(quickAdd: () => null));

  /// Cambia la categoría del item nuevo. Pasa a ser la última usada.
  Future<void> chooseQuickAddCategory(String? categoryId) => _run(() async {
        if (state.quickAdd == null) {
          return;
        }
        emit(state.copyWith(quickAdd: () => QuickAddState(categoryId: categoryId)));
        await _preferences.setLastQuickAddCategoryId(categoryId);
      });

  /// Crea un item con [name] en la categoría del campo, con urgencia normal,
  /// sin cantidad y sin repetición. Devuelve si lo creó; si no, el campo
  /// muestra el error.
  Future<bool> submitQuickAdd(String name) async {
    final QuickAddState? quickAdd = state.quickAdd;
    if (quickAdd == null) {
      return false;
    }
    final String? categoryId = quickAdd.categoryId;
    try {
      final ShoppingItem item = await _createItem(name: name, categoryIds: <String>[?categoryId]);
      await _preferences.setLastQuickAddCategoryId(categoryId);
      emit(state.copyWith(lastAdded: () => item, quickAdd: () => QuickAddState(categoryId: categoryId)));
      return true;
    } on ShoppingValidationException catch (error) {
      final QuickAddError quickAddError = switch (error.reason) {
        ShoppingValidationReason.empty => const QuickAddEmpty(),
        ShoppingValidationReason.tooLong => QuickAddTooLong(name.trim().length),
      };
      emit(state.copyWith(quickAdd: () => QuickAddState(categoryId: categoryId, error: quickAddError)));
      return false;
    } on Object catch (error) {
      emit(state.copyWith(error: () => error));
      return false;
    }
  }

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
