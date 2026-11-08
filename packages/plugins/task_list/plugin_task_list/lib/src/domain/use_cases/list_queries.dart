import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:task_list_domain/task_list_domain.dart';

/// La lista en un momento: categorías ordenadas, tareas con su estado y el
/// día local de ese momento.
class TaskListSnapshot extends Equatable {
  const TaskListSnapshot({required this.categories, required this.entries, required this.today});

  final List<TaskCategory> categories;
  final List<TaskListEntry> entries;

  /// El día local en que se calculó (medianoche UTC de esa fecha).
  final DateTime today;

  TaskListSummary get summary => TaskListView.summary(entries);

  @override
  List<Object?> get props => <Object?>[categories, entries, today];
}

/// Tareas y categorías juntas, al suscribirse y cada vez que cambia algo. El
/// estado de cada tarea se calcula con la hora del momento en que se emite.
///
/// `combineLatest2` espera a que terminen las cancelaciones al cancelar, así
/// que en `testWidgets` no hay que usar `first` sobre este stream: con el
/// reloj simulado no termina. Para leer una vez, usar el repositorio.
class WatchTaskList {
  const WatchTaskList(this._repository, this._clock);

  final TaskListRepository _repository;
  final Clock _clock;

  Stream<TaskListSnapshot> call() => Rx.combineLatest2(
        _repository.watchTasks(),
        _repository.watchCategories(),
        (List<HouseholdTask> tasks, List<TaskCategory> categories) {
          final DateTime now = _clock.nowUtc();
          final DateTime today = _clock.today();
          return TaskListSnapshot(
            categories: ListCategories.sorted(categories),
            entries: TaskListView.entries(tasks, categories, now: now, today: today),
            today: today,
          );
        },
      );
}

class WatchTaskCategories {
  const WatchTaskCategories(this._repository);

  final TaskListRepository _repository;

  Stream<List<TaskCategory>> call() => _repository.watchCategories();
}
