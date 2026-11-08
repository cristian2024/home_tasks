import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../domain/use_cases/list_queries.dart';
import '../../domain/use_cases/task_use_cases.dart';

enum TaskFormStatus { loading, editing, submitting, saved, deleted }

enum RecurrenceMode { none, fixed, range }

/// Campo de días de la recurrencia.
enum RecurrenceField { every, min, max }

sealed class TaskFormError extends Equatable {
  const TaskFormError();
}

final class TaskFormValidationError extends TaskFormError {
  const TaskFormValidationError(this.error);

  final TaskValidationException error;

  @override
  List<Object?> get props => <Object?>[error.field, error.reason];
}

/// Un número de días que no se puede leer o fuera de 1..365.
final class TaskFormInvalidDays extends TaskFormError {
  const TaskFormInvalidDays(this.field);

  final RecurrenceField field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// El mínimo es mayor que el máximo.
final class TaskFormInvalidRange extends TaskFormError {
  const TaskFormInvalidRange();

  @override
  List<Object?> get props => <Object?>[];
}

/// Error no ligado a un campo (tarea borrada, categoría que ya no existe…).
final class TaskFormGeneralError extends TaskFormError {
  const TaskFormGeneralError(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}

class TaskFormState extends Equatable {
  const TaskFormState({
    this.status = TaskFormStatus.loading,
    this.title = '',
    this.dueDate,
    this.urgency = Urgency.normal,
    this.categoryIds = const <String>{},
    this.recurrenceMode = RecurrenceMode.none,
    this.everyDays = '',
    this.minDays = '',
    this.maxDays = '',
    this.lastDoneAt,
    this.categories = const <TaskCategory>[],
    this.error,
    this.savedTaskId,
  });

  final TaskFormStatus status;

  /// Valores iniciales de los campos de texto.
  final String title;
  final String everyDays;
  final String minDays;
  final String maxDays;

  /// Día límite elegido; `null` si no tiene.
  final DateTime? dueDate;
  final Urgency urgency;
  final Set<String> categoryIds;
  final RecurrenceMode recurrenceMode;

  /// Última vez que se hizo, al editar.
  final DateTime? lastDoneAt;
  final List<TaskCategory> categories;
  final TaskFormError? error;
  final String? savedTaskId;

  TaskFormState copyWith({
    TaskFormStatus? status,
    String? title,
    DateTime? Function()? dueDate,
    Urgency? urgency,
    Set<String>? categoryIds,
    RecurrenceMode? recurrenceMode,
    String? everyDays,
    String? minDays,
    String? maxDays,
    DateTime? lastDoneAt,
    List<TaskCategory>? categories,
    TaskFormError? Function()? error,
    String? savedTaskId,
  }) =>
      TaskFormState(
        status: status ?? this.status,
        title: title ?? this.title,
        dueDate: dueDate == null ? this.dueDate : dueDate(),
        urgency: urgency ?? this.urgency,
        categoryIds: categoryIds ?? this.categoryIds,
        recurrenceMode: recurrenceMode ?? this.recurrenceMode,
        everyDays: everyDays ?? this.everyDays,
        minDays: minDays ?? this.minDays,
        maxDays: maxDays ?? this.maxDays,
        lastDoneAt: lastDoneAt ?? this.lastDoneAt,
        categories: categories ?? this.categories,
        error: error == null ? this.error : error(),
        savedTaskId: savedTaskId ?? this.savedTaskId,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        title,
        dueDate,
        urgency,
        categoryIds,
        recurrenceMode,
        everyDays,
        minDays,
        maxDays,
        lastDoneAt,
        categories,
        error,
        savedTaskId,
      ];
}

/// Crear o editar una tarea.
class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit({
    required this.taskId,
    required GetTask getTask,
    required WatchTaskCategories watchCategories,
    required CreateTask createTask,
    required UpdateTask updateTask,
    required DeleteTasks deleteTasks,
  })  : _getTask = getTask,
        _createTask = createTask,
        _updateTask = updateTask,
        _deleteTasks = deleteTasks,
        super(const TaskFormState()) {
    _categories = watchCategories().listen(
      (List<TaskCategory> categories) => emit(state.copyWith(categories: categories)),
    );
    unawaited(_load());
  }

  /// `null` al crear.
  final String? taskId;
  final GetTask _getTask;
  final CreateTask _createTask;
  final UpdateTask _updateTask;
  final DeleteTasks _deleteTasks;
  late final StreamSubscription<List<TaskCategory>> _categories;

  bool get isEditing => taskId != null;

  Future<void> _load() async {
    final String? taskId = this.taskId;
    if (taskId == null) {
      emit(state.copyWith(status: TaskFormStatus.editing));
      return;
    }
    try {
      final HouseholdTask task = await _getTask(taskId);
      final Recurrence? recurrence = task.recurrence;
      emit(state.copyWith(
        status: TaskFormStatus.editing,
        title: task.title,
        dueDate: () => task.dueDate,
        urgency: task.urgency,
        categoryIds: task.categoryIds.toSet(),
        recurrenceMode: recurrence == null
            ? RecurrenceMode.none
            : (recurrence.isFixed ? RecurrenceMode.fixed : RecurrenceMode.range),
        everyDays: recurrence == null ? '' : '${recurrence.minDays}',
        minDays: recurrence == null ? '' : '${recurrence.minDays}',
        maxDays: recurrence == null ? '' : '${recurrence.maxDays}',
        lastDoneAt: task.lastDoneAt,
      ));
    } on Object catch (error) {
      emit(state.copyWith(status: TaskFormStatus.editing, error: () => TaskFormGeneralError(error)));
    }
  }

  void setDueDate(DateTime? dueDate) => emit(state.copyWith(dueDate: () => dueDate));

  void setUrgency(Urgency urgency) => emit(state.copyWith(urgency: urgency));

  void setCategories(Set<String> categoryIds) => emit(state.copyWith(categoryIds: categoryIds));

  /// Elegir que se repita oculta la fecha: se excluyen.
  void setRecurrenceMode(RecurrenceMode mode) => emit(state.copyWith(recurrenceMode: mode, error: () => null));

  Future<void> submit({
    required String title,
    String everyDays = '',
    String minDays = '',
    String maxDays = '',
  }) async {
    final Recurrence? recurrence;
    try {
      recurrence = _recurrence(everyDays, minDays, maxDays);
    } on TaskFormError catch (error) {
      emit(state.copyWith(error: () => error));
      return;
    }
    emit(state.copyWith(status: TaskFormStatus.submitting, error: () => null));
    try {
      final String? taskId = this.taskId;
      final List<String> categoryIds = <String>[
        for (final TaskCategory category in state.categories)
          if (state.categoryIds.contains(category.id)) category.id,
      ];
      final DateTime? dueDate = recurrence == null ? state.dueDate : null;
      final HouseholdTask task = taskId == null
          ? await _createTask(
              title: title,
              urgency: state.urgency,
              categoryIds: categoryIds,
              dueDate: dueDate,
              recurrence: recurrence,
            )
          : await _updateTask(
              taskId,
              title: title,
              urgency: state.urgency,
              categoryIds: categoryIds,
              dueDate: () => dueDate,
              recurrence: () => recurrence,
            );
      emit(state.copyWith(status: TaskFormStatus.saved, savedTaskId: task.id));
    } on TaskValidationException catch (error) {
      emit(state.copyWith(status: TaskFormStatus.editing, error: () => TaskFormValidationError(error)));
    } on Object catch (error) {
      emit(state.copyWith(status: TaskFormStatus.editing, error: () => TaskFormGeneralError(error)));
    }
  }

  Future<void> delete() async {
    final String? taskId = this.taskId;
    if (taskId == null) {
      return;
    }
    try {
      await _deleteTasks(<String>[taskId]);
      emit(state.copyWith(status: TaskFormStatus.deleted));
    } on Object catch (error) {
      emit(state.copyWith(error: () => TaskFormGeneralError(error)));
    }
  }

  Recurrence? _recurrence(String every, String min, String max) {
    int days(String text, RecurrenceField field) {
      final int? value = int.tryParse(text.trim());
      if (value == null || value < 1 || value > Recurrence.maxAllowedDays) {
        throw TaskFormInvalidDays(field);
      }
      return value;
    }

    switch (state.recurrenceMode) {
      case RecurrenceMode.none:
        return null;
      case RecurrenceMode.fixed:
        return Recurrence.fixed(days(every, RecurrenceField.every));
      case RecurrenceMode.range:
        final int minDays = days(min, RecurrenceField.min);
        final int maxDays = days(max, RecurrenceField.max);
        if (minDays > maxDays) {
          throw const TaskFormInvalidRange();
        }
        return Recurrence.between(minDays, maxDays);
    }
  }

  @override
  Future<void> close() {
    unawaited(_categories.cancel());
    return super.close();
  }
}
