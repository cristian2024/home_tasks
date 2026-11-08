/// Dobles de prueba y tests de contrato del dominio de la lista de tareas.
library;

import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import 'task_list_domain.dart';

export 'src/testing/task_list_repository_contract.dart';
export 'src/testing/task_list_sync_fixtures.dart';

/// [TaskListRepository] en memoria, para tests y apps de ejemplo. Cumple
/// `taskListRepositoryContract`.
///
/// Con [hlcClock] y [changeLog] además se sincroniza: cada escritura local
/// actualiza sus copias sincronizadas y añade sus registros al log, y como
/// [TaskListSyncStore] sirve a `TaskListSyncParticipant`. Pasa
/// `taskListSyncContract`.
class InMemoryTaskListRepository implements TaskListRepository, TaskListSyncStore {
  InMemoryTaskListRepository({HlcClock? hlcClock, ChangeLog? changeLog, IdGenerator ids = const UuidV4Generator()})
      : _recorder = hlcClock == null ? null : LocalSyncRecorder(hlcClock: hlcClock, ids: ids),
        _changeLog = changeLog;

  final LocalSyncRecorder? _recorder;
  final ChangeLog? _changeLog;
  final Map<String, SyncedEntity> _synced = <String, SyncedEntity>{};

  final Map<String, HouseholdTask> _tasks = <String, HouseholdTask>{};
  final Map<String, TaskCategory> _categories = <String, TaskCategory>{};

  /// IDs borrados (o que la sincronización no muestra) de cada colección.
  final Map<String, Set<String>> _deleted = <String, Set<String>>{
    for (final String collection in TaskListCollections.all) collection: <String>{},
  };
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  bool _seeded = false;

  @override
  Future<void> saveTask(HouseholdTask task) async {
    if (_isDeleted(TaskListCollections.tasks, task.id)) {
      return;
    }
    _tasks[task.id] = task;
    await _record(<LocalSyncWrite>[_taskWrite(task)]);
    _changed();
  }

  @override
  Future<HouseholdTask?> getTask(String id) async => _tasks[id];

  @override
  Future<List<HouseholdTask>> getTasks() async => _tasks.values.toList();

  @override
  Stream<List<HouseholdTask>> watchTasks() => _watch(() => _tasks.values.toList());

  @override
  Future<void> deleteTasks(List<String> ids, {required DateTime deletedAt}) async {
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[
      for (final String id in ids)
        if (_tasks.remove(id) != null) _deletion(TaskListCollections.tasks, id, deletedAt),
    ];
    await _record(writes);
    _changed();
  }

  @override
  Future<void> saveCategories(List<TaskCategory> categories) async {
    final List<TaskCategory> active = <TaskCategory>[
      for (final TaskCategory category in categories)
        if (!_isDeleted(TaskListCollections.categories, category.id)) category,
    ];
    for (final TaskCategory category in active) {
      _categories[category.id] = category;
    }
    await _record(active.map(_categoryWrite).toList());
    _changed();
  }

  @override
  Future<List<TaskCategory>> getCategories() async => _sortedCategories();

  @override
  Stream<List<TaskCategory>> watchCategories() => _watch(_sortedCategories);

  @override
  Future<void> deleteCategory(String id, {required DateTime updatedAt}) async {
    if (_categories.remove(id) == null) {
      return;
    }
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[_deletion(TaskListCollections.categories, id, updatedAt)];
    for (final HouseholdTask task in _tasks.values.toList()) {
      if (task.categoryIds.contains(id)) {
        final HouseholdTask updated = task.copyWith(
          categoryIds: <String>[for (final String categoryId in task.categoryIds) if (categoryId != id) categoryId],
          updatedAt: updatedAt,
        );
        _tasks[task.id] = updated;
        writes.add(_taskWrite(updated));
      }
    }
    await _record(writes);
    _changed();
  }

  @override
  Future<bool> seedDefaultCategories(List<TaskCategory> defaults) async {
    if (_seeded) {
      return false;
    }
    _seeded = true;
    await saveCategories(defaults);
    return true;
  }

  @override
  Future<List<SyncedEntity>> syncedEntities(String collection) async => <SyncedEntity>[
        for (final SyncedEntity entity in _synced.values)
          if (entity.collection == collection) entity,
      ];

  @override
  Future<void> commitSync(TaskListSyncCommit commit) async {
    for (final SyncedEntity entity in commit.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    _apply(TaskListCollections.tasks, commit.tasks, _tasks, (HouseholdTask task) => task.id);
    _apply(TaskListCollections.categories, commit.categories, _categories, (TaskCategory c) => c.id);
    _changed();
  }

  /// Libera los streams abiertos.
  Future<void> close() => _changes.close();

  void _apply<T>(String collection, List<TaskResolved<T>> resolved, Map<String, T> active, String Function(T) idOf) {
    for (final TaskResolved<T> entry in resolved) {
      final String id = idOf(entry.entity);
      if (entry.isDeleted) {
        active.remove(id);
        _deleted[collection]!.add(id);
      } else {
        active[id] = entry.entity;
        _deleted[collection]!.remove(id);
      }
    }
  }

  bool _isDeleted(String collection, String id) => _deleted[collection]!.contains(id);

  List<TaskCategory> _sortedCategories() => ListCategories.sorted(_categories.values);

  LocalSyncWrite _taskWrite(HouseholdTask task) =>
      _write(TaskListCollections.tasks, task.id, TaskListCodec.taskFields(task));

  LocalSyncWrite _categoryWrite(TaskCategory category) =>
      _write(TaskListCollections.categories, category.id, TaskListCodec.categoryFields(category));

  LocalSyncWrite _deletion(String collection, String id, DateTime deletedAt) {
    _deleted[collection]!.add(id);
    return _write(collection, id, TaskListCodec.deletion(deletedAt));
  }

  LocalSyncWrite _write(String collection, String id, Map<String, Object?> fields) =>
      LocalSyncWrite(collection: collection, id: id, fields: fields, current: _synced['$collection|$id']);

  /// Con sincronización, actualiza las copias y añade los registros al log.
  Future<void> _record(List<LocalSyncWrite> writes) async {
    final LocalSyncRecorder? recorder = _recorder;
    final ChangeLog? log = _changeLog;
    if (recorder == null || log == null || writes.isEmpty) {
      return;
    }
    final LocalSyncChanges changes = recorder.record(writes, nextSeq: (await log.vector())[recorder.deviceId] + 1);
    for (final SyncedEntity entity in changes.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    await log.append(changes.records);
  }

  void _changed() => _changes.add(null);

  /// Emite [read] al suscribirse y con cada cambio. El valor inicial se emite
  /// en `onListen`, así que no se pierde una escritura hecha justo después de
  /// suscribirse.
  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
      },
      // No devuelve el futuro de cancel(): `first` lo esperaría y, con el
      // reloj simulado de testWidgets, no se completa.
      onCancel: () {
        unawaited(changes?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }
}
