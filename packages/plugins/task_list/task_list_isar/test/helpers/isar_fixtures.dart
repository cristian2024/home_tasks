import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_isar/task_list_isar.dart';

/// La lista de tareas sobre Isar tal como la compone una app: [IsarStorage]
/// con [TaskListIsar], en un locator propio y un directorio temporal.
/// [close] cierra la base y borra el directorio.
class TestStorage {
  TestStorage._(this.services, this._directory);

  final ServiceLocator services;
  final Directory _directory;

  TaskListRepository get repository => services.get<TaskListRepository>();

  static Future<TestStorage> open() async {
    final Directory directory = Directory.systemTemp.createTempSync('task_list_isar_test');
    final ServiceLocator services = ServiceLocator();
    await IsarStorage(directory: directory.path, features: const <IsarFeature>[TaskListIsar()]).register(services);
    return TestStorage._(services, directory);
  }

  Future<void> close() async {
    await services.reset();
    _directory.deleteSync(recursive: true);
  }
}
