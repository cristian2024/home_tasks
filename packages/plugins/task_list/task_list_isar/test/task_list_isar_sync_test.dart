import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_isar/sync_isar.dart';
import 'package:task_list_domain/task_list_domain.dart';
import 'package:task_list_domain/testing.dart';
import 'package:task_list_isar/task_list_isar.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 3, 9);

/// La lista de tareas y la sincronización sobre Isar, como las compone una
/// app. Sin [synced], la app no compuso la sincronización (no hay
/// `HlcClock`).
Future<ServiceLocator> _open({bool synced = true}) async {
  final Directory directory = Directory.systemTemp.createTempSync('task_list_isar_sync_test');
  final ServiceLocator services = ServiceLocator();
  await IsarStorage(directory: directory.path, features: const <IsarFeature>[TaskListIsar(), SyncIsar()])
      .register(services);
  if (synced) {
    _composeSync(services);
  }
  addTearDown(() async {
    await services.reset();
    directory.deleteSync(recursive: true);
  });
  return services;
}

void _composeSync(ServiceLocator services) => services.registerSingleton<HlcClock>(
      HlcClock(deviceId: 'device-local', clock: FixedClock(DateTime.utc(2026, 11, 7))),
    );

Future<TaskListSyncSubject> _subject() async {
  final ServiceLocator services = await _open();
  return TaskListSyncSubject(
    repository: services.get<TaskListRepository>(),
    participant: SyncParticipants.of(services).forCollection(TaskListCollections.tasks)! as TaskListSyncParticipant,
    log: services.get<ChangeLog>(),
  );
}

HouseholdTask _task(String id, {DateTime? updatedAt}) => HouseholdTask(
      id: id,
      title: 'Sacar la basura',
      urgency: Urgency.normal,
      status: TaskStatus.pending,
      createdAt: _t0,
      updatedAt: updatedAt ?? _t0,
    );

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  taskListSyncContract('Isar', create: _subject);
  taskListRepositoryContract('Isar, sincronizado', create: () async => (await _open()).get<TaskListRepository>());

  group('TaskListIsar con sincronización', () {
    test('añade su participante a SyncParticipants', () async {
      final ServiceLocator services = await _open();

      expect(SyncParticipants.of(services).all.single, isA<TaskListSyncParticipant>());
      expect(SyncParticipants.of(services).forCollection(TaskListCollections.categories), isNotNull);
    });

    test('sin la sincronización compuesta no registra nada', () async {
      final ServiceLocator services = await _open(synced: false);
      final TaskListRepository repository = services.get<TaskListRepository>();

      await repository.saveTask(_task('t1'));

      expect(await services.get<ChangeLog>().vector(), VersionVector.empty);
      expect(await (repository as TaskListSyncStore).syncedEntities(TaskListCollections.tasks), isEmpty);
    });

    test('migra una vez lo guardado antes, y lo borrado se migra borrado', () async {
      final ServiceLocator services = await _open(synced: false);
      final TaskListRepository repository = services.get<TaskListRepository>();
      final TaskListSyncStore store = repository as TaskListSyncStore;
      await repository.seedDefaultCategories(<TaskCategory>[const TaskCategory(id: 'c1', sortOrder: 0, defaultKey: 'cleaning')]);
      await repository.saveTask(_task('t1'));
      await repository.saveTask(_task('t2'));
      await repository.deleteTasks(<String>['t2'], deletedAt: _t0.add(const Duration(hours: 1)));
      _composeSync(services);

      final List<SyncedEntity> tasks = await store.syncedEntities(TaskListCollections.tasks);
      await store.syncedEntities(TaskListCollections.tasks);

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.collection), <String>[
        TaskListCollections.categories,
        TaskListCollections.tasks,
        TaskListCollections.tasks,
      ]);
      expect(records.first.hlc, Hlc(wallTime: 0, counter: 0, deviceId: 'device-local'));
      expect(tasks.map(TaskListCodec.deletedAtOf).whereType<DateTime>(), <DateTime>[_t0.add(const Duration(hours: 1))]);
    });

    test('la migración también se hace al escribir y no se repite', () async {
      final ServiceLocator services = await _open(synced: false);
      final TaskListRepository repository = services.get<TaskListRepository>();
      await repository.saveTask(_task('t1'));
      _composeSync(services);

      await repository.saveTask(_task('t1', updatedAt: _t0.add(const Duration(days: 1))));
      await repository.saveTask(_task('t2'));

      final List<ChangeRecord> records = await services.get<ChangeLog>().missingFor(VersionVector.empty);
      expect(records.map((ChangeRecord record) => record.seq), <int>[1, 2, 3]);
      expect(records[1].changes, <FieldChange>[ValueChange('updatedAt', _t0.add(const Duration(days: 1)).toIso8601String())]);
    });
  });
}
