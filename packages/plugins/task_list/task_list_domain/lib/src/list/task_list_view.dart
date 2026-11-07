import 'package:categories/categories.dart';
import 'package:equatable/equatable.dart';
import 'package:urgency/urgency.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';

/// Una tarea con su estado en un momento dado y sus categorías, ordenadas por
/// el orden de las categorías.
class TaskListEntry extends Equatable {
  const TaskListEntry({required this.task, required this.state, this.categories = const <TaskCategory>[]});

  final HouseholdTask task;
  final TaskState state;
  final List<TaskCategory> categories;

  /// La categoría bajo la que se agrupa; `null` si no tiene ninguna.
  TaskCategory? get primaryCategory => categories.isEmpty ? null : categories.first;

  /// El día que la ordena: su fecha límite o, si es repetida y espera, el día
  /// en que vuelve. `null` si no tiene ninguno.
  DateTime? get sortDate => task.dueDate ?? (state == TaskState.waiting ? task.returnsOn : null);

  @override
  List<Object?> get props => <Object?>[task, state, categories];
}

/// Qué tareas se muestran. Un criterio vacío no filtra.
class TaskListFilter extends Equatable {
  const TaskListFilter({
    this.categoryIds = const <String>{},
    this.includeUncategorized = false,
    this.urgencies = const <Urgency>{},
    this.states = const <TaskState>{},
  });

  /// Estados por los que se puede filtrar: los que se salen de lo normal.
  static const List<TaskState> filterableStates = <TaskState>[TaskState.overdue, TaskState.waiting, TaskState.noDate];

  /// Tareas con alguna de estas categorías.
  final Set<String> categoryIds;

  /// Incluye también las tareas sin categoría. Solo filtra por categoría si
  /// hay [categoryIds] o esto es `true`.
  final bool includeUncategorized;

  final Set<Urgency> urgencies;
  final Set<TaskState> states;

  bool get filtersByCategory => categoryIds.isNotEmpty || includeUncategorized;

  bool get isEmpty => !filtersByCategory && urgencies.isEmpty && states.isEmpty;

  bool matches(TaskListEntry entry) {
    if (filtersByCategory &&
        !entry.categories.any((TaskCategory category) => categoryIds.contains(category.id)) &&
        !(includeUncategorized && entry.categories.isEmpty)) {
      return false;
    }
    if (urgencies.isNotEmpty && !urgencies.contains(entry.task.urgency)) {
      return false;
    }
    return states.isEmpty || states.contains(entry.state);
  }

  TaskListFilter copyWith({
    Set<String>? categoryIds,
    bool? includeUncategorized,
    Set<Urgency>? urgencies,
    Set<TaskState>? states,
  }) =>
      TaskListFilter(
        categoryIds: categoryIds ?? this.categoryIds,
        includeUncategorized: includeUncategorized ?? this.includeUncategorized,
        urgencies: urgencies ?? this.urgencies,
        states: states ?? this.states,
      );

  @override
  List<Object?> get props => <Object?>[categoryIds, includeUncategorized, urgencies, states];
}

/// Cómo se agrupa la lista.
enum TaskGrouping { date, category }

/// Grupos de la agrupación por fecha, en su orden.
enum TaskDateGroup {
  overdue,
  today,
  upcoming,
  noDate;

  /// El grupo de una tarea por hacer o en espera; `null` si está hecha.
  static TaskDateGroup? of(TaskState state) => switch (state) {
        TaskState.overdue => TaskDateGroup.overdue,
        TaskState.today => TaskDateGroup.today,
        TaskState.upcoming || TaskState.waiting => TaskDateGroup.upcoming,
        TaskState.noDate => TaskDateGroup.noDate,
        TaskState.done => null,
      };
}

/// Un grupo de la lista: por fecha ([dateGroup]) o por categoría
/// ([category], `null` para «Sin categoría»).
class TaskGroup extends Equatable {
  const TaskGroup.date(TaskDateGroup this.dateGroup, this.entries) : category = null;

  const TaskGroup.category(this.category, this.entries) : dateGroup = null;

  final TaskDateGroup? dateGroup;
  final TaskCategory? category;
  final List<TaskListEntry> entries;

  @override
  List<Object?> get props => <Object?>[dateGroup, category, entries];
}

/// Lo que resume la tarjeta del inicio.
class TaskListSummary extends Equatable {
  const TaskListSummary({required this.toDo, required this.overdue, required this.urgent, required this.done});

  /// Por hacer: sin las que esperan ni las hechas.
  final int toDo;
  final int overdue;

  /// Por hacer con urgencia inmediata o alta.
  final int urgent;
  final int done;

  @override
  List<Object?> get props => <Object?>[toDo, overdue, urgent, done];
}

/// Une, ordena, filtra y agrupa las tareas. Funciones puras: la hora y el día
/// los da quien llama.
abstract final class TaskListView {
  /// Cada tarea con su estado en [now] ([today] es su día local) y sus
  /// categorías existentes, ordenadas.
  static List<TaskListEntry> entries(
    List<HouseholdTask> tasks,
    List<TaskCategory> categories, {
    required DateTime now,
    required DateTime today,
  }) {
    final List<TaskCategory> ordered = ListCategories.sorted(categories);
    return <TaskListEntry>[
      for (final HouseholdTask task in tasks)
        TaskListEntry(
          task: task,
          state: task.stateAt(now, today: today),
          categories: <TaskCategory>[
            for (final TaskCategory category in ordered)
              if (task.categoryIds.contains(category.id)) category,
          ],
        ),
    ];
  }

  /// Orden dentro de un grupo: lo más urgente, después lo que vence antes
  /// (sin fecha al final) y después por título.
  static int compare(TaskListEntry a, TaskListEntry b) {
    final int byUrgency = a.task.urgency.compareTo(b.task.urgency);
    if (byUrgency != 0) {
      return byUrgency;
    }
    final DateTime? aDate = a.sortDate;
    final DateTime? bDate = b.sortDate;
    if (aDate != bDate) {
      if (aDate == null || bDate == null) {
        return aDate == null ? 1 : -1;
      }
      return aDate.compareTo(bDate);
    }
    final int byTitle = a.task.title.toLowerCase().compareTo(b.task.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.task.id.compareTo(b.task.id);
  }

  /// Agrupa las tareas por hacer y en espera de [entries] (ya filtradas); las
  /// hechas se ignoran. Por fecha: Atrasadas, Hoy, Próximas (con las que
  /// esperan) y Sin fecha. Por categoría, cada tarea sale una sola vez, bajo
  /// su primera categoría, en el orden de las categorías y con «Sin
  /// categoría» al final. Solo hay grupos con tareas, ordenadas con [compare].
  static List<TaskGroup> group(List<TaskListEntry> entries, TaskGrouping grouping) {
    final List<TaskListEntry> pending =
        entries.where((TaskListEntry entry) => entry.state != TaskState.done).toList();
    switch (grouping) {
      case TaskGrouping.date:
        return <TaskGroup>[
          for (final TaskDateGroup group in TaskDateGroup.values)
            if (_sorted(pending.where((TaskListEntry entry) => TaskDateGroup.of(entry.state) == group))
                case final List<TaskListEntry> members when members.isNotEmpty)
              TaskGroup.date(group, members),
        ];
      case TaskGrouping.category:
        final Map<String, TaskCategory> categories = <String, TaskCategory>{
          for (final TaskListEntry entry in pending)
            if (entry.primaryCategory case final TaskCategory category) category.id: category,
        };
        final List<TaskListEntry> uncategorized =
            _sorted(pending.where((TaskListEntry entry) => entry.primaryCategory == null));
        return <TaskGroup>[
          for (final TaskCategory category in ListCategories.sorted(categories.values))
            TaskGroup.category(
              category,
              _sorted(pending.where((TaskListEntry entry) => entry.primaryCategory?.id == category.id)),
            ),
          if (uncategorized.isNotEmpty) TaskGroup.category(null, uncategorized),
        ];
    }
  }

  /// Las hechas, de la más reciente a la más antigua.
  static List<TaskListEntry> done(List<TaskListEntry> entries) =>
      entries.where((TaskListEntry entry) => entry.state == TaskState.done).toList()
        ..sort((TaskListEntry a, TaskListEntry b) {
          final int byDate = (b.task.lastDoneAt ?? b.task.updatedAt).compareTo(a.task.lastDoneAt ?? a.task.updatedAt);
          return byDate != 0 ? byDate : a.task.id.compareTo(b.task.id);
        });

  static TaskListSummary summary(List<TaskListEntry> entries) {
    final List<TaskListEntry> toDo = entries.where((TaskListEntry entry) => entry.state.isToDo).toList();
    return TaskListSummary(
      toDo: toDo.length,
      overdue: toDo.where((TaskListEntry entry) => entry.state == TaskState.overdue).length,
      urgent: toDo.where((TaskListEntry entry) => entry.task.urgency.isUrgent).length,
      done: entries.where((TaskListEntry entry) => entry.state == TaskState.done).length,
    );
  }

  static List<TaskListEntry> _sorted(Iterable<TaskListEntry> entries) => entries.toList()..sort(compare);
}
