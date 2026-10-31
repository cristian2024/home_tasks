import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:sync_engine/sync_engine.dart';

class ConflictsState extends Equatable {
  const ConflictsState({
    this.loaded = false,
    this.conflicts = const <SyncConflict>[],
    this.itemNames = const <String, String>{},
    this.resolving = const <String>{},
  });

  final bool loaded;

  /// Abiertos, del más antiguo al más reciente.
  final List<SyncConflict> conflicts;

  /// Nombre de los objetos de item_tracker que aparecen en los conflictos.
  final Map<String, String> itemNames;

  /// Ids de los conflictos que se están resolviendo.
  final Set<String> resolving;

  ConflictsState copyWith({
    bool? loaded,
    List<SyncConflict>? conflicts,
    Map<String, String>? itemNames,
    Set<String>? resolving,
  }) =>
      ConflictsState(
        loaded: loaded ?? this.loaded,
        conflicts: conflicts ?? this.conflicts,
        itemNames: itemNames ?? this.itemNames,
        resolving: resolving ?? this.resolving,
      );

  @override
  List<Object?> get props => <Object?>[loaded, conflicts, itemNames, resolving];
}

/// Bandeja de conflictos: los abiertos y su resolución.
class ConflictsCubit extends Cubit<ConflictsState> {
  /// [items] da los nombres de los objetos; sin él, se muestran genéricos.
  ConflictsCubit({required ConflictInbox inbox, HouseholdItemRepository? items})
      : _inbox = inbox,
        _items = items,
        super(const ConflictsState()) {
    _subscription = inbox.watchOpen().listen((List<SyncConflict> conflicts) => unawaited(_onConflicts(conflicts)));
  }

  final ConflictInbox _inbox;
  final HouseholdItemRepository? _items;
  late final StreamSubscription<List<SyncConflict>> _subscription;

  Future<void> resolve(SyncConflict conflict, String optionId) async {
    emit(state.copyWith(resolving: <String>{...state.resolving, conflict.id}));
    try {
      await _inbox.resolve(conflict, optionId);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(resolving: <String>{...state.resolving}..remove(conflict.id)));
      }
    }
  }

  /// Confirma la resolución que ya rige en todos los abiertos.
  Future<void> keepAll() async {
    for (final SyncConflict conflict in state.conflicts) {
      await resolve(conflict, conflict.provisionalOptionId);
    }
  }

  Future<void> _onConflicts(List<SyncConflict> conflicts) async {
    final List<SyncConflict> sorted = <SyncConflict>[...conflicts]
      ..sort((SyncConflict a, SyncConflict b) => a.detectedAt.compareTo(b.detectedAt));
    final Map<String, String> names = <String, String>{...state.itemNames};
    final HouseholdItemRepository? items = _items;
    if (items != null) {
      for (final SyncConflict conflict in sorted) {
        if (!ItemTrackerCollections.all.contains(conflict.collection)) {
          continue;
        }
        for (final String id in conflict.entityIds) {
          if (!names.containsKey(id)) {
            final HouseholdItem? item = await items.getById(id);
            if (item != null) {
              names[id] = item.name;
            }
          }
        }
      }
    }
    if (!isClosed) {
      emit(state.copyWith(loaded: true, conflicts: sorted, itemNames: names));
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
