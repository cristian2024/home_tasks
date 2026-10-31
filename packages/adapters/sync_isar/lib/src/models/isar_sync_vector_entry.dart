import 'package:storage_isar/adapter.dart';

part 'isar_sync_vector_entry.g.dart';

/// Entrada del vector local: hasta qué `seq` se tienen todos los registros de
/// un dispositivo. Se actualiza en la misma transacción que los registros.
@collection
class IsarSyncVectorEntry {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String deviceId;

  late int seq;
}
