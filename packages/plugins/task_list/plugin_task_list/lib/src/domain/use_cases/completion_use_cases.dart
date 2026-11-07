import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:task_list_domain/task_list_domain.dart';

import 'task_use_cases.dart';

/// Lo necesario para deshacer haber completado una tarea.
class TaskCompletion extends Equatable {
  const TaskCompletion({required this.previous, required this.completed});

  /// La tarea como estaba antes de completarla.
  final HouseholdTask previous;

  /// Como quedó: hecha o, si se repite, esperando su siguiente ventana.
  final HouseholdTask completed;

  @override
  List<Object?> get props => <Object?>[previous, completed];
}

/// Completa una tarea: una que no se repite pasa a hecha; una que se repite
/// sigue pendiente y espera su siguiente ventana. En las dos, la última vez
/// que se hizo pasa a ser ahora.
class CompleteTask {
  const CompleteTask(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  /// Devuelve `null` (sin escribir nada) si la tarea ya estaba hecha.
  Future<TaskCompletion?> call(String taskId) async {
    final HouseholdTask task = await getTask(_repository, taskId);
    if (task.status == TaskStatus.done) {
      return null;
    }
    final DateTime now = _clock.nowUtc();
    final HouseholdTask completed = task.copyWith(
      status: task.isRecurring ? TaskStatus.pending : TaskStatus.done,
      lastDoneAt: () => now,
      updatedAt: now,
    );
    await _repository.saveTask(completed);
    return TaskCompletion(previous: task, completed: completed);
  }
}

/// Deshace [CompleteTask]: la tarea vuelve a como estaba.
class UndoTaskCompletion {
  const UndoTaskCompletion(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<void> call(TaskCompletion completion) =>
      _repository.saveTask(completion.previous.copyWith(updatedAt: _clock.nowUtc()));
}

/// Vuelve a poner pendiente una tarea hecha. Conserva cuándo se hizo.
class ReopenTask {
  const ReopenTask(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<void> call(String taskId) async {
    final HouseholdTask task = await getTask(_repository, taskId);
    if (task.status == TaskStatus.pending) {
      return;
    }
    await _repository.saveTask(task.copyWith(status: TaskStatus.pending, updatedAt: _clock.nowUtc()));
  }
}

/// Borra las tareas hechas (las que se repiten nunca lo están). Devuelve
/// cuántas borró.
class ClearDoneTasks {
  const ClearDoneTasks(this._repository, [this._clock = const SystemClock()]);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<int> call() async {
    final List<String> ids = <String>[
      for (final HouseholdTask task in await _repository.getTasks())
        if (task.status == TaskStatus.done) task.id,
    ];
    if (ids.isNotEmpty) {
      await _repository.deleteTasks(ids, deletedAt: _clock.nowUtc());
    }
    return ids.length;
  }
}
