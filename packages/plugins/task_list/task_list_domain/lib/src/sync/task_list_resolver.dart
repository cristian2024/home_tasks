import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';
import 'task_list_codec.dart';

/// Una tarea o una categoría tal como la lee la app: activa o, si no, con el
/// momento desde el que no se muestra.
class TaskResolved<T> extends Equatable {
  const TaskResolved(this.entity, {this.deletedAt});

  final T entity;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => <Object?>[entity, deletedAt];
}

/// Resultado de [TaskListResolver.resolve].
class TaskSyncView extends Equatable {
  TaskSyncView({
    required Map<String, TaskResolved<HouseholdTask>> tasks,
    required Map<String, TaskResolved<TaskCategory>> categories,
  })  : tasks = Map<String, TaskResolved<HouseholdTask>>.unmodifiable(tasks),
        categories = Map<String, TaskResolved<TaskCategory>>.unmodifiable(categories);

  /// Entidades completas, por id.
  final Map<String, TaskResolved<HouseholdTask>> tasks;
  final Map<String, TaskResolved<TaskCategory>> categories;

  @override
  List<Object?> get props => <Object?>[tasks, categories];
}

/// Calcula, a partir de las copias sincronizadas, lo que lee la app (spec
/// §10.4.4). Es una función pura del estado: todos los dispositivos llegan al
/// mismo resultado, sin importar en qué orden recibieron los cambios.
///
/// Por ahora no produce conflictos: cada campo se queda con el último cambio
/// (por `hlc`) y un borrado gana a una edición.
///
/// - **Completar en dos dispositivos** escribe los mismos campos: cuenta una
///   vez.
/// - **Categorías por defecto repetidas** (las sembró cada dispositivo): de
///   las que tienen la misma `defaultKey` queda la de id menor. Las demás no
///   se muestran y sus tareas pasan a la que queda.
/// - **Categoría borrada** mientras otro la añade a una tarea: la referencia
///   se ignora.
class TaskListResolver {
  const TaskListResolver();

  TaskSyncView resolve(Iterable<SyncedEntity> tasks, Iterable<SyncedEntity> categories) {
    final Map<String, String> aliases = <String, String>{};
    final Map<String, TaskResolved<TaskCategory>> resolvedCategories = _categories(categories, aliases);
    return TaskSyncView(
      tasks: <String, TaskResolved<HouseholdTask>>{
        for (final SyncedEntity entity in tasks)
          if (TaskListCodec.taskOf(entity) case final HouseholdTask task)
            entity.id: TaskResolved<HouseholdTask>(
              task.copyWith(categoryIds: _categoryIds(task, aliases, resolvedCategories)),
              deletedAt: TaskListCodec.deletedAtOf(entity),
            ),
      },
      categories: resolvedCategories,
    );
  }

  /// Las categorías completas. Apunta en [aliases] las repetidas por
  /// `defaultKey` y la que queda en su lugar.
  Map<String, TaskResolved<TaskCategory>> _categories(Iterable<SyncedEntity> entities, Map<String, String> aliases) {
    final List<(TaskCategory, SyncedEntity)> complete = <(TaskCategory, SyncedEntity)>[
      for (final SyncedEntity entity in entities)
        if (TaskListCodec.categoryOf(entity) case final TaskCategory category) (category, entity),
    ]..sort(((TaskCategory, SyncedEntity) a, (TaskCategory, SyncedEntity) b) => a.$1.id.compareTo(b.$1.id));
    final Map<String, String> kept = <String, String>{};
    final Map<String, TaskResolved<TaskCategory>> resolved = <String, TaskResolved<TaskCategory>>{};
    for (final (TaskCategory category, SyncedEntity entity) in complete) {
      final String? defaultKey = category.defaultKey;
      final String canonical = defaultKey == null ? category.id : kept.putIfAbsent(defaultKey, () => category.id);
      if (canonical != category.id) {
        aliases[category.id] = canonical;
      }
      resolved[category.id] = TaskResolved<TaskCategory>(
        category,
        deletedAt: TaskListCodec.deletedAtOf(entity) ??
            (canonical == category.id ? null : _wallTime(entity.metadata.createdHlc)),
      );
    }
    return resolved;
  }

  /// Categorías de la tarea, ordenadas: las repetidas pasan a la que queda y
  /// las borradas se quitan. Las que aún no llegaron se conservan.
  static List<String> _categoryIds(
    HouseholdTask task,
    Map<String, String> aliases,
    Map<String, TaskResolved<TaskCategory>> categories,
  ) =>
      <String>{
        for (final String id in task.categoryIds)
          if (aliases[id] ?? id case final String effective when categories[effective]?.isDeleted != true) effective,
      }.toList()
        ..sort();

  static DateTime _wallTime(Hlc? hlc) => DateTime.fromMillisecondsSinceEpoch(hlc?.wallTime ?? 0, isUtc: true);
}
