import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../domain/use_cases/completion_use_cases.dart';
import '../../domain/use_cases/list_queries.dart';

enum TaskListStatus { loading, ready, failed }

class TaskListState extends Equatable {
  TaskListState({
    this.status = TaskListStatus.loading,
    TaskListSnapshot? snapshot,
    this.filter = const TaskListFilter(),
    this.grouping = TaskGrouping.date,
    this.showFilters = false,
    this.lastCompletion,
    this.error,
  }) : snapshot = snapshot ??
            TaskListSnapshot(categories: const <TaskCategory>[], entries: const <TaskListEntry>[], today: DateTime.utc(1970));

  final TaskListStatus status;
  final TaskListSnapshot snapshot;
  final TaskListFilter filter;
  final TaskGrouping grouping;

  /// Si se ve el panel de filtros y agrupación.
  final bool showFilters;

  /// La última tarea completada, para ofrecer deshacerlo.
  final TaskCompletion? lastCompletion;
  final Object? error;

  List<TaskListEntry> get filtered => snapshot.entries.where(filter.matches).toList();

  /// Los grupos de lo por hacer y en espera, filtrados.
  List<TaskGroup> get groups => TaskListView.group(filtered, grouping);

  /// Las hechas, de la más reciente a la más antigua.
  List<TaskListEntry> get done => TaskListView.done(snapshot.entries);

  /// Si hay tareas por hacer o en espera, sin filtrar.
  bool get hasPending => snapshot.entries.any((TaskListEntry entry) => entry.state != TaskState.done);

  /// Si los filtros o la agrupación cambian lo que se ve por defecto.
  bool get isCustomized => !filter.isEmpty || grouping != TaskGrouping.date;

  TaskListState copyWith({
    TaskListStatus? status,
    TaskListSnapshot? snapshot,
    TaskListFilter? filter,
    TaskGrouping? grouping,
    bool? showFilters,
    TaskCompletion? Function()? lastCompletion,
    Object? Function()? error,
  }) =>
      TaskListState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
        filter: filter ?? this.filter,
        grouping: grouping ?? this.grouping,
        showFilters: showFilters ?? this.showFilters,
        lastCompletion: lastCompletion == null ? this.lastCompletion : lastCompletion(),
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => <Object?>[status, snapshot, filter, grouping, showFilters, lastCompletion, error];
}

/// La lista con sus filtros y agrupación, y las acciones de completar.
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit({
    required WatchTaskList watchList,
    required CompleteTask completeTask,
    required UndoTaskCompletion undoCompletion,
    required ReopenTask reopenTask,
    required ClearDoneTasks clearDone,
  })  : _watchList = watchList,
        _completeTask = completeTask,
        _undoCompletion = undoCompletion,
        _reopenTask = reopenTask,
        _clearDone = clearDone,
        super(TaskListState()) {
    _listen();
  }

  final WatchTaskList _watchList;
  final CompleteTask _completeTask;
  final UndoTaskCompletion _undoCompletion;
  final ReopenTask _reopenTask;
  final ClearDoneTasks _clearDone;
  StreamSubscription<TaskListSnapshot>? _subscription;

  void _listen() {
    unawaited(_subscription?.cancel());
    _subscription = _watchList().listen(
      (TaskListSnapshot snapshot) => emit(state.copyWith(status: TaskListStatus.ready, snapshot: snapshot)),
      onError: (Object _) => emit(state.copyWith(status: TaskListStatus.failed)),
    );
  }

  /// Vuelve a cargar tras un error.
  void retry() {
    emit(state.copyWith(status: TaskListStatus.loading));
    _listen();
  }

  void setFilter(TaskListFilter filter) => emit(state.copyWith(filter: filter));

  void setGrouping(TaskGrouping grouping) => emit(state.copyWith(grouping: grouping));

  void toggleFilters() => emit(state.copyWith(showFilters: !state.showFilters));

  /// Completa una tarea por hacer, o vuelve a pendiente una hecha.
  Future<void> toggle(TaskListEntry entry) => _run(() async {
        if (entry.state == TaskState.done) {
          await _reopenTask(entry.task.id);
          emit(state.copyWith(lastCompletion: () => null));
          return;
        }
        final TaskCompletion? completion = await _completeTask(entry.task.id);
        emit(state.copyWith(lastCompletion: () => completion));
      });

  Future<void> undoLastCompletion() => _run(() async {
        final TaskCompletion? completion = state.lastCompletion;
        if (completion != null) {
          emit(state.copyWith(lastCompletion: () => null));
          await _undoCompletion(completion);
        }
      });

  /// Devuelve cuántas borró.
  Future<int> clearDone() async {
    try {
      return await _clearDone();
    } on Object catch (error) {
      emit(state.copyWith(error: () => error));
      return 0;
    }
  }

  void clearError() => emit(state.copyWith(error: () => null));

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      emit(state.copyWith(error: () => error));
    }
  }

  @override
  Future<void> close() {
    // Sin await: ver «Handlers de bloc» en CLAUDE.md.
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
