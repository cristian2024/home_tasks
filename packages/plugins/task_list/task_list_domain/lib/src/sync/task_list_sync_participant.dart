import 'package:core_sync/core_sync.dart';

import 'task_list_codec.dart';
import 'task_list_resolver.dart';
import 'task_list_sync_store.dart';

/// La lista de tareas en la sincronización (spec §10.4.5). Trabaja sobre el
/// contrato del almacén, así que sirve con cualquier implementación.
///
/// [applyRemote] fusiona los cambios en las copias sincronizadas, calcula con
/// [TaskListResolver] lo que debe leer la app y lo guarda con
/// [TaskListSyncStore.commitSync]. Por ahora no hay conflictos que resolver.
class TaskListSyncParticipant implements SyncParticipant {
  TaskListSyncParticipant({required TaskListSyncStore store, TaskListResolver resolver = const TaskListResolver()})
      : _store = store,
        _resolver = resolver;

  final TaskListSyncStore _store;
  final TaskListResolver _resolver;

  @override
  Set<String> get collections => TaskListCollections.all;

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async {
    final Map<String, Map<String, SyncedEntity>> copies = <String, Map<String, SyncedEntity>>{
      for (final String collection in TaskListCollections.all) collection: await _load(collection),
    };
    final TaskSyncView before = _resolve(copies);
    final Map<String, SyncedEntity> changed = <String, SyncedEntity>{};
    for (final ChangeRecord record in records) {
      final Map<String, SyncedEntity> entities = copies[record.collection]!;
      final SyncedEntity current =
          entities[record.entityId] ?? SyncedEntity(collection: record.collection, id: record.entityId);
      final SyncedEntity merged = current.merge(record);
      if (merged != current) {
        entities[record.entityId] = merged;
        changed['${record.collection}|${record.entityId}'] = merged;
      }
    }
    final TaskSyncView after = _resolve(copies);
    final TaskListSyncCommit commit = TaskListSyncCommit(
      entities: changed.values.toList(),
      tasks: _changes(before.tasks, after.tasks),
      categories: _changes(before.categories, after.categories),
    );
    if (!commit.isEmpty) {
      await _store.commitSync(commit);
    }
    return const <SyncConflict>[];
  }

  /// La lista de tareas aún no produce conflictos.
  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {}

  TaskSyncView _resolve(Map<String, Map<String, SyncedEntity>> copies) => _resolver.resolve(
        copies[TaskListCollections.tasks]!.values,
        copies[TaskListCollections.categories]!.values,
      );

  static List<TaskResolved<T>> _changes<T>(Map<String, TaskResolved<T>> before, Map<String, TaskResolved<T>> after) =>
      <TaskResolved<T>>[
        for (final MapEntry<String, TaskResolved<T>>(:String key, :TaskResolved<T> value) in after.entries)
          if (before[key] != value) value,
      ];

  Future<Map<String, SyncedEntity>> _load(String collection) async => <String, SyncedEntity>{
        for (final SyncedEntity entity in await _store.syncedEntities(collection)) entity.id: entity,
      };
}
