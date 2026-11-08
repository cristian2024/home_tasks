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
    this.pinned,
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

  /// La tarea recién completada tal como estaba: se queda en su sitio,
  /// marcada, mientras dura el «Deshacer».
  final TaskListEntry? pinned;
  final Object? error;

  List<TaskListEntry> get filtered {
    final TaskListEntry? pinned = this.pinned;
    return <TaskListEntry>[
      for (final TaskListEntry entry in snapshot.entries)
        if (pinned != null && entry.task.id == pinned.task.id) pinned else entry,
    ].where(filter.matches).toList();
  }

  /// Si [entry] es la que se acaba de completar.
  bool isPinned(TaskListEntry entry) => pinned?.task.id == entry.task.id;

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
    TaskListEntry? Function()? pinned,
    Object? Function()? error,
  }) =>
      TaskListState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
        filter: filter ?? this.filter,
        grouping: grouping ?? this.grouping,
        showFilters: showFilters ?? this.showFilters,
        lastCompletion: lastCompletion == null ? this.lastCompletion : lastCompletion(),
        pinned: pinned == null ? this.pinned : pinned(),
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => <Object?>[status, snapshot, filter, grouping, showFilters, lastCompletion, pinned, error];
}

/// La lista con sus filtros y agrupación, y las acciones de completar. Una
/// tarea completada se queda en su sitio durante [undoDuration] y después va
/// a «Hechas» o, si se repite, a «Próximas».
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
  Timer? _settle;

  /// Cuánto se ofrece deshacer y se queda en su sitio una tarea completada.
  static const Duration undoDuration = Duration(seconds: 5);

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

  /// Completa una tarea por hacer, vuelve a pendiente una hecha y, si es la
  /// recién completada, lo deshace.
  Future<void> toggle(TaskListEntry entry) => _run(() async {
        if (state.isPinned(entry)) {
          await undoLastCompletion();
          return;
        }
        if (entry.state == TaskState.done) {
          await _reopenTask(entry.task.id);
          return;
        }
        final TaskCompletion? completion = await _completeTask(entry.task.id);
        if (completion == null) {
          return;
        }
        _settle?.cancel();
        _settle = Timer(undoDuration, settle);
        emit(state.copyWith(lastCompletion: () => completion, pinned: () => entry));
      });

  Future<void> undoLastCompletion() => _run(() async {
        final TaskCompletion? completion = state.lastCompletion;
        _settle?.cancel();
        if (completion != null) {
          emit(state.copyWith(lastCompletion: () => null, pinned: () => null));
          await _undoCompletion(completion);
        }
      });

  /// Termina el plazo para deshacer: la tarea completada deja su sitio.
  void settle() {
    _settle?.cancel();
    if (!isClosed) {
      emit(state.copyWith(lastCompletion: () => null, pinned: () => null));
    }
  }

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
    _settle?.cancel();
    return super.close();
  }
}
