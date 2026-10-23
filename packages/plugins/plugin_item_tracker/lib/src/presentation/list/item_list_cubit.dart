import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/hierarchy/item_tree.dart';
import '../../domain/use_cases/item_queries.dart';

class ItemListState extends Equatable {
  ItemListState({this.loading = true, ItemTree? tree, this.query = ''}) : tree = tree ?? ItemTree(const []);

  final bool loading;

  /// Todos los objetos, con su jerarquía para mostrar dónde está cada uno.
  final ItemTree tree;
  final String query;

  List<HouseholdItem> get all => tree.items;

  /// Objetos cuyo nombre contiene [query], sin distinguir mayúsculas.
  List<HouseholdItem> get visible {
    final needle = query.trim().toLowerCase();
    return needle.isEmpty ? all : all.where((item) => item.name.toLowerCase().contains(needle)).toList();
  }

  @override
  List<Object?> get props => [loading, tree, query];
}

/// Listado reactivo de objetos con filtro por nombre. Incluye los que están
/// dentro de otros; la pantalla muestra su ruta.
class ItemListCubit extends Cubit<ItemListState> {
  ItemListCubit(WatchItemTree watchItemTree) : super(ItemListState()) {
    _subscription = watchItemTree().listen(
      (tree) => emit(ItemListState(loading: false, tree: tree, query: state.query)),
    );
  }

  late final StreamSubscription<ItemTree> _subscription;

  void search(String query) => emit(ItemListState(loading: state.loading, tree: state.tree, query: query));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
