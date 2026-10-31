import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';

import '../mappers/sync_mappers.dart';
import '../models/isar_sync_conflict.dart';

/// [ConflictRepository] sobre Isar.
class IsarConflictRepository implements ConflictRepository {
  IsarConflictRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(SyncConflict conflict) =>
      _isar.writeTxn(() => _isar.isarSyncConflicts.putByConflictId(SyncMappers.toIsarConflict(conflict)));

  @override
  Future<SyncConflict?> get(String id) async {
    final IsarSyncConflict? stored = await _isar.isarSyncConflicts.getByConflictId(id);
    return stored == null ? null : SyncMappers.fromIsarConflict(stored);
  }

  @override
  Future<List<SyncConflict>> openConflicts() async => (await _isar.isarSyncConflicts
          .filter()
          .resolvedOptionIdIsNull()
          .sortByDetectedAt()
          .thenByConflictId()
          .findAll())
      .map(SyncMappers.fromIsarConflict)
      .toList();

  @override
  Stream<List<SyncConflict>> watchOpenConflicts() =>
      _isar.isarSyncConflicts.watchLazy(fireImmediately: true).asyncMap((_) => openConflicts());
}
