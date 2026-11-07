import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:test/test.dart';
import 'package:urgency/urgency.dart';

import '../entities/household_task.dart';
import '../entities/task_category.dart';
import '../repositories/task_list_repository.dart';
import '../sync/task_list_codec.dart';
import '../sync/task_list_sync_participant.dart';

/// Lo que necesita [taskListSyncContract]: un repositorio que se sincroniza,
/// su participante y el log donde registra.
class TaskListSyncSubject {
  TaskListSyncSubject({required this.repository, required this.participant, required this.log});

  final TaskListRepository repository;
  final TaskListSyncParticipant participant;
  final ChangeLog log;
}

/// Crea un [TaskListSyncSubject] vacío. Los cambios locales los hace el
/// dispositivo `device-local`, con marcas posteriores a las de
/// [taskListSyncRecords].
typedef TaskListSyncFactory = FutureOr<TaskListSyncSubject> Function();

const int _t0 = 1762420000000;

/// Cambios de tres dispositivos con ediciones concurrentes:
/// - `fridge` renombrada a la vez en A y B: gana B («Limpiar la nevera a
///   fondo»);
/// - A y B sembraron su categoría «cleaning»: queda `cat-a-cleaning` y
///   `trash`, de B, pasa a ella;
/// - B añade `cat-garden` a `fridge` mientras C la borra: la referencia se
///   ignora;
/// - A y B completan `trash` a la vez: cuenta una vez, sin conflicto;
/// - C borra `blind` mientras A cambia su urgencia: queda borrada.
List<ChangeRecord> taskListSyncRecords() {
  ChangeRecord record(String device, int seq, String collection, String entityId, int at, List<FieldChange> changes) =>
      ChangeRecord(
        opId: '$device-$seq',
        deviceId: device,
        seq: seq,
        collection: collection,
        entityId: entityId,
        hlc: Hlc(wallTime: _t0 + at, counter: 0, deviceId: device),
        changes: changes,
      );
  List<FieldChange> values(Map<String, Object?> fields) => FieldDiff.between(null, fields);
  List<FieldChange> task(String id, String title, int at, {Set<String> categoryIds = const <String>{}}) =>
      values(TaskListCodec.taskFields(_task(id, title, at, categoryIds: categoryIds.toList())));
  List<FieldChange> category(String id, int sortOrder, {String? name, String? defaultKey}) =>
      values(TaskListCodec.categoryFields(TaskCategory(id: id, sortOrder: sortOrder, name: name, defaultKey: defaultKey)));
  List<FieldChange> done(int at) => <FieldChange>[
        ValueChange('status', TaskStatus.done.name),
        ValueChange('lastDoneAt', _at(30).toIso8601String()),
        ValueChange('updatedAt', _at(at).toIso8601String()),
      ];
  List<FieldChange> deletion(int at) => values(TaskListCodec.deletion(_at(at)));
  const String tasks = TaskListCollections.tasks;
  const String categories = TaskListCollections.categories;
  return <ChangeRecord>[
    record('device-a', 1, categories, 'cat-a-cleaning', 1, category('cat-a-cleaning', 0, defaultKey: 'cleaning')),
    record('device-a', 2, categories, 'cat-garden', 2, category('cat-garden', 5, name: 'Jardín')),
    record('device-a', 3, tasks, 'fridge', 3, task('fridge', 'Limpiar la nevera', 3, categoryIds: <String>{'cat-a-cleaning'})),
    record('device-a', 4, tasks, 'fridge', 10, <FieldChange>[ValueChange('title', 'Limpiar la nevera ya')]),
    record('device-a', 5, tasks, 'trash', 30, done(30)),
    record('device-a', 6, tasks, 'blind', 60, <FieldChange>[ValueChange('urgency', Urgency.high.name)]),
    record('device-b', 1, categories, 'cat-b-cleaning', 1, category('cat-b-cleaning', 0, defaultKey: 'cleaning')),
    record('device-b', 2, tasks, 'trash', 6, task('trash', 'Sacar la basura', 6, categoryIds: <String>{'cat-b-cleaning'})),
    record('device-b', 3, tasks, 'fridge', 11, <FieldChange>[ValueChange('title', 'Limpiar la nevera a fondo')]),
    record('device-b', 4, tasks, 'trash', 31, done(31)),
    record('device-b', 5, tasks, 'fridge', 40, <FieldChange>[ElementChange(TaskListCodec.categoryIds, 'cat-garden', present: true)]),
    record('device-c', 1, tasks, 'blind', 8, task('blind', 'Arreglar la persiana', 8)),
    record('device-c', 2, categories, 'cat-garden', 39, deletion(39)),
    record('device-c', 3, tasks, 'blind', 61, deletion(61)),
  ];
}

/// Lo que se ve de la lista de tareas a través del repositorio: tareas activas
/// (con sus categorías ordenadas, que no tienen orden propio) y categorías.
/// Comparable con `==`.
Future<Map<String, Object?>> readTaskListState(TaskListRepository repository) async {
  final List<HouseholdTask> tasks = (await repository.getTasks())
      .map((HouseholdTask task) => task.copyWith(categoryIds: List<String>.of(task.categoryIds)..sort()))
      .toList()
    ..sort((HouseholdTask a, HouseholdTask b) => a.id.compareTo(b.id));
  return <String, Object?>{'tasks': tasks, 'categories': await repository.getCategories()};
}

/// Tests de sincronización de la lista de tareas. Todo repositorio que se
/// sincroniza debe pasarlos con su participante.
void taskListSyncContract(String implementation, {required TaskListSyncFactory create}) {
  group('task_list sincronizado ($implementation)', () {
    late TaskListSyncSubject subject;
    final Map<TaskListSyncParticipant, TaskListRepository> repositories = <TaskListSyncParticipant, TaskListRepository>{};

    setUp(() async => subject = await create());

    syncParticipantContract<TaskListSyncParticipant>(
      implementation,
      create: () async {
        final TaskListSyncSubject created = await create();
        repositories[created.participant] = created.repository;
        return created.participant;
      },
      records: taskListSyncRecords(),
      readState: (TaskListSyncParticipant participant) => readTaskListState(repositories[participant]!),
    );

    test('fusiona por campo, sin conflictos', () async {
      final List<SyncConflict> conflicts = await subject.participant.applyRemote(taskListSyncRecords());
      final TaskListRepository repository = subject.repository;

      expect((await repository.getTask('fridge'))?.title, 'Limpiar la nevera a fondo');
      expect((await repository.getTask('fridge'))?.categoryIds, <String>['cat-a-cleaning']);
      expect((await repository.getTask('trash'))?.categoryIds, <String>['cat-a-cleaning']);
      expect((await repository.getTask('trash'))?.status, TaskStatus.done);
      expect((await repository.getTask('trash'))?.lastDoneAt, _at(30));
      expect((await repository.getCategories()).map((TaskCategory category) => category.id), <String>['cat-a-cleaning']);
      expect(await repository.getTask('blind'), isNull);
      expect(conflicts, isEmpty);
    });

    test('las escrituras locales se registran y otro dispositivo las aplica igual', () async {
      final TaskListRepository repository = subject.repository;
      final HouseholdTask oven = _task('oven', 'Limpiar el horno', 100, categoryIds: <String>['c-2', 'c-1']);
      await repository.seedDefaultCategories(<TaskCategory>[
        const TaskCategory(id: 'c-1', sortOrder: 0, defaultKey: 'kitchen'),
        const TaskCategory(id: 'c-2', sortOrder: 1, name: 'Cocina grande'),
      ]);
      await repository.saveTask(oven);
      await repository.saveTask(_task('plants', 'Regar las plantas', 100));
      await repository.saveTask(oven.copyWith(status: TaskStatus.done, lastDoneAt: () => _at(101), updatedAt: _at(101)));
      await repository.deleteCategory('c-2', updatedAt: _at(104));
      await repository.deleteTasks(<String>['plants'], deletedAt: _at(105));
      final TaskListSyncSubject other = await create();

      final List<ChangeRecord> records = await subject.log.missingFor(VersionVector.empty);
      final List<SyncConflict> conflicts = await other.participant.applyRemote(records);

      expect(records.map((ChangeRecord record) => record.seq), List<int>.generate(records.length, (int i) => i + 1));
      expect(conflicts, isEmpty);
      expect(await readTaskListState(other.repository), await readTaskListState(repository));
    });

    test('lo borrado no vuelve con una escritura normal', () async {
      await subject.participant.applyRemote(taskListSyncRecords());

      await subject.repository.saveTask(_task('blind', 'Arreglar la persiana', 100));
      await subject.repository.saveCategories(<TaskCategory>[const TaskCategory(id: 'cat-garden', sortOrder: 0, name: 'Patio')]);

      expect(await subject.repository.getTask('blind'), isNull);
      expect((await subject.repository.getCategories()).map((TaskCategory category) => category.id), <String>['cat-a-cleaning']);
    });

    test('resolver un conflicto no escribe nada', () async {
      await subject.participant.applyRemote(taskListSyncRecords());
      final VersionVector before = await subject.log.vector();

      await subject.participant.resolveConflict(
        SyncConflict(
          id: 'task_list.x',
          collection: TaskListCollections.tasks,
          kind: 'x',
          entityIds: const <String>['fridge'],
          options: <ConflictOption>[ConflictOption('a')],
          provisionalOptionId: 'a',
          detectedAt: _at(0),
        ),
        'a',
      );

      expect(await subject.log.vector(), before);
    });
  });
}

DateTime _at(int offset) => DateTime.fromMillisecondsSinceEpoch(_t0 + offset, isUtc: true);

HouseholdTask _task(String id, String title, int at, {List<String> categoryIds = const <String>[]}) => HouseholdTask(
      id: id,
      title: title,
      urgency: Urgency.normal,
      status: TaskStatus.pending,
      categoryIds: categoryIds,
      createdAt: _at(at),
      updatedAt: _at(at),
    );
