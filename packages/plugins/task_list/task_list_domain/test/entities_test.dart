import 'package:task_list_domain/task_list_domain.dart';
import 'package:test/test.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 1, 18);
  final DateTime today = DateTime.utc(2026, 11, 7);
  final DateTime now = DateTime.utc(2026, 11, 7, 12);

  HouseholdTask task({
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
    Recurrence? recurrence,
    DateTime? lastDoneAt,
  }) =>
      HouseholdTask(
        id: 't1',
        title: 'Sacar la basura',
        urgency: Urgency.normal,
        status: status,
        dueDate: dueDate,
        recurrence: recurrence,
        lastDoneAt: lastDoneAt,
        createdAt: t0,
        updatedAt: t0,
      );

  group('HouseholdTask.stateAt', () {
    test('sin fecha ni recurrencia, está sin fecha o hecha', () {
      expect(task().stateAt(now, today: today), TaskState.noDate);
      expect(task(status: TaskStatus.done).stateAt(now, today: today), TaskState.done);
      expect(task().isRecurring, isFalse);
    });

    test('con fecha, compara el día con hoy', () {
      expect(task(dueDate: DateTime.utc(2026, 11, 6)).stateAt(now, today: today), TaskState.overdue);
      expect(task(dueDate: DateTime.utc(2026, 11, 7)).stateAt(now, today: today), TaskState.today);
      expect(task(dueDate: DateTime.utc(2026, 11, 8)).stateAt(now, today: today), TaskState.upcoming);
      expect(task(dueDate: DateTime.utc(2026, 11, 6), status: TaskStatus.done).stateAt(now, today: today), TaskState.done);
    });

    test('repetida, sigue su ventana y nunca queda hecha', () {
      final HouseholdTask fridge = task(recurrence: Recurrence.between(10, 14), lastDoneAt: t0);

      expect(fridge.isRecurring, isTrue);
      expect(fridge.stateAt(t0.add(const Duration(days: 9)), today: today), TaskState.waiting);
      expect(fridge.stateAt(t0.add(const Duration(days: 10)), today: today), TaskState.today);
      expect(fridge.stateAt(t0.add(const Duration(days: 16)), today: today), TaskState.overdue);
      expect(task(recurrence: Recurrence.fixed(7)).stateAt(now, today: today), TaskState.today);
    });

    test('solo lo que no espera ni está hecho es por hacer', () {
      expect(TaskState.values.where((TaskState state) => state.isToDo),
          <TaskState>[TaskState.overdue, TaskState.today, TaskState.upcoming, TaskState.noDate]);
    });
  });

  test('returnsOn es el día en que se abre la ventana de una repetida', () {
    final HouseholdTask extinguisher = task(recurrence: Recurrence.fixed(30), lastDoneAt: DateTime.utc(2026, 10, 21, 12));

    expect(extinguisher.returnsOn, CalendarDay.localDayOf(DateTime.utc(2026, 11, 20, 12)));
    expect(task(recurrence: Recurrence.fixed(30)).returnsOn, isNull);
    expect(task().returnsOn, isNull);
  });

  test('una tarea repetida no puede tener fecha', () {
    expect(
      () => task(dueDate: today, recurrence: Recurrence.fixed(7)),
      throwsA(isA<AssertionError>()),
    );
  });

  test('copyWith cambia lo indicado y puede vaciar los opcionales', () {
    final HouseholdTask original = task(dueDate: today, lastDoneAt: t0);
    final HouseholdTask changed = original.copyWith(
      title: 'Sacar el reciclaje',
      urgency: Urgency.high,
      status: TaskStatus.done,
      categoryIds: <String>['c1'],
      dueDate: () => null,
      recurrence: () => Recurrence.fixed(7),
      lastDoneAt: () => null,
      updatedAt: now,
    );

    expect(changed.title, 'Sacar el reciclaje');
    expect(changed.urgency, Urgency.high);
    expect(changed.status, TaskStatus.done);
    expect(changed.categoryIds, <String>['c1']);
    expect(changed.dueDate, isNull);
    expect(changed.recurrence, Recurrence.fixed(7));
    expect(changed.lastDoneAt, isNull);
    expect(changed.updatedAt, now);
    expect(changed.createdAt, t0);
    expect(original.copyWith(), original);
    expect(original.toString(), contains('Sacar la basura'));
  });

  test('las categorías por defecto se identifican por su nombre', () {
    expect(DefaultTaskCategory.values.map((DefaultTaskCategory category) => category.key),
        <String>['cleaning', 'kitchen', 'garden', 'bills', 'repairs']);
  });
}
