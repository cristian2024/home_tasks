import 'package:core_sync/core_sync.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:test/test.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 3, 9);

  SyncedEntity entity(Map<String, Object?> fields, {String collection = TaskListCollections.tasks}) {
    final ChangeRecord record = ChangeRecord(
      opId: 'a-1',
      deviceId: 'a',
      seq: 1,
      collection: collection,
      entityId: 'x',
      hlc: Hlc(wallTime: 1, counter: 0, deviceId: 'a'),
      changes: FieldDiff.between(null, fields),
    );
    return SyncedEntity(collection: collection, id: 'x').merge(record);
  }

  final HouseholdTask dated = HouseholdTask(
    id: 'x',
    title: 'Pagar la administración',
    urgency: Urgency.high,
    status: TaskStatus.pending,
    categoryIds: const <String>['c1'],
    dueDate: DateTime.utc(2026, 11, 5),
    createdAt: t0,
    updatedAt: t0,
  );

  test('una tarea con fecha va y vuelve igual, con la fecha como día', () {
    final Map<String, Object?> fields = TaskListCodec.taskFields(dated);

    expect(fields['dueDate'], '2026-11-05');
    expect(TaskListCodec.taskOf(entity(fields)), dated);
  });

  test('una tarea repetida ignora la fecha y lee la recurrencia', () {
    final HouseholdTask repeated = dated.copyWith(dueDate: () => null, recurrence: () => Recurrence.between(10, 14), lastDoneAt: () => t0);
    final Map<String, Object?> fields = <String, Object?>{...TaskListCodec.taskFields(repeated), 'dueDate': '2026-11-05'};

    expect(TaskListCodec.taskOf(entity(fields)), repeated);
  });

  test('a una tarea incompleta le faltan campos', () {
    expect(TaskListCodec.taskOf(entity(<String, Object?>{'title': 'Sin más'})), isNull);
  });

  test('una recurrencia o una fecha inválidas se leen como ninguna, y updatedAt cae a createdAt', () {
    final Map<String, Object?> fields = <String, Object?>{
      ...TaskListCodec.taskFields(dated),
      'recurrence': <String, Object?>{'minDays': 9, 'maxDays': 2},
      'dueDate': 'mañana',
      'updatedAt': null,
      TaskListCodec.categoryIds: null,
    };

    final HouseholdTask task = TaskListCodec.taskOf(entity(fields))!;
    expect(task.recurrence, isNull);
    expect(task.dueDate, isNull);
    expect(task.updatedAt, t0);
    expect(task.categoryIds, isEmpty);
    expect(TaskListCodec.taskOf(entity(<String, Object?>{...fields, 'recurrence': 'nada'}))!.recurrence, isNull);
  });

  test('categorías: van y vuelven, y sin orden o sin nombre no valen', () {
    const TaskCategory garden = TaskCategory(id: 'x', sortOrder: 2, name: 'Jardín');
    const TaskCategory cleaning = TaskCategory(id: 'x', sortOrder: 0, defaultKey: 'cleaning');

    expect(TaskListCodec.categoryOf(entity(TaskListCodec.categoryFields(garden), collection: TaskListCollections.categories)), garden);
    expect(TaskListCodec.categoryOf(entity(TaskListCodec.categoryFields(cleaning), collection: TaskListCollections.categories)), cleaning);
    expect(TaskListCodec.categoryOf(entity(<String, Object?>{'name': 'Sin orden'}, collection: TaskListCollections.categories)), isNull);
    expect(TaskListCodec.categoryOf(entity(<String, Object?>{'sortOrder': 1}, collection: TaskListCollections.categories)), isNull);
  });

  test('el borrado guarda su momento', () {
    expect(TaskListCodec.deletedAtOf(entity(TaskListCodec.deletion(t0))), t0);
    expect(TaskListCodec.deletedAtOf(entity(TaskListCodec.taskFields(dated))), isNull);
  });

  test('el resultado de la resolución se compara por valor', () {
    final TaskResolved<HouseholdTask> resolved = TaskResolved<HouseholdTask>(dated, deletedAt: t0);

    expect(resolved.isDeleted, isTrue);
    expect(resolved, TaskResolved<HouseholdTask>(dated, deletedAt: t0));
    expect(TaskSyncView(tasks: const <String, TaskResolved<HouseholdTask>>{}, categories: const <String, TaskResolved<TaskCategory>>{}),
        TaskSyncView(tasks: const <String, TaskResolved<HouseholdTask>>{}, categories: const <String, TaskResolved<TaskCategory>>{}));
    expect(TaskListSyncCommit().isEmpty, isTrue);
    expect(TaskListSyncCommit(), TaskListSyncCommit());
  });
}
