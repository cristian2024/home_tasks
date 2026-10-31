import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';

import '../mappers/sync_mappers.dart';
import '../models/isar_sync_change_record.dart';
import '../models/isar_sync_vector_entry.dart';

/// Escribe registros de cambio **dentro de una transacción de escritura ya
/// abierta** de la base, para guardarlos a la vez que la entidad:
///
/// ```dart
/// await isar.writeTxn(() async {
///   await isar.items.put(model);
///   final int seq = await writer.nextSeq(deviceId);
///   await writer.append(<ChangeRecord>[ChangeRecord(seq: seq, ...)]);
/// });
/// ```
///
/// Si algo falla, la transacción se deshace entera: ni la entidad ni el
/// registro quedan guardados.
class IsarChangeLogWriter {
  IsarChangeLogWriter(this._isar);

  final Isar _isar;

  /// El `seq` del siguiente registro de [deviceId].
  Future<int> nextSeq(String deviceId) async =>
      ((await _isar.isarSyncVectorEntrys.getByDeviceId(deviceId))?.seq ?? 0) + 1;

  /// Guarda [records] e ignora los que ya existen (mismo `opId`). Lanza
  /// [ArgumentError] si alguno ocupa el `seq` de otro registro distinto del
  /// mismo dispositivo; al deshacerse la transacción no queda ninguno.
  Future<void> append(List<ChangeRecord> records) async {
    final IsarCollection<IsarSyncChangeRecord> stored = _isar.isarSyncChangeRecords;
    final Set<String> devices = <String>{};
    for (final ChangeRecord record in records) {
      if (await stored.getByOpId(record.opId) != null) {
        continue;
      }
      if (await stored.getByDeviceIdSeq(record.deviceId, record.seq) != null) {
        throw ArgumentError.value(record, 'records', 'El seq ${record.seq} de ${record.deviceId} ya es de otro registro');
      }
      await stored.put(SyncMappers.toIsarRecord(record));
      devices.add(record.deviceId);
    }
    for (final String deviceId in devices) {
      await _advance(deviceId);
    }
  }

  /// Avanza la entrada del vector de [deviceId] mientras exista el siguiente.
  Future<void> _advance(String deviceId) async {
    final IsarSyncVectorEntry entry = await _isar.isarSyncVectorEntrys.getByDeviceId(deviceId) ??
        (IsarSyncVectorEntry()
          ..deviceId = deviceId
          ..seq = 0);
    while (await _isar.isarSyncChangeRecords.getByDeviceIdSeq(deviceId, entry.seq + 1) != null) {
      entry.seq++;
    }
    await _isar.isarSyncVectorEntrys.put(entry);
  }
}
