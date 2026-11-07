import 'dart:convert';

import 'package:core_sync/core_sync.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../models/isar_task.dart';
import '../models/isar_task_category.dart';
import '../models/isar_task_list_synced.dart';
import 'task_data_mapper.dart';

/// Conversión de las copias sincronizadas y de lo que la sincronización deja
/// para leer.
abstract final class SyncedEntityMapper {
  static IsarTaskListSynced toIsar(SyncedEntity entity) => IsarTaskListSynced()
    ..collection = entity.collection
    ..entityId = entity.id
    ..fieldsJson = jsonEncode(entity.fields)
    ..metadataJson = jsonEncode(entity.metadata.toJson());

  static SyncedEntity fromIsar(IsarTaskListSynced model) => SyncedEntity(
        collection: model.collection,
        id: model.entityId,
        fields: jsonDecode(model.fieldsJson) as Map<String, Object?>,
        metadata: SyncMetadata.fromJson(jsonDecode(model.metadataJson)),
      );

  static IsarTask toIsarTask(TaskResolved<HouseholdTask> resolved) =>
      TaskDataMapper.toIsarTask(resolved.entity)..deletedAt = resolved.deletedAt?.toUtc();

  static IsarTaskCategory toIsarCategory(TaskResolved<TaskCategory> resolved) =>
      TaskDataMapper.toIsarCategory(resolved.entity)..deletedAt = resolved.deletedAt?.toUtc();
}
