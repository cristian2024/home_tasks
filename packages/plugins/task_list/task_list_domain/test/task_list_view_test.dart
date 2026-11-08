import 'package:task_list_domain/task_list_domain.dart';
import 'package:test/test.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 1, 9);
  final DateTime today = DateTime.utc(2026, 11, 7);
  final DateTime now = DateTime.utc(2026, 11, 7, 12);
  const TaskCategory cleaning = TaskCategory(id: 'c1', sortOrder: 0, defaultKey: 'cleaning');
  const TaskCategory kitchen = TaskCategory(id: 'c2', sortOrder: 1, defaultKey: 'kitchen');

  HouseholdTask task(
    String id, {
    String? title,
    Urgency urgency = Urgency.normal,
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
    Recurrence? recurrence,
    DateTime? lastDoneAt,
    List<String> categoryIds = const <String>[],
  }) =>
      HouseholdTask(
        id: id,
        title: title ?? id,
        urgency: urgency,
        status: status,
        dueDate: dueDate,
        recurrence: recurrence,
        lastDoneAt: lastDoneAt,
        categoryIds: categoryIds,
        createdAt: t0,
        updatedAt: t0,
      );

  final List<HouseholdTask> tasks = <HouseholdTask>[
    task('filtro', urgency: Urgency.high, dueDate: DateTime.utc(2026, 11, 3), categoryIds: <String>['c1']),
    task('admin', dueDate: DateTime.utc(2026, 11, 5)),
    task('basura', urgency: Urgency.immediate, dueDate: today, categoryIds: <String>['c2', 'c1']),
    task('nevera', recurrence: Recurrence.between(10, 14), categoryIds: <String>['c2']),
    task('plantas', dueDate: DateTime.utc(2026, 11, 8)),
    task('extintor', recurrence: Recurrence.fixed(30), lastDoneAt: DateTime.utc(2026, 10, 21, 12)),
    task('persiana'),
    task('horno', status: TaskStatus.done, lastDoneAt: DateTime.utc(2026, 11, 6)),
    task('ventanas', status: TaskStatus.done, lastDoneAt: DateTime.utc(2026, 11, 7)),
  ];
  final List<TaskListEntry> entries =
      TaskListView.entries(tasks, <TaskCategory>[kitchen, cleaning], now: now, today: today);
  List<String> ids(List<TaskListEntry> entries) => <String>[for (final TaskListEntry entry in entries) entry.task.id];

  test('une cada tarea con su estado y sus categorías ordenadas', () {
    final TaskListEntry trash = entries.firstWhere((TaskListEntry entry) => entry.task.id == 'basura');

    expect(trash.state, TaskState.today);
    expect(trash.categories, <TaskCategory>[cleaning, kitchen]);
    expect(trash.primaryCategory, cleaning);
    expect(entries.firstWhere((TaskListEntry entry) => entry.task.id == 'persiana').primaryCategory, isNull);
  });

  test('agrupa por fecha: atrasadas, hoy, próximas (con las que esperan) y sin fecha', () {
    final List<TaskGroup> groups = TaskListView.group(entries, TaskGrouping.date);

    expect(groups.map((TaskGroup group) => group.dateGroup),
        <TaskDateGroup>[TaskDateGroup.overdue, TaskDateGroup.today, TaskDateGroup.upcoming, TaskDateGroup.noDate]);
    expect(ids(groups[0].entries), <String>['filtro', 'admin']);
    expect(ids(groups[1].entries), <String>['basura', 'nevera']);
    expect(ids(groups[2].entries), <String>['plantas', 'extintor']);
    expect(ids(groups[3].entries), <String>['persiana']);
  });

  test('agrupa por categoría: cada tarea bajo la primera, y sin categoría al final', () {
    final List<TaskGroup> groups = TaskListView.group(entries, TaskGrouping.category);

    expect(groups.map((TaskGroup group) => group.category), <TaskCategory?>[cleaning, kitchen, null]);
    expect(ids(groups[0].entries), <String>['basura', 'filtro']);
    expect(ids(groups[1].entries), <String>['nevera']);
    expect(ids(groups[2].entries), <String>['admin', 'plantas', 'extintor', 'persiana']);
  });

  test('ordena por urgencia, después por fecha (sin fecha al final) y por título', () {
    final TaskListEntry a = TaskListEntry(task: task('a', title: 'B', dueDate: today), state: TaskState.today);
    final TaskListEntry b = TaskListEntry(task: task('c', title: 'A'), state: TaskState.noDate);
    final TaskListEntry c = TaskListEntry(task: task('c', title: 'a'), state: TaskState.noDate);
    final TaskListEntry d = TaskListEntry(task: task('d', title: 'a'), state: TaskState.noDate);

    expect(TaskListView.compare(a, b), lessThan(0));
    expect(TaskListView.compare(b, a), greaterThan(0));
    expect(TaskListView.compare(b, c), 0, reason: 'el título no distingue mayúsculas');
    expect(TaskListView.compare(c, d), lessThan(0), reason: 'a igual título, por id');
  });

  test('una repetida en espera se ordena por el día en que vuelve', () {
    final TaskListEntry waiting = entries.firstWhere((TaskListEntry entry) => entry.task.id == 'extintor');

    expect(waiting.state, TaskState.waiting);
    expect(waiting.sortDate, waiting.task.returnsOn);
  });

  test('las hechas van de la más reciente a la más antigua', () {
    expect(ids(TaskListView.done(entries)), <String>['ventanas', 'horno']);
  });

  test('el resumen cuenta lo por hacer, lo atrasado, lo urgente y lo hecho', () {
    expect(TaskListView.summary(entries), const TaskListSummary(toDo: 6, overdue: 2, urgent: 2, done: 2));
  });

  group('TaskListFilter', () {
    test('vacío no filtra', () {
      const TaskListFilter filter = TaskListFilter();

      expect(filter.isEmpty, isTrue);
      expect(entries.every(filter.matches), isTrue);
    });

    test('filtra por categoría, sin categoría, urgencia y estado', () {
      List<String> matching(TaskListFilter filter) => ids(entries.where(filter.matches).toList());

      expect(matching(const TaskListFilter(categoryIds: <String>{'c2'})), <String>['basura', 'nevera']);
      expect(
        matching(const TaskListFilter(includeUncategorized: true)),
        <String>['admin', 'plantas', 'extintor', 'persiana', 'horno', 'ventanas'],
      );
      expect(matching(const TaskListFilter(urgencies: <Urgency>{Urgency.immediate})), <String>['basura']);
      expect(matching(const TaskListFilter(states: <TaskState>{TaskState.waiting})), <String>['extintor']);
    });

    test('copyWith cambia lo indicado', () {
      const TaskListFilter filter = TaskListFilter();

      expect(
        filter.copyWith(
          categoryIds: <String>{'c1'},
          includeUncategorized: true,
          urgencies: <Urgency>{Urgency.low},
          states: <TaskState>{TaskState.overdue},
        ),
        const TaskListFilter(
          categoryIds: <String>{'c1'},
          includeUncategorized: true,
          urgencies: <Urgency>{Urgency.low},
          states: <TaskState>{TaskState.overdue},
        ),
      );
      expect(filter.copyWith(), filter);
      expect(TaskListFilter.filterableStates, <TaskState>[TaskState.overdue, TaskState.waiting, TaskState.noDate]);
    });
  });

  test('el grupo por fecha de cada estado', () {
    expect(TaskDateGroup.of(TaskState.waiting), TaskDateGroup.upcoming);
    expect(TaskDateGroup.of(TaskState.done), isNull);
  });

  test('entradas y grupos se comparan por valor', () {
    final List<TaskGroup> groups = TaskListView.group(entries, TaskGrouping.date);

    expect(TaskListView.group(entries, TaskGrouping.date), groups);
    expect(entries.first, TaskListView.entries(tasks, <TaskCategory>[kitchen, cleaning], now: now, today: today).first);
  });
}
