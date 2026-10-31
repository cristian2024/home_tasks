import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/adapter.dart';
import 'package:sync_isar/sync_isar.dart';

import '../mappers/item_data_mapper.dart';
import '../mappers/synced_entity_mapper.dart';
import '../models/isar_household_item.dart';
import '../models/isar_item_event.dart';
import '../models/isar_item_tracker_synced.dart';
import '../models/isar_physical_identifier.dart';

/// La sincronización de item_tracker sobre Isar: copias sincronizadas,
/// registro de las escrituras locales y migración de los datos anteriores.
///
/// Solo actúa si la app compuso la sincronización: si en el locator hay un
/// `HlcClock` (lo registra `SyncModule`) y un [IsarChangeLogWriter] (lo
/// registra `SyncIsar`). Los pide al usarlos, porque se registran después
/// de abrir la base.
class IsarItemTrackerSync {
  IsarItemTrackerSync(this._isar, this._services, {IdGenerator ids = const UuidV4Generator()}) : _ids = ids;

  final Isar _isar;
  final ServiceLocator? _services;
  final IdGenerator _ids;

  IsarCollection<IsarItemTrackerSynced> get _synced => _isar.isarItemTrackerSynceds;

  /// Al empezar una transacción de escritura, antes de escribir nada:
  /// migra lo guardado antes si aún no se hizo.
  Future<void> prepare() async {
    final _SyncContext? context = _context();
    if (context != null) {
      await _migrate(context);
    }
  }

  /// Al final de la transacción de escritura: actualiza las copias de lo
  /// escrito y registra sus cambios en el log, todo en esa transacción.
  Future<void> record({
    List<IsarHouseholdItem> items = const <IsarHouseholdItem>[],
    List<IsarPhysicalIdentifier> identifiers = const <IsarPhysicalIdentifier>[],
    List<IsarItemEvent> events = const <IsarItemEvent>[],
  }) async {
    final _SyncContext? context = _context();
    if (context == null) {
      return;
    }
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[
      for (final IsarHouseholdItem item in items)
        await _write(ItemTrackerCollections.items, item.id, SyncedEntityMapper.itemFields(item)),
      for (final IsarPhysicalIdentifier identifier in identifiers)
        await _write(ItemTrackerCollections.identifiers, identifier.id, SyncedEntityMapper.identifierFields(identifier)),
      for (final IsarItemEvent event in events)
        LocalSyncWrite(
          collection: ItemTrackerCollections.events,
          id: event.id,
          fields: ItemTrackerCodec.eventFields(ItemDataMapper.fromIsarEvent(event)),
        ),
    ];
    final LocalSyncChanges changes =
        context.recorder.record(writes, nextSeq: await context.writer.nextSeq(context.recorder.deviceId));
    await _putSynced(changes.entities);
    await context.writer.append(changes.records);
  }

  /// Copias de [collection], tras migrar los datos anteriores si hace falta.
  Future<List<SyncedEntity>> syncedEntities(String collection) async {
    await _isar.writeTxn(prepare);
    final List<IsarItemTrackerSynced> rows = await _synced.where().collectionEqualToAnyEntityId(collection).findAll();
    return rows.map(SyncedEntityMapper.fromIsar).toList();
  }

  /// Guarda lo que deja la sincronización, en una transacción y sin
  /// registrar nada.
  Future<void> commit(ItemTrackerSyncCommit commit) => _isar.writeTxn(() async {
        await _putSynced(commit.entities);
        await _isar.isarHouseholdItems.putAllById(commit.items.map(SyncedEntityMapper.toIsarItem).toList());
        // Primero los que dejan de estar activos, para no chocar con el
        // índice único del valor activo.
        final List<ResolvedIdentifier> identifiers = List<ResolvedIdentifier>.of(commit.identifiers)
          ..sort((ResolvedIdentifier a, ResolvedIdentifier b) => (a.isActive ? 1 : 0) - (b.isActive ? 1 : 0));
        for (final ResolvedIdentifier identifier in identifiers) {
          await _isar.isarPhysicalIdentifiers.putById(SyncedEntityMapper.toIsarIdentifier(identifier));
        }
        await _isar.isarItemEvents.putAllById(commit.events.map(ItemDataMapper.toIsarEvent).toList());
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

  Future<LocalSyncWrite> _write(String collection, String id, Map<String, Object?> fields) async {
    final IsarItemTrackerSynced? current = await _synced.getByCollectionEntityId(collection, id);
    return LocalSyncWrite(
      collection: collection,
      id: id,
      fields: fields,
      current: current == null ? null : SyncedEntityMapper.fromIsar(current),
    );
  }

  Future<void> _putSynced(List<SyncedEntity> entities) =>
      _synced.putAllByCollectionEntityId(entities.map(SyncedEntityMapper.toIsar).toList());

  /// Una sola vez (spec §10.4.8): da a lo que ya estaba guardado su copia
  /// sincronizada, con marcas derivadas de sus fechas y este dispositivo como
  /// origen, y registra sus cambios para que viajen al unirse a un hogar.
  Future<void> _migrate(_SyncContext context) async {
    if (await _synced.getByCollectionEntityId(IsarItemTrackerSynced.migrationMarker, '') != null) {
      return;
    }
    final String deviceId = context.hlcClock.deviceId;
    int seq = await context.writer.nextSeq(deviceId);
    final List<ChangeRecord> records = <ChangeRecord>[];
    final List<SyncedEntity> entities = <SyncedEntity>[];
    void add(String collection, String id, Map<String, Object?> fields, DateTime at) {
      final Hlc hlc = Hlc(wallTime: at.millisecondsSinceEpoch, counter: 0, deviceId: deviceId);
      final List<FieldChange> changes = ItemTrackerCodec.diff(null, fields);
      records.add(ChangeRecord(
        opId: _ids.newId(),
        deviceId: deviceId,
        seq: seq++,
        collection: collection,
        entityId: id,
        hlc: hlc,
        changes: changes,
      ));
      entities.add(SyncedEntity(collection: collection, id: id).apply(changes, hlc));
    }

    for (final IsarHouseholdItem item in await _isar.isarHouseholdItems.where().findAll()) {
      add(ItemTrackerCollections.items, item.id, SyncedEntityMapper.itemFields(item), item.deletedAt ?? item.updatedAt);
    }
    for (final IsarPhysicalIdentifier identifier in await _isar.isarPhysicalIdentifiers.where().findAll()) {
      add(
        ItemTrackerCollections.identifiers,
        identifier.id,
        SyncedEntityMapper.identifierFields(identifier),
        identifier.deletedAt ?? identifier.boundAt,
      );
    }
    for (final IsarItemEvent event in await _isar.isarItemEvents.where().findAll()) {
      add(
        ItemTrackerCollections.events,
        event.id,
        ItemTrackerCodec.eventFields(ItemDataMapper.fromIsarEvent(event)),
        event.timestamp,
      );
    }
    await _putSynced(<SyncedEntity>[
      ...entities.where((SyncedEntity entity) => entity.collection != ItemTrackerCollections.events),
      SyncedEntity(collection: IsarItemTrackerSynced.migrationMarker, id: ''),
    ]);
    await context.writer.append(records);
  }
}

class _SyncContext {
  _SyncContext(this.recorder, this.hlcClock, this.writer);

  final LocalSyncRecorder recorder;
  final HlcClock hlcClock;
  final IsarChangeLogWriter writer;
}
