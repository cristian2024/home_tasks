import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';

import '../mappers/sync_mappers.dart';
import '../models/isar_sync_change_record.dart';
import '../models/isar_sync_vector_entry.dart';
import 'isar_change_log_writer.dart';

/// [ChangeLog] sobre Isar. El vector se guarda aparte y se actualiza en la
/// misma transacción que los registros, así que leerlo no recorre el
/// historial.
class IsarChangeLog implements ChangeLog {
  IsarChangeLog(this._isar) : _writer = IsarChangeLogWriter(_isar);

  final Isar _isar;
  final IsarChangeLogWriter _writer;

  @override
  Future<void> append(List<ChangeRecord> records) => _isar.writeTxn(() => _writer.append(records));

  @override
  Future<VersionVector> vector() async {
    final List<IsarSyncVectorEntry> entries = await _isar.isarSyncVectorEntrys.where().findAll();
    return VersionVector(<String, int>{for (final IsarSyncVectorEntry entry in entries) entry.deviceId: entry.seq});
  }

  @override
  Stream<VersionVector> watchVector() =>
      _isar.isarSyncVectorEntrys.watchLazy(fireImmediately: true).asyncMap((_) => vector()).distinct();

  @override
  Future<List<ChangeRecord>> missingFor(VersionVector remote, {int? limit}) => _isar.txn(() async {
        final List<IsarSyncVectorEntry> devices = await _isar.isarSyncVectorEntrys.where().sortByDeviceId().findAll();
        final List<ChangeRecord> missing = <ChangeRecord>[];
        for (final IsarSyncVectorEntry device in devices) {
          final int? remaining = limit == null ? null : limit - missing.length;
          if (remaining != null && remaining <= 0) {
            break;
          }
          final QueryBuilder<IsarSyncChangeRecord, IsarSyncChangeRecord, QAfterWhereClause> query =
              _isar.isarSyncChangeRecords.where().deviceIdEqualToSeqGreaterThan(device.deviceId, remote[device.deviceId]);
          final List<IsarSyncChangeRecord> rows =
              remaining == null ? await query.findAll() : await query.limit(remaining).findAll();
          missing.addAll(rows.map(SyncMappers.fromIsarRecord));
        }
        return missing;
      });
}
