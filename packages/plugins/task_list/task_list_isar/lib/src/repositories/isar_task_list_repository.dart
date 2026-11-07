import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:storage_isar/adapter.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../datasources/task_local_data_source.dart';
import '../mappers/task_data_mapper.dart';
import '../models/isar_task.dart';
import '../models/isar_task_category.dart';
import '../sync/isar_task_list_sync.dart';

/// [TaskListRepository] sobre Isar. Pasa `taskListRepositoryContract`.
///
/// Con [services] se sincroniza si la app compuso la sincronización (ver
/// [IsarTaskListSync]): registra cada escritura en la misma transacción y,
/// como [TaskListSyncStore], sirve a `TaskListSyncParticipant`. Pasa
/// `taskListSyncContract`.
class IsarTaskListRepository implements TaskListRepository, TaskListSyncStore {
  factory IsarTaskListRepository(Isar isar, {ServiceLocator? services}) =>
      IsarTaskListRepository._(IsarTaskListSync(isar, services), isar);

  IsarTaskListRepository._(this._sync, Isar isar) : _source = TaskLocalDataSource(isar, _sync);

  final TaskLocalDataSource _source;
  final IsarTaskListSync _sync;

  @override
  Future<List<SyncedEntity>> syncedEntities(String collection) => _sync.syncedEntities(collection);

  @override
  Future<void> commitSync(TaskListSyncCommit commit) => _sync.commit(commit);

  @override
  Future<void> saveTask(HouseholdTask task) => _source.putTask(TaskDataMapper.toIsarTask(task));

  @override
  Future<HouseholdTask?> getTask(String id) async {
    final IsarTask? model = await _source.getTask(id);
    return model == null ? null : TaskDataMapper.fromIsarTask(model);
  }

  @override
  Future<List<HouseholdTask>> getTasks() async => _tasks(await _source.getTasks());

  @override
  Stream<List<HouseholdTask>> watchTasks() => _source.watchTasks().map(_tasks);

  @override
  Future<void> deleteTasks(List<String> ids, {required DateTime deletedAt}) =>
      _source.deleteTasks(ids, deletedAt.toUtc());

  @override
  Future<void> saveCategories(List<TaskCategory> categories) =>
      _source.putCategories(categories.map(TaskDataMapper.toIsarCategory).toList());

  @override
  Future<List<TaskCategory>> getCategories() async => _categories(await _source.getCategories());

  @override
  Stream<List<TaskCategory>> watchCategories() => _source.watchCategories().map(_categories);

  @override
  Future<void> deleteCategory(String id, {required DateTime updatedAt}) =>
      _source.deleteCategory(id, updatedAt.toUtc());

  @override
  Future<bool> seedDefaultCategories(List<TaskCategory> defaults) =>
      _source.seedCategories(defaults.map(TaskDataMapper.toIsarCategory).toList());

  static List<HouseholdTask> _tasks(List<IsarTask> models) => models.map(TaskDataMapper.fromIsarTask).toList();

  static List<TaskCategory> _categories(List<IsarTaskCategory> models) =>
      models.map(TaskDataMapper.fromIsarCategory).toList();
}
