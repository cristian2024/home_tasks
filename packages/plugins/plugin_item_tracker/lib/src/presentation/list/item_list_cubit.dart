import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/use_cases/item_queries.dart';

class ItemListState extends Equatable {
  const ItemListState({this.loading = true, this.all = const [], this.query = ''});

  final bool loading;
  final List<HouseholdItem> all;
  final String query;

  /// Objetos cuyo nombre contiene [query], sin distinguir mayúsculas.
  List<HouseholdItem> get visible {
    final needle = query.trim().toLowerCase();
    return needle.isEmpty ? all : all.where((item) => item.name.toLowerCase().contains(needle)).toList();
  }

  @override
  List<Object?> get props => [loading, all, query];
}

/// Listado reactivo de objetos con filtro por nombre.
class ItemListCubit extends Cubit<ItemListState> {
  ItemListCubit(WatchItems watchItems) : super(const ItemListState()) {
    _subscription = watchItems().listen(
      (items) => emit(ItemListState(loading: false, all: items, query: state.query)),
    );
  }

  late final StreamSubscription<List<HouseholdItem>> _subscription;

  void search(String query) => emit(ItemListState(loading: state.loading, all: state.all, query: query));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
