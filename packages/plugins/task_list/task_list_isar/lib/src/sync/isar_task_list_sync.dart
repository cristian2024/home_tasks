import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:storage_isar/adapter.dart';
import 'package:sync_isar/sync_isar.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../mappers/synced_entity_mapper.dart';
import '../mappers/task_data_mapper.dart';
import '../models/isar_task.dart';
import '../models/isar_task_category.dart';
import '../models/isar_task_list_synced.dart';

/// Escritura local de una entidad: su colección, su id y sus campos
/// sincronizados después de escribir.
typedef TaskSyncWrite = ({String collection, String id, Map<String, Object?> fields});

/// La sincronización de la lista de tareas sobre Isar: copias sincronizadas,
/// registro de las escrituras locales y migración de lo guardado antes de
/// componer la sincronización.
///
/// Solo actúa si la app compuso la sincronización: si en el locator hay un
/// `HlcClock` (lo registra `SyncModule`) y un [IsarChangeLogWriter] (lo
/// registra `SyncIsar`). Los pide al usarlos, porque se registran después de
/// abrir la base.
class IsarTaskListSync {
  IsarTaskListSync(this._isar, this._services, {IdGenerator ids = const UuidV4Generator()}) : _ids = ids;

  final Isar _isar;
  final ServiceLocator? _services;
  final IdGenerator _ids;

  IsarCollection<IsarTaskListSynced> get _synced => _isar.isarTaskListSynceds;

  static TaskSyncWrite task(IsarTask model) => (
        collection: TaskListCollections.tasks,
        id: model.id,
        fields: TaskListCodec.taskFields(TaskDataMapper.fromIsarTask(model)),
      );

  static TaskSyncWrite category(IsarTaskCategory model) => (
        collection: TaskListCollections.categories,
        id: model.id,
        fields: TaskListCodec.categoryFields(TaskDataMapper.fromIsarCategory(model)),
      );

  static TaskSyncWrite deletion(String collection, String id, DateTime at) =>
      (collection: collection, id: id, fields: TaskListCodec.deletion(at));

  /// Al empezar una transacción de escritura, antes de escribir nada: migra
  /// lo guardado antes si aún no se hizo.
  Future<void> prepare() async {
    final _SyncContext? context = _context();
    if (context != null) {
      await _migrate(context);
    }
  }

  /// Al final de la transacción de escritura: actualiza las copias de lo
  /// escrito y registra sus cambios en el log, todo en esa transacción.
  Future<void> record(List<TaskSyncWrite> writes) async {
    final _SyncContext? context = _context();
    if (context == null || writes.isEmpty) {
      return;
    }
    final List<LocalSyncWrite> localWrites = <LocalSyncWrite>[
      for (final TaskSyncWrite write in writes)
        LocalSyncWrite(
          collection: write.collection,
          id: write.id,
          fields: write.fields,
          current: await _current(write.collection, write.id),
        ),
    ];
    final LocalSyncChanges changes =
        context.recorder.record(localWrites, nextSeq: await context.writer.nextSeq(context.recorder.deviceId));
    await _putSynced(changes.entities);
    await context.writer.append(changes.records);
  }

  /// Copias de [collection], tras migrar los datos anteriores si hace falta.
  Future<List<SyncedEntity>> syncedEntities(String collection) async {
    await _isar.writeTxn(prepare);
    final List<IsarTaskListSynced> rows = await _synced.where().collectionEqualToAnyEntityId(collection).findAll();
    return rows.map(SyncedEntityMapper.fromIsar).toList();
  }

  /// Guarda lo que deja la sincronización, en una transacción y sin
  /// registrar nada.
  Future<void> commit(TaskListSyncCommit commit) => _isar.writeTxn(() async {
        await _putSynced(commit.entities);
        await _isar.isarTasks.putAllById(commit.tasks.map(SyncedEntityMapper.toIsarTask).toList());
        await _isar.isarTaskCategorys.putAllById(commit.categories.map(SyncedEntityMapper.toIsarCategory).toList());
      });

  _SyncContext? _context() {
    final ServiceLocator? services = _services;
    if (services == null || !services.isRegistered<HlcClock>() || !services.isRegistered<IsarChangeLogWriter>()) {
      return null;
    }
    return _SyncContext(
      LocalSyncRecorder(hlcClock: services.get<HlcClock>(), ids: _ids),
      services.get<HlcClock>(),
      services.get<IsarChangeLogWriter>(),
    );
  }

  Future<SyncedEntity?> _current(String collection, String id) async {
    final IsarTaskListSynced? current = await _synced.getByCollectionEntityId(collection, id);
    return current == null ? null : SyncedEntityMapper.fromIsar(current);
  }

  Future<void> _putSynced(List<SyncedEntity> entities) =>
      _synced.putAllByCollectionEntityId(entities.map(SyncedEntityMapper.toIsar).toList());

  /// Una sola vez (spec §10.4.8): da a lo que ya estaba guardado su copia
  /// sincronizada, con marcas derivadas de sus fechas y este dispositivo como
  /// origen, y registra sus cambios para que viajen al unirse a un hogar. Lo
  /// borrado se migra borrado. Las categorías no tienen fecha: reciben la
  /// marca más antigua.
  Future<void> _migrate(_SyncContext context) async {
    if (await _synced.getByCollectionEntityId(IsarTaskListSynced.migrationMarker, '') != null) {
      return;
    }
    final String deviceId = context.hlcClock.deviceId;
    int seq = await context.writer.nextSeq(deviceId);
    final List<ChangeRecord> records = <ChangeRecord>[];
    final List<SyncedEntity> entities = <SyncedEntity>[
      SyncedEntity(collection: IsarTaskListSynced.migrationMarker, id: ''),
    ];
    void add(TaskSyncWrite write, DateTime? at, DateTime? deletedAt) {
      final Hlc hlc = Hlc(wallTime: (deletedAt ?? at)?.millisecondsSinceEpoch ?? 0, counter: 0, deviceId: deviceId);
      final List<FieldChange> changes = FieldDiff.between(null, <String, Object?>{
        ...write.fields,
        if (deletedAt != null) ...TaskListCodec.deletion(deletedAt),
      });
      records.add(ChangeRecord(
        opId: _ids.newId(),
        deviceId: deviceId,
        seq: seq++,
        collection: write.collection,
        entityId: write.id,
        hlc: hlc,
        changes: changes,
      ));
      entities.add(SyncedEntity(collection: write.collection, id: write.id).apply(changes, hlc));
    }

    for (final IsarTaskCategory model in await _isar.isarTaskCategorys.where().findAll()) {
      add(category(model), null, model.deletedAt);
    }
    for (final IsarTask model in await _isar.isarTasks.where().findAll()) {
      add(task(model), model.updatedAt, model.deletedAt);
    }
    await _putSynced(entities);
    await context.writer.append(records);
  }
}

class _SyncContext {
  _SyncContext(this.recorder, this.hlcClock, this.writer);

  final LocalSyncRecorder recorder;
  final HlcClock hlcClock;
  final IsarChangeLogWriter writer;
}
