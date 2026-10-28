import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/bind_identifier.dart';
import '../../domain/use_cases/item_queries.dart';

enum AssociateStatus { searching, ready, binding, bound }

class AssociateState extends Equatable {
  const AssociateState({
    this.status = AssociateStatus.searching,
    this.results = const <HouseholdItem>[],
    this.boundItem,
    this.error,
  });

  final AssociateStatus status;
  final List<HouseholdItem> results;
  final HouseholdItem? boundItem;
  final Object? error;

  @override
  List<Object?> get props => <Object?>[status, results, boundItem, error];
}

/// Asocia un identificador desconocido a un objeto existente (AC-05).
class AssociateCubit extends Cubit<AssociateState> {
  AssociateCubit({
    required this.identifier,
    required SearchItems searchItems,
    required BindIdentifier bindIdentifier,
  })  : _search = searchItems,
        _bind = bindIdentifier,
        super(const AssociateState()) {
    search('');
  }

  final ({String rawValue, IdentifierType type}) identifier;
  final SearchItems _search;
  final BindIdentifier _bind;
  int _searchGeneration = 0;

  Future<void> search(String query) async {
    final int generation = ++_searchGeneration;
    emit(AssociateState(status: AssociateStatus.searching, results: state.results));
    final List<HouseholdItem> results = await _search(query);
    // Descarta respuestas de búsquedas anteriores que lleguen tarde.
    if (generation == _searchGeneration && !isClosed) {
      emit(AssociateState(status: AssociateStatus.ready, results: results));
    }
  }

  Future<void> bind(HouseholdItem item) async {
    if (state.status == AssociateStatus.binding) {
      return;
    }
    emit(AssociateState(status: AssociateStatus.binding, results: state.results));
    try {
      await _bind(item.id, rawValue: identifier.rawValue, type: identifier.type);
      emit(AssociateState(status: AssociateStatus.bound, results: state.results, boundItem: item));
    } catch (error) {
      emit(AssociateState(status: AssociateStatus.ready, results: state.results, error: error));
    }
  }
}
