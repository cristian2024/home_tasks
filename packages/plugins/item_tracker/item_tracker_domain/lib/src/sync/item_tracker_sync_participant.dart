import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../repositories/household_item_repository.dart';
import 'item_tracker_codec.dart';
import 'item_tracker_resolver.dart';
import 'item_tracker_sync_store.dart';

/// item_tracker en la sincronización (spec §10.4.5). Trabaja sobre los
/// contratos del repositorio, así que sirve con cualquier implementación.
///
/// - [applyRemote] fusiona los cambios en las copias sincronizadas, calcula
///   con [ItemTrackerResolver] lo que debe leer la app y lo guarda con
///   [ItemTrackerSyncStore.commitSync]. Devuelve los conflictos actuales.
/// - [resolveConflict] aplica la opción elegida con escrituras normales del
///   repositorio, que se registran y se sincronizan.
class ItemTrackerSyncParticipant implements SyncParticipant {
  ItemTrackerSyncParticipant({
    required ItemTrackerSyncStore store,
    required HouseholdItemRepository repository,
    ItemTrackerResolver resolver = const ItemTrackerResolver(),
    IdGenerator ids = const UuidV4Generator(),
    Clock clock = const SystemClock(),
  })  : _store = store,
        _repository = repository,
        _resolver = resolver,
        _ids = ids,
        _clock = clock;

  final ItemTrackerSyncStore _store;
  final HouseholdItemRepository _repository;
  final ItemTrackerResolver _resolver;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Set<String> get collections => ItemTrackerCollections.all;

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async {
    final Map<String, SyncedEntity> items = await _load(ItemTrackerCollections.items);
    final Map<String, SyncedEntity> identifiers = await _load(ItemTrackerCollections.identifiers);
    final ItemTrackerView before = _resolver.resolve(items.values, identifiers.values);
    final Map<String, SyncedEntity> changed = <String, SyncedEntity>{};
    final Map<String, ItemEvent> events = <String, ItemEvent>{};
    for (final ChangeRecord record in records) {
      if (record.collection == ItemTrackerCollections.events) {
        final ItemEvent? event =
            ItemTrackerCodec.eventOf(SyncedEntity(collection: record.collection, id: record.entityId).merge(record));
        if (event != null) {
          events[event.id] = event;
        }
        continue;
      }
      final Map<String, SyncedEntity> entities =
          record.collection == ItemTrackerCollections.items ? items : identifiers;
      final SyncedEntity current =
          entities[record.entityId] ?? SyncedEntity(collection: record.collection, id: record.entityId);
      final SyncedEntity merged = current.merge(record);
      if (merged != current) {
        entities[record.entityId] = merged;
        changed['${record.collection}|${record.entityId}'] = merged;
      }
    }
    final ItemTrackerView after = _resolver.resolve(items.values, identifiers.values);
    final ItemTrackerSyncCommit commit = ItemTrackerSyncCommit(
      entities: changed.values.toList(),
      items: <ResolvedItem>[
        for (final MapEntry<String, ResolvedItem>(:String key, :ResolvedItem value) in after.items.entries)
          if (before.items[key] != value) value,
      ],
      identifiers: <ResolvedIdentifier>[
        for (final MapEntry<String, ResolvedIdentifier>(:String key, :ResolvedIdentifier value)
            in after.identifiers.entries)
          if (before.identifiers[key] != value) value,
      ],
      events: events.values.toList(),
    );
    if (!commit.isEmpty) {
      await _store.commitSync(commit);
    }
    return after.conflicts;
  }

  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {
    switch (conflict.kind) {
      case ItemTrackerResolver.identifierBoundTwice:
        await _keepIdentifier(conflict, optionId);
      case ItemTrackerResolver.containerDeleted when optionId == ItemTrackerResolver.deleteOption:
        await _repository.deleteItems(<String>[conflict.entityIds.first], deletedAt: _clock.nowUtc(), events: const <ItemEvent>[]);
      case ItemTrackerResolver.containerDeleted || ItemTrackerResolver.moveReverted:
        await _confirmPlacement(conflict.entityIds.first);
    }
  }

  /// Registra como propio el contenedor efectivo del objeto, para que el de
  /// la copia sincronizada coincida con lo que se ve.
  Future<void> _confirmPlacement(String itemId) async {
    final HouseholdItem? item = await _repository.getById(itemId);
    if (item != null) {
      await _repository.moveItem(item, const <ItemEvent>[]);
    }
  }

  /// Con la opción provisional no hay nada que hacer: el otro identificador ya
  /// está quitado y no vuelve. Con la otra, se quita el que se había quedado y
  /// se vuelve a asociar el valor al objeto elegido.
  Future<void> _keepIdentifier(SyncConflict conflict, String optionId) async {
    if (optionId == conflict.provisionalOptionId) {
      return;
    }
    final Map<String, String> chosen =
        conflict.options.firstWhere((ConflictOption option) => option.id == optionId).details;
    final String holderId = conflict.provisionalOptionId.substring(ItemTrackerResolver.keepPrefix.length);
    final DateTime now = _clock.nowUtc();
    final PhysicalIdentifier? holder = await _repository.getIdentifier(holderId);
    if (holder != null) {
      await _repository.unbindIdentifier(holderId, deletedAt: now, event: _event(holder, ItemEventKind.identifierUnbound, now));
    }
    final PhysicalIdentifier rebound = PhysicalIdentifier(
      id: _ids.newId(),
      rawValue: chosen['rawValue']!,
      type: IdentifierType.values.byName(chosen['type']!),
      itemId: chosen['itemId']!,
      boundAt: now,
    );
    await _repository.bindIdentifier(rebound, _event(rebound, ItemEventKind.identifierBound, now));
  }

  ItemEvent _event(PhysicalIdentifier identifier, ItemEventKind kind, DateTime now) => ItemEvent(
        id: _ids.newId(),
        itemId: identifier.itemId,
        kind: kind,
        title: identifier.type.name,
        description: identifier.rawValue,
        timestamp: now,
      );

  Future<Map<String, SyncedEntity>> _load(String collection) async => <String, SyncedEntity>{
        for (final SyncedEntity entity in await _store.syncedEntities(collection)) entity.id: entity,
      };
}
