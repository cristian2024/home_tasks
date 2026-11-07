import 'package:fake_async/fake_async.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_domain/testing.dart';
import 'package:test/test.dart';

void main() {
  taskListRepositoryContract(
    'InMemory',
    create: InMemoryTaskListRepository.new,
    dispose: (TaskListRepository repository) => (repository as InMemoryTaskListRepository).close(),
  );

  test('first termina con el reloj simulado (onCancel no devuelve el futuro de cancel)', () {
    fakeAsync((FakeAsync async) {
      final InMemoryTaskListRepository repository = InMemoryTaskListRepository();
      List<HouseholdTask>? tasks;
      List<TaskCategory>? categories;

      repository.watchTasks().first.then((List<HouseholdTask> value) => tasks = value);
      repository.watchCategories().first.then((List<TaskCategory> value) => categories = value);
      async.flushMicrotasks();

      expect(tasks, isEmpty);
      expect(categories, isEmpty);
    });
  });
}
