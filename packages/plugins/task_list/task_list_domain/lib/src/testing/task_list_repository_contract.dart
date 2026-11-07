import 'dart:async';

import 'package:async/async.dart';
import 'package:recurrence/recurrence.dart';
import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';
import '../repositories/task_list_repository.dart';

/// Tests de contrato de [TaskListRepository]. Toda implementación (en memoria
/// o de cualquier motor de base de datos) debe pasarlos.
///
/// [create] devuelve un repositorio vacío para cada test y [dispose] lo
/// libera.
///
/// ```dart
/// taskListRepositoryContract('Isar', create: () => ..., dispose: (_) => ...);
/// ```
void taskListRepositoryContract(
  String implementation, {
  required FutureOr<TaskListRepository> Function() create,
  FutureOr<void> Function(TaskListRepository repository)? dispose,
}) {
  group('TaskListRepository ($implementation)', () {
    late TaskListRepository repository;

    final DateTime t0 = DateTime.utc(2026, 11, 3, 9);
    final DateTime t1 = DateTime.utc(2026, 11, 4, 9);

    HouseholdTask task(
      String id, {
      String title = 'Limpiar la nevera',
      List<String> categoryIds = const <String>[],
      TaskStatus status = TaskStatus.pending,
      DateTime? updatedAt,
    }) =>
        HouseholdTask(
          id: id,
          title: title,
          urgency: Urgency.high,
          status: status,
          categoryIds: categoryIds,
          recurrence: Recurrence.between(10, 14),
          lastDoneAt: t0,
          createdAt: t0,
          updatedAt: updatedAt ?? t0,
        );

    TaskCategory category(String id, int sortOrder, {String? name, String? defaultKey}) => TaskCategory(
          id: id,
          sortOrder: sortOrder,
          name: name ?? (defaultKey == null ? id : null),
          defaultKey: defaultKey,
        );

    Set<String> ids(List<HouseholdTask> tasks) => <String>{for (final HouseholdTask task in tasks) task.id};

    setUp(() async => repository = await create());
    tearDown(() async => dispose?.call(repository));

    group('tareas', () {
      test('saveTask guarda todos los campos y getTask los devuelve', () async {
        await repository.saveTask(task('t1', categoryIds: <String>['c1', 'c2']));

        expect(await repository.getTask('t1'), task('t1', categoryIds: <String>['c1', 'c2']));
        expect(await repository.getTask('nada'), isNull);
      });

      test('guarda una tarea hecha, con fecha límite y sin recurrencia', () async {
        final HouseholdTask plain = HouseholdTask(
          id: 't1',
          title: 'Pagar la administración',
          urgency: Urgency.normal,
          status: TaskStatus.done,
          dueDate: DateTime.utc(2026, 11, 5),
          lastDoneAt: t1,
          createdAt: t0,
          updatedAt: t1,
        );

        await repository.saveTask(plain);

        expect(await repository.getTask('t1'), plain);
      });

      test('saveTask reemplaza la tarea con el mismo ID', () async {
        await repository.saveTask(task('t1'));
        await repository.saveTask(task('t1', title: 'Limpiar la nevera a fondo', updatedAt: t1));

        expect((await repository.getTask('t1'))!.title, 'Limpiar la nevera a fondo');
        expect(await repository.getTasks(), hasLength(1));
      });

      test('las fechas se devuelven en UTC', () async {
        await repository.saveTask(task('t1'));

        final HouseholdTask saved = (await repository.getTask('t1'))!;
        expect(saved.createdAt.isUtc && saved.updatedAt.isUtc && saved.lastDoneAt!.isUtc, isTrue);
      });

      test('watchTasks emite al suscribirse y con cada cambio', () async {
        await repository.saveTask(task('t1'));
        final StreamQueue<List<HouseholdTask>> queue = StreamQueue<List<HouseholdTask>>(repository.watchTasks());
        addTearDown(queue.cancel);

        expect(ids(await queue.next), <String>{'t1'});
        await repository.saveTask(task('t2'));
        await expectLater(
          queue,
          emitsThrough(predicate<List<HouseholdTask>>((List<HouseholdTask> tasks) => tasks.length == 2)),
        );
        await repository.deleteTasks(<String>['t1'], deletedAt: t1);
        await expectLater(
          queue,
          emitsThrough(predicate<List<HouseholdTask>>((List<HouseholdTask> tasks) => ids(tasks).join() == 't2')),
        );
      });

      test('deleteTasks borra las tareas e ignora las que no existen', () async {
        await repository.saveTask(task('t1'));
        await repository.saveTask(task('t2'));

        await repository.deleteTasks(<String>['t1', 'nada'], deletedAt: t1);

        expect(ids(await repository.getTasks()), <String>{'t2'});
        expect(await repository.getTask('t1'), isNull);
      });

      test('una tarea borrada no vuelve al guardarla', () async {
        await repository.saveTask(task('t1'));
        await repository.deleteTasks(<String>['t1'], deletedAt: t1);

        await repository.saveTask(task('t1', updatedAt: t1));

        expect(await repository.getTasks(), isEmpty);
      });
    });

    group('categorías', () {
      test('saveCategories guarda y getCategories las devuelve por sortOrder', () async {
        await repository.saveCategories(<TaskCategory>[
          category('c2', 1, name: 'Jardín'),
          category('c1', 0, defaultKey: 'cleaning'),
        ]);

        expect(await repository.getCategories(), <TaskCategory>[
          category('c1', 0, defaultKey: 'cleaning'),
          category('c2', 1, name: 'Jardín'),
        ]);
      });

      test('saveCategories reemplaza las que tienen el mismo ID (reordenar, renombrar)', () async {
        await repository.saveCategories(<TaskCategory>[category('c1', 0), category('c2', 1)]);

        await repository.saveCategories(<TaskCategory>[category('c1', 1, name: 'Casa'), category('c2', 0)]);

        expect(await repository.getCategories(), <TaskCategory>[category('c2', 0), category('c1', 1, name: 'Casa')]);
      });

      test('watchCategories emite al suscribirse y con cada cambio', () async {
        final StreamQueue<List<TaskCategory>> queue = StreamQueue<List<TaskCategory>>(repository.watchCategories());
        addTearDown(queue.cancel);

        expect(await queue.next, isEmpty);
        await repository.saveCategories(<TaskCategory>[category('c1', 0)]);
        await expectLater(queue, emitsThrough(<TaskCategory>[category('c1', 0)]));
      });

      test('deleteCategory la borra y la quita de las tareas que la tienen', () async {
        await repository.saveCategories(<TaskCategory>[category('c1', 0), category('c2', 1)]);
        await repository.saveTask(task('t1', categoryIds: <String>['c1', 'c2']));
        await repository.saveTask(task('t2', categoryIds: <String>['c1']));
        await repository.saveTask(task('t3', categoryIds: <String>['c2']));

        await repository.deleteCategory('c1', updatedAt: t1);

        expect(await repository.getCategories(), <TaskCategory>[category('c2', 1)]);
        expect(await repository.getTask('t1'), task('t1', categoryIds: <String>['c2'], updatedAt: t1));
        expect(await repository.getTask('t2'), task('t2', updatedAt: t1));
        expect(await repository.getTask('t3'), task('t3', categoryIds: <String>['c2']));
      });

      test('deleteCategory de una categoría que no existe no hace nada', () async {
        await repository.saveTask(task('t1', categoryIds: <String>['c1']));

        await repository.deleteCategory('nada', updatedAt: t1);

        expect(await repository.getTask('t1'), task('t1', categoryIds: <String>['c1']));
      });

      test('una categoría borrada no vuelve al guardarla', () async {
        await repository.saveCategories(<TaskCategory>[category('c1', 0)]);
        await repository.deleteCategory('c1', updatedAt: t1);

        await repository.saveCategories(<TaskCategory>[category('c1', 0, name: 'Casa'), category('c2', 1)]);

        expect(await repository.getCategories(), <TaskCategory>[category('c2', 1)]);
      });

      test('seedDefaultCategories solo crea las categorías la primera vez', () async {
        final List<TaskCategory> defaults = <TaskCategory>[category('c1', 0, defaultKey: 'cleaning')];

        expect(await repository.seedDefaultCategories(defaults), isTrue);
        await repository.deleteCategory('c1', updatedAt: t1);

        expect(await repository.seedDefaultCategories(defaults), isFalse);
        expect(await repository.getCategories(), isEmpty);
      });
    });
  });
}
