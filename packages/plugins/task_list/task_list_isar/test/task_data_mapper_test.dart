import 'package:flutter_test/flutter_test.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_isar/src/mappers/task_data_mapper.dart';
import 'package:task_list_isar/src/models/isar_task.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 3, 9);

  test('una tarea repetida con todos los campos va y vuelve sin cambios', () {
    final HouseholdTask task = HouseholdTask(
      id: 't1',
      title: 'Limpiar la nevera',
      urgency: Urgency.high,
      status: TaskStatus.pending,
      categoryIds: const <String>['c1', 'c2'],
      recurrence: Recurrence.between(10, 14),
      lastDoneAt: t0,
      createdAt: t0,
      updatedAt: t0,
    );

    expect(TaskDataMapper.fromIsarTask(TaskDataMapper.toIsarTask(task)), task);
  });

  test('una tarea con fecha y sin recurrencia va y vuelve, con la fecha como día UTC', () {
    final HouseholdTask task = HouseholdTask(
      id: 't1',
      title: 'Pagar la administración',
      urgency: Urgency.normal,
      status: TaskStatus.done,
      dueDate: DateTime.utc(2026, 11, 5),
      createdAt: t0,
      updatedAt: t0,
    );

    final IsarTask model = TaskDataMapper.toIsarTask(task);
    model.dueDate = model.dueDate!.toLocal();

    expect(model.recurrenceMinDays, isNull);
    expect(model.recurrenceMaxDays, isNull);
    expect(TaskDataMapper.fromIsarTask(model), task);
  });

  test('una categoría va y vuelve sin cambios', () {
    const TaskCategory category = TaskCategory(id: 'c1', sortOrder: 2, name: 'Jardín');

    expect(TaskDataMapper.fromIsarCategory(TaskDataMapper.toIsarCategory(category)), category);
  });
}
