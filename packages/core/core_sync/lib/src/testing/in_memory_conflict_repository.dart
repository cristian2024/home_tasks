import 'dart:async';

import '../contracts/conflict_repository.dart';
import '../model/sync_conflict.dart';
import 'watch.dart';

/// [ConflictRepository] en memoria. Cumple `conflictRepositoryContract`.
class InMemoryConflictRepository implements ConflictRepository {
  final Map<String, SyncConflict> _conflicts = <String, SyncConflict>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  @override
  Future<void> save(SyncConflict conflict) async {
    _conflicts[conflict.id] = conflict;
    _changes.add(null);
  }

  @override
  Future<SyncConflict?> get(String id) async => _conflicts[id];

  @override
  Future<List<SyncConflict>> openConflicts() async => _open();

  @override
  Stream<List<SyncConflict>> watchOpenConflicts() => watchValue(_changes.stream, _open);

  List<SyncConflict> _open() => _conflicts.values.where((SyncConflict conflict) => !conflict.isResolved).toList()
    ..sort((SyncConflict a, SyncConflict b) {
      final int byDate = a.detectedAt.compareTo(b.detectedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
}
