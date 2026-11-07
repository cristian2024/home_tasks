import 'package:core_utils/core_utils.dart';
import 'package:task_list_domain/task_list_domain.dart';

/// Crea una tarea pendiente. Valida el título y que sus categorías existan.
/// Una tarea que se repite no guarda fecha.
class CreateTask {
  const CreateTask(this._repository, this._ids, this._clock);

  final TaskListRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  Future<HouseholdTask> call({
    required String title,
    Urgency urgency = Urgency.normal,
    List<String> categoryIds = const <String>[],
    DateTime? dueDate,
    Recurrence? recurrence,
  }) async {
    final DateTime now = _clock.nowUtc();
    final HouseholdTask task = HouseholdTask(
      id: _ids.newId(),
      title: TaskValidator.title(title),
      urgency: urgency,
      status: TaskStatus.pending,
      categoryIds: await checkCategories(_repository, categoryIds),
      dueDate: recurrence == null && dueDate != null ? CalendarDay.of(dueDate) : null,
      recurrence: recurrence,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveTask(task);
    return task;
  }
}

/// [categoryIds] sin repetir. Lanza [TaskCategoryNotFoundException] si
/// alguna no existe.
Future<List<String>> checkCategories(TaskListRepository repository, List<String> categoryIds) async {
  final Set<String> unique = categoryIds.toSet();
  if (unique.isEmpty) {
    return const <String>[];
  }
  final Set<String> existing = <String>{
    for (final TaskCategory category in await repository.getCategories()) category.id,
  };
  for (final String id in unique) {
    if (!existing.contains(id)) {
      throw TaskCategoryNotFoundException(id);
    }
  }
  return List<String>.unmodifiable(unique);
}

/// Edita una tarea. Si pasa a repetirse, pierde la fecha. Si nada cambia no
/// escribe.
class UpdateTask {
  const UpdateTask(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<HouseholdTask> call(
    String taskId, {
    String? title,
    Urgency? urgency,
    List<String>? categoryIds,
    DateTime? Function()? dueDate,
    Recurrence? Function()? recurrence,
  }) async {
    final HouseholdTask current = await getTask(_repository, taskId);
    final Recurrence? newRecurrence = recurrence == null ? current.recurrence : recurrence();
    final DateTime? requestedDate = dueDate == null ? current.dueDate : dueDate();
    final HouseholdTask changed = current.copyWith(
      title: title == null ? null : TaskValidator.title(title),
      urgency: urgency,
      categoryIds: categoryIds == null ? null : await checkCategories(_repository, categoryIds),
      dueDate: () => newRecurrence == null && requestedDate != null ? CalendarDay.of(requestedDate) : null,
      recurrence: () => newRecurrence,
    );
    if (changed == current) {
      return current;
    }
    final HouseholdTask updated = changed.copyWith(updatedAt: _clock.nowUtc());
    await _repository.saveTask(updated);
    return updated;
  }
}

/// La tarea [taskId]. Lanza [TaskNotFoundException] si no existe.
Future<HouseholdTask> getTask(TaskListRepository repository, String taskId) async =>
    await repository.getTask(taskId) ?? (throw TaskNotFoundException(taskId));

class GetTask {
  const GetTask(this._repository);

  final TaskListRepository _repository;

  /// Lanza [TaskNotFoundException] si no existe.
  Future<HouseholdTask> call(String taskId) => getTask(_repository, taskId);
}

class DeleteTasks {
  const DeleteTasks(this._repository, [this._clock = const SystemClock()]);

  final TaskListRepository _repository;
  final Clock _clock;

  Future<void> call(List<String> taskIds) => _repository.deleteTasks(taskIds, deletedAt: _clock.nowUtc());
}
