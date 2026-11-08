import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';
import 'task_list_resolver.dart';

/// Lo que el participante escribe tras aplicar cambios recibidos: las copias
/// sincronizadas que cambiaron y lo que la app debe leer desde entonces.
class TaskListSyncCommit extends Equatable {
  TaskListSyncCommit({
    List<SyncedEntity> entities = const <SyncedEntity>[],
    List<TaskResolved<HouseholdTask>> tasks = const <TaskResolved<HouseholdTask>>[],
    List<TaskResolved<TaskCategory>> categories = const <TaskResolved<TaskCategory>>[],
  })  : entities = List<SyncedEntity>.unmodifiable(entities),
        tasks = List<TaskResolved<HouseholdTask>>.unmodifiable(tasks),
        categories = List<TaskResolved<TaskCategory>>.unmodifiable(categories);

  final List<SyncedEntity> entities;
  final List<TaskResolved<HouseholdTask>> tasks;
  final List<TaskResolved<TaskCategory>> categories;

  bool get isEmpty => entities.isEmpty && tasks.isEmpty && categories.isEmpty;

  @override
  List<Object?> get props => <Object?>[entities, tasks, categories];
}

/// Almacén de las copias sincronizadas de la lista de tareas. Lo implementa
/// cada repositorio junto a `TaskListRepository`.
///
/// Las escrituras locales del repositorio actualizan las copias y registran
/// sus cambios en la misma transacción. Las de [commitSync] no registran
/// nada: vienen de otro dispositivo.
abstract interface class TaskListSyncStore {
  /// Copias sincronizadas de [collection], también las borradas y las
  /// incompletas.
  Future<List<SyncedEntity>> syncedEntities(String collection);

  /// Guarda [commit] de forma atómica, sin registrar cambios: reemplaza las
  /// copias de `entities` y deja tareas y categorías como las leerá la app,
  /// activas o borradas.
  Future<void> commitSync(TaskListSyncCommit commit);
}
