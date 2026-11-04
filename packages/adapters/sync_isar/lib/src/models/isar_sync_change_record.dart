import 'package:storage_isar/adapter.dart';

part 'isar_sync_change_record.g.dart';

/// Un `ChangeRecord`, propio o recibido. [json] lo guarda completo; los demás
/// campos sirven para buscarlo.
@collection
class IsarSyncChangeRecord {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String opId;

  @Index(unique: true, composite: <CompositeIndex>[CompositeIndex('seq')])
  late String deviceId;

  late int seq;

  late String json;
}
