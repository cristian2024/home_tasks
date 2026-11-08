import 'package:flutter_test/flutter_test.dart';
import 'package:storage_isar/adapter.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_domain/testing.dart';
import 'package:task_list_isar/src/repositories/isar_task_list_repository.dart';
import 'package:task_list_isar/task_list_isar.dart';

import 'helpers/isar_fixtures.dart';

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  final Map<TaskListRepository, TestStorage> storages = <TaskListRepository, TestStorage>{};
  taskListRepositoryContract(
    'Isar',
    create: () async {
      final TestStorage storage = await TestStorage.open();
      storages[storage.repository] = storage;
      return storage.repository;
    },
    dispose: (TaskListRepository repository) => storages.remove(repository)!.close(),
  );

  test('TaskListIsar aporta sus colecciones y registra su repositorio Isar', () async {
    final TestStorage storage = await TestStorage.open();
    addTearDown(storage.close);

    expect(
      const TaskListIsar().schemas.map((CollectionSchema<dynamic> schema) => schema.name),
      <String>['IsarTask', 'IsarTaskCategory', 'IsarTaskListFlag', 'IsarTaskListSynced'],
    );
    expect(storage.repository, isA<IsarTaskListRepository>());
  });
}
