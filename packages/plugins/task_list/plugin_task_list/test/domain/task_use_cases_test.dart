import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases cases;

  setUp(() => cases = TestUseCases());

  group('CreateTask', () {
    test('crea una tarea pendiente con el título recortado y la fecha como día', () async {
      await cases.ensureDefaults();
      final TaskCategory cleaning = (await cases.repository.getCategories()).first;

      final HouseholdTask task = await cases.createTask(
        title: '  Sacar la basura ',
        urgency: Urgency.immediate,
        categoryIds: <String>[cleaning.id, cleaning.id],
        dueDate: DateTime.utc(2026, 11, 6, 18),
      );

      expect(task.title, 'Sacar la basura');
      expect(task.status, TaskStatus.pending);
      expect(task.categoryIds, <String>[cleaning.id]);
      expect(task.dueDate, DateTime.utc(2026, 11, 6));
      expect(task.createdAt, t0);
      expect(await cases.repository.getTask(task.id), task);
    });

    test('una tarea que se repite no guarda la fecha', () async {
      final HouseholdTask task = await cases.createTask(
        title: 'Limpiar la nevera',
        dueDate: DateTime.utc(2026, 11, 6),
        recurrence: Recurrence.between(10, 14),
      );

      expect(task.dueDate, isNull);
      expect(task.recurrence, Recurrence.between(10, 14));
    });

    test('rechaza un título vacío y categorías que no existen', () async {
      expect(() => cases.createTask(title: ' '), throwsA(isA<TaskValidationException>()));
      expect(() => cases.createTask(title: 'Regar', categoryIds: <String>['nada']), throwsA(isA<TaskCategoryNotFoundException>()));
    });
  });

  group('UpdateTask', () {
    test('cambia lo indicado y actualiza la fecha de cambio', () async {
      final HouseholdTask task = await cases.createTask(title: 'Regar las plantas', dueDate: DateTime.utc(2026, 11, 7));
      cases.clock.advance(const Duration(hours: 1));

      final HouseholdTask updated = await cases.updateTask(task.id, title: 'Regar el jardín', urgency: Urgency.high);

      expect(updated.title, 'Regar el jardín');
      expect(updated.urgency, Urgency.high);
      expect(updated.dueDate, DateTime.utc(2026, 11, 7));
      expect(updated.updatedAt, t0.add(const Duration(hours: 1)));
    });

    test('pasar a repetirse quita la fecha, y quitar la recurrencia admite una fecha nueva', () async {
      final HouseholdTask task = await cases.createTask(title: 'Revisar el extintor', dueDate: DateTime.utc(2026, 11, 7));

      final HouseholdTask repeated = await cases.updateTask(task.id, recurrence: () => Recurrence.fixed(30));
      final HouseholdTask dated = await cases.updateTask(
        task.id,
        recurrence: () => null,
        dueDate: () => DateTime.utc(2026, 11, 20, 9),
        categoryIds: <String>[],
      );

      expect(repeated.dueDate, isNull);
      expect(dated.recurrence, isNull);
      expect(dated.dueDate, DateTime.utc(2026, 11, 20));
    });

    test('si nada cambia no escribe', () async {
      final HouseholdTask task = await cases.createTask(title: 'Regar las plantas');
      cases.clock.advance(const Duration(hours: 1));

      expect(await cases.updateTask(task.id, title: 'Regar las plantas'), task);
    });

    test('una tarea que no existe lanza TaskNotFoundException', () {
      expect(() => cases.updateTask('nada', title: 'x'), throwsA(isA<TaskNotFoundException>()));
      expect(() => cases.getTask('nada'), throwsA(isA<TaskNotFoundException>()));
    });
  });

  test('GetTask devuelve la tarea y DeleteTasks la borra', () async {
    final HouseholdTask task = await cases.createTask(title: 'Arreglar la persiana');

    expect(await cases.getTask(task.id), task);
    await cases.deleteTasks(<String>[task.id]);
    expect(await cases.repository.getTasks(), isEmpty);
  });

  group('completar', () {
    test('una tarea normal pasa a hecha y se puede deshacer', () async {
      final HouseholdTask task = await cases.createTask(title: 'Sacar la basura');
      cases.clock.advance(const Duration(minutes: 5));

      final TaskCompletion completion = (await cases.completeTask(task.id))!;

      expect(completion.previous, task);
      expect(completion.completed.status, TaskStatus.done);
      expect(completion.completed.lastDoneAt, t0.add(const Duration(minutes: 5)));
      expect(await cases.completeTask(task.id), isNull, reason: 'ya estaba hecha');

      await cases.undoCompletion(completion);
      final HouseholdTask restored = (await cases.repository.getTask(task.id))!;
      expect(restored.status, TaskStatus.pending);
      expect(restored.lastDoneAt, isNull);
    });

    test('una tarea que se repite sigue pendiente y espera su ventana', () async {
      final HouseholdTask task = await cases.createTask(title: 'Limpiar la nevera', recurrence: Recurrence.between(10, 14));

      final TaskCompletion completion = (await cases.completeTask(task.id))!;

      expect(completion.completed.status, TaskStatus.pending);
      expect(completion.completed.stateAt(t0, today: DateTime.utc(2026, 11, 6)), TaskState.waiting);
    });

    test('ReopenTask vuelve a pendiente una hecha y no toca una pendiente', () async {
      final HouseholdTask task = await cases.createTask(title: 'Sacar la basura');
      await cases.completeTask(task.id);

      await cases.reopenTask(task.id);
      final HouseholdTask reopened = (await cases.repository.getTask(task.id))!;
      await cases.reopenTask(task.id);

      expect(reopened.status, TaskStatus.pending);
      expect(reopened.lastDoneAt, t0, reason: 'conserva cuándo se hizo');
      expect(await cases.repository.getTask(task.id), reopened);
    });

    test('ClearDoneTasks borra solo las hechas', () async {
      final HouseholdTask done = await cases.createTask(title: 'Sacar la basura');
      await cases.createTask(title: 'Regar las plantas');
      await cases.completeTask(done.id);

      expect(await cases.clearDone(), 1);
      expect(await cases.clearDone(), 0);
      expect((await cases.repository.getTasks()).map((HouseholdTask task) => task.title), <String>['Regar las plantas']);
    });

    test('completar una tarea que no existe lanza TaskNotFoundException', () {
      expect(() => cases.completeTask('nada'), throwsA(isA<TaskNotFoundException>()));
    });
  });

  test('TaskCompletion se compara por valor', () async {
    final HouseholdTask task = await cases.createTask(title: 'Sacar la basura');

    expect(TaskCompletion(previous: task, completed: task), TaskCompletion(previous: task, completed: task));
  });
}
