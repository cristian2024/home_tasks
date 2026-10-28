import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/item_queries.dart';
import '../../domain/use_cases/move_item.dart';

enum MoveItemStatus { loading, ready, moving, moved, missing }

/// Por qué no se puede elegir un contenedor.
enum MoveBlock {
  /// El objeto ya está ahí.
  current,

  /// Se superaría el máximo de niveles.
  tooDeep,
}

/// Contenedor posible para el objeto que se mueve.
class MoveCandidate extends Equatable {
  const MoveCandidate({required this.item, required this.path, this.block});

  final HouseholdItem item;

  /// Contenedores del candidato, para distinguir objetos con el mismo nombre.
  final List<HouseholdItem> path;
  final MoveBlock? block;

  @override
  List<Object?> get props => <Object?>[item, path, block];
}

class MoveItemState extends Equatable {
  const MoveItemState({
    this.status = MoveItemStatus.loading,
    this.item,
    this.candidates = const <MoveCandidate>[],
    this.query = '',
    this.error,
    this.destination,
  });

  final MoveItemStatus status;

  /// Objeto que se mueve.
  final HouseholdItem? item;

  /// Todos los destinos posibles: excluye el propio objeto y lo que contiene.
  final List<MoveCandidate> candidates;
  final String query;
  final Object? error;

  /// Contenedor al que se movió, cuando [status] es `moved`.
  final HouseholdItem? destination;

  /// Candidatos cuyo nombre contiene [query], sin distinguir mayúsculas.
  List<MoveCandidate> get visible {
    final String needle = query.trim().toLowerCase();
    return needle.isEmpty
        ? candidates
        : candidates.where((MoveCandidate candidate) => candidate.item.name.toLowerCase().contains(needle)).toList();
  }

  MoveItemState copyWith({
    MoveItemStatus? status,
    HouseholdItem? item,
    List<MoveCandidate>? candidates,
    String? query,
    Object? Function()? error,
    HouseholdItem? destination,
  }) {
    return MoveItemState(
      status: status ?? this.status,
      item: item ?? this.item,
      candidates: candidates ?? this.candidates,
      query: query ?? this.query,
      error: error == null ? this.error : error(),
      destination: destination ?? this.destination,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, item, candidates, query, error, destination];
}

/// Elegir el contenedor al que se mueve un objeto (Cubit, §11.1). Los
/// destinos que superarían el límite de niveles se muestran bloqueados para
/// que no haya que probar y esperar un error.
class MoveItemCubit extends Cubit<MoveItemState> {
  MoveItemCubit(
    this.itemId, {
    required WatchItemTree watchItemTree,
    required MoveItem moveItem,
    required ContainmentPolicy containmentPolicy,
  })  : _moveItem = moveItem,
        _policy = containmentPolicy,
        super(const MoveItemState()) {
    _subscription = watchItemTree().listen(_onTree);
  }

  final String itemId;
  final MoveItem _moveItem;
  final ContainmentPolicy _policy;
  late final StreamSubscription<ItemTree> _subscription;
  ItemTree? _tree;

  /// Máximo de niveles permitido.
  int get maxDepth => _policy.maxDepth;

  void _onTree(ItemTree tree) {
    _tree = tree;
    final HouseholdItem? item = tree[itemId];
    if (item == null) {
      emit(MoveItemState(status: MoveItemStatus.missing, query: state.query));
      return;
    }
    final int height = tree.heightOf(itemId);
    emit(
      state.copyWith(
        status: state.status == MoveItemStatus.loading || state.status == MoveItemStatus.missing
            ? MoveItemStatus.ready
            : null,
        item: item,
        candidates: <MoveCandidate>[
          for (final HouseholdItem candidate in tree.items)
            if (candidate.id != itemId && !tree.isInside(candidate.id, ancestorId: itemId))
              MoveCandidate(
                item: candidate,
                path: tree.pathOf(candidate.id),
                block: candidate.id == item.parentId
                    ? MoveBlock.current
                    : (_policy.allows(parentDepth: tree.depthOf(candidate.id), subtreeHeight: height)
                        ? null
                        : MoveBlock.tooDeep),
              ),
        ],
      ),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> moveTo(HouseholdItem container) async {
    if (state.status != MoveItemStatus.ready) {
      return;
    }
    emit(state.copyWith(status: MoveItemStatus.moving, error: () => null));
    try {
      await _moveItem(itemId, parentId: container.id);
      emit(state.copyWith(status: MoveItemStatus.moved, destination: _tree?[container.id] ?? container));
    } catch (error) {
      emit(state.copyWith(status: MoveItemStatus.ready, error: () => error));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
