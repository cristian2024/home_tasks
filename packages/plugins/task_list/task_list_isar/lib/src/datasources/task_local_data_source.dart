import 'package:storage_isar/adapter.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../models/isar_task.dart';
import '../models/isar_task_category.dart';
import '../models/isar_task_list_flag.dart';
import '../sync/isar_task_list_sync.dart';

/// Acceso a las colecciones Isar de la lista de tareas. Toda escritura va en
/// una transacción explícita (spec §10.1). Los borrados son lógicos
/// (`deletedAt`) y las lecturas solo devuelven lo activo. Con
/// [IsarTaskListSync], cada escritura registra sus cambios en esa misma
/// transacción.
class TaskLocalDataSource {
  TaskLocalDataSource(this._isar, [this._sync]);

  /// Marca de que ya se crearon las categorías por defecto.
  static const String defaultsSeededFlag = 'defaultCategoriesSeeded';

  final Isar _isar;
  final IsarTaskListSync? _sync;

  IsarCollection<IsarTask> get _tasks => _isar.isarTasks;
  IsarCollection<IsarTaskCategory> get _categories => _isar.isarTaskCategorys;
  IsarCollection<IsarTaskListFlag> get _flags => _isar.isarTaskListFlags;

  /// Guarda la tarea, salvo que esté borrada.
  Future<void> putTask(IsarTask task) => _write(() async {
        if ((await _tasks.getById(task.id))?.deletedAt != null) {
          return const <TaskSyncWrite>[];
        }
        await _tasks.putById(task);
        return <TaskSyncWrite>[IsarTaskListSync.task(task)];
      });

  Future<IsarTask?> getTask(String id) async {
    final IsarTask? task = await _tasks.getById(id);
    return task?.deletedAt == null ? task : null;
  }

  Future<List<IsarTask>> getTasks() => _tasks.filter().deletedAtIsNull().findAll();

  Stream<List<IsarTask>> watchTasks() => _tasks.filter().deletedAtIsNull().watch(fireImmediately: true);

  /// Borra las tareas activas en [deletedAt], en una sola transacción.
  Future<void> deleteTasks(List<String> ids, DateTime deletedAt) => _write(() async {
        final List<TaskSyncWrite> writes = <TaskSyncWrite>[];
        for (final String id in ids) {
          final IsarTask? task = await getTask(id);
          if (task == null) {
            continue;
          }
          await _tasks.putById(task..deletedAt = deletedAt);
          writes.add(IsarTaskListSync.deletion(TaskListCollections.tasks, id, deletedAt));
        }
        return writes;
      });

  /// Guarda las categorías que no están borradas.
  Future<void> putCategories(List<IsarTaskCategory> categories) => _write(() => _putCategories(categories));

  Future<List<IsarTaskCategory>> getCategories() =>
      _categories.filter().deletedAtIsNull().sortBySortOrder().thenById().findAll();

  Stream<List<IsarTaskCategory>> watchCategories() =>
      _categories.filter().deletedAtIsNull().sortBySortOrder().thenById().watch(fireImmediately: true);

  /// Borra la categoría en [updatedAt] y la quita de sus tareas (con ese
  /// `updatedAt`) en una sola transacción. No hace nada si no existe.
  Future<void> deleteCategory(String id, DateTime updatedAt) => _write(() async {
        final IsarTaskCategory? category = await _categories.getById(id);
        if (category == null || category.deletedAt != null) {
          return const <TaskSyncWrite>[];
        }
        await _categories.putById(category..deletedAt = updatedAt);
        final List<IsarTask> tasks =
            await _tasks.where().categoryIdsElementEqualTo(id).filter().deletedAtIsNull().findAll();
        for (final IsarTask task in tasks) {
          task
            ..categoryIds = <String>[for (final String categoryId in task.categoryIds) if (categoryId != id) categoryId]
            ..updatedAt = updatedAt;
        }
        await _tasks.putAllById(tasks);
        return <TaskSyncWrite>[
          IsarTaskListSync.deletion(TaskListCollections.categories, id, updatedAt),
          ...tasks.map(IsarTaskListSync.task),
        ];
      });

  /// Guarda [categories] y la marca de categorías creadas, solo si la marca
  /// no existe. Devuelve si las guardó.
  Future<bool> seedCategories(List<IsarTaskCategory> categories) async {
    bool seeded = false;
    await _write(() async {
      if (await _flags.getByKey(defaultsSeededFlag) != null) {
        return const <TaskSyncWrite>[];
      }
      await _flags.putByKey(IsarTaskListFlag()..key = defaultsSeededFlag);
      seeded = true;
      return _putCategories(categories);
    });
    return seeded;
  }

  Future<List<TaskSyncWrite>> _putCategories(List<IsarTaskCategory> categories) async {
    final List<IsarTaskCategory> active = <IsarTaskCategory>[
      for (final IsarTaskCategory category in categories)
        if ((await _categories.getById(category.id))?.deletedAt == null) category,
    ];
    await _categories.putAllById(active);
    return active.map(IsarTaskListSync.category).toList();
  }

  /// Ejecuta [body] en una transacción de escritura y registra lo que
  /// devuelve.
  Future<void> _write(Future<List<TaskSyncWrite>> Function() body) => _isar.writeTxn(() async {
        await _sync?.prepare();
        await _sync?.record(await body());
      });
}
