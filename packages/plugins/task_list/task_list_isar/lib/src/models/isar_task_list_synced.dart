import 'package:storage_isar/adapter.dart';

part 'isar_task_list_synced.g.dart';

/// Copia sincronizada de una tarea o una categoría (`SyncedEntity`). La fila
/// con [collection] igual a [migrationMarker] marca que la migración ya se
/// hizo.
@collection
class IsarTaskListSynced {
  static const String migrationMarker = 'task_list.migrated';

  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: <CompositeIndex>[CompositeIndex('entityId')])
  late String collection;

  late String entityId;

  /// Campos en JSON.
  late String fieldsJson;

  /// `SyncMetadata.toJson` en JSON.
  late String metadataJson;
}
