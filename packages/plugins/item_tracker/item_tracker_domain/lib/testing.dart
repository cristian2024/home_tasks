/// Dobles de prueba del dominio y tests de contrato reutilizables, para los
/// tests y las apps de ejemplo de otros paquetes.
library;

import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import 'item_tracker_domain.dart';

export 'src/testing/household_item_repository_contract.dart';
export 'src/testing/item_tracker_sync_fixtures.dart';

/// [HouseholdItemRepository] en memoria. Cumple
/// [householdItemRepositoryContract]: unicidad de identificadores, orden de
/// los listados y streams que emiten al suscribirse y en cada cambio.
///
/// Con [hlcClock] y [changeLog] además se sincroniza: cada escritura local
/// actualiza sus copias sincronizadas y añade sus registros al log, y como
/// [ItemTrackerSyncStore] sirve a `ItemTrackerSyncParticipant`.
class InMemoryHouseholdItemRepository implements HouseholdItemRepository, ItemTrackerSyncStore {
  InMemoryHouseholdItemRepository({HlcClock? hlcClock, ChangeLog? changeLog, IdGenerator ids = const UuidV4Generator()})
      : _recorder = hlcClock == null ? null : LocalSyncRecorder(hlcClock: hlcClock, ids: ids),
        _changeLog = changeLog;

  final LocalSyncRecorder? _recorder;
  final ChangeLog? _changeLog;
  final Map<String, SyncedEntity> _synced = <String, SyncedEntity>{};

  final Map<String, HouseholdItem> _items = <String, HouseholdItem>{};
  final Map<String, PhysicalIdentifier> _identifiers = <String, PhysicalIdentifier>{};
  final Map<String, ItemEvent> _events = <String, ItemEvent>{};

  /// Identificadores quitados (borrado lógico), con el momento en que se quitaron.
  final List<({PhysicalIdentifier identifier, DateTime deletedAt})> deletedIdentifiers =
      <({PhysicalIdentifier identifier, DateTime deletedAt})>[];
  /// Objetos borrados (borrado lógico), con el momento en que se borraron.
  final List<({HouseholdItem item, DateTime deletedAt})> deletedItems = <({HouseholdItem item, DateTime deletedAt})>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  String _identifierKey(String rawValue, IdentifierType type) => '${type.name}:$rawValue';

  /// Lee el estado y se suscribe a los cambios en el mismo momento en que
  /// alguien escucha, como los watchers de una base de datos. Con un
  /// `async*` las dos cosas pasan una microtarea después, y una escritura
  /// hecha justo tras suscribirse se perdería.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
      },
      // No devuelve el futuro de `cancel()`: `first` lo espera, y con el reloj
      // simulado de los widget tests no se completa.
      onCancel: () {
        unawaited(changes?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  void _checkIdentifier(PhysicalIdentifier identifier) {
    final PhysicalIdentifier? existing = _identifiers[_identifierKey(identifier.rawValue, identifier.type)];
    if (existing != null) {
      throw IdentifierAlreadyBoundException(
        rawValue: identifier.rawValue,
        type: identifier.type,
        boundItemId: existing.itemId,
      );
    }
  }

  @override
  Future<void> createItem(HouseholdItem item, {PhysicalIdentifier? identifier, required List<ItemEvent> events}) async {
    if (identifier != null) {
      _checkIdentifier(identifier);
      _identifiers[_identifierKey(identifier.rawValue, identifier.type)] = identifier;
    }
    _items[item.id] = item;
    for (final ItemEvent event in events) {
      _events[event.id] = event;
    }
    await _record(<LocalSyncWrite>[
      _itemWrite(item),
      if (identifier != null) _identifierWrite(identifier),
      ...events.map(_eventWrite),
    ]);
    _changes.add(null);
  }

  @override
  Future<void> updateItem(HouseholdItem item, ItemEvent event) async {
    _items[item.id] = item;
    _events[event.id] = event;
    await _record(<LocalSyncWrite>[_itemWrite(item), _eventWrite(event)]);
    _changes.add(null);
  }

  @override
  Future<HouseholdItem?> getById(String id) async => _items[id];

  @override
  Future<List<HouseholdItem>> getAll() async => _items.values.toList();

  @override
  Future<void> moveItem(HouseholdItem item, List<ItemEvent> events) async {
    _items[item.id] = item;
    for (final ItemEvent event in events) {
      _events[event.id] = event;
    }
    await _record(<LocalSyncWrite>[_itemWrite(item), ...events.map(_eventWrite)]);
    _changes.add(null);
  }

  @override
  Future<void> deleteItems(
    List<String> itemIds, {
    required DateTime deletedAt,
    List<HouseholdItem> moved = const <HouseholdItem>[],
    required List<ItemEvent> events,
  }) async {
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[];
    for (final String id in itemIds) {
      final HouseholdItem? item = _items.remove(id);
      if (item == null) {
        continue;
      }
      deletedItems.add((item: item, deletedAt: deletedAt));
      writes.add(_itemWrite(item, deletedAt: deletedAt));
      final List<PhysicalIdentifier> identifiers =
          _identifiers.values.where((PhysicalIdentifier identifier) => identifier.itemId == id).toList();
      for (final PhysicalIdentifier identifier in identifiers) {
        _identifiers.remove(_identifierKey(identifier.rawValue, identifier.type));
        deletedIdentifiers.add((identifier: identifier, deletedAt: deletedAt));
        writes.add(_identifierWrite(identifier, deletedAt: deletedAt));
      }
    }
    for (final HouseholdItem item in moved) {
      _items[item.id] = item;
    }
    for (final ItemEvent event in events) {
      _events[event.id] = event;
    }
    await _record(<LocalSyncWrite>[...writes, ...moved.map(_itemWrite), ...events.map(_eventWrite)]);
    _changes.add(null);
  }

  @override
  Stream<HouseholdItem?> watchById(String id) => _watch(() => _items[id]);

  List<HouseholdItem> _sortedItems() =>
      _items.values.toList()..sort((HouseholdItem a, HouseholdItem b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Stream<List<HouseholdItem>> watchAll() => _watch(_sortedItems);

  @override
  Future<List<HouseholdItem>> searchByName(String query) async {
    final String needle = query.toLowerCase();
    return _sortedItems().where((HouseholdItem item) => item.name.toLowerCase().contains(needle)).toList();
  }

  @override
  Future<PhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type) async =>
      _identifiers[_identifierKey(rawValue, type)];

  @override
  Future<PhysicalIdentifier?> getIdentifier(String id) async =>
      _identifiers.values.where((PhysicalIdentifier identifier) => identifier.id == id).firstOrNull;

  @override
  Stream<List<PhysicalIdentifier>> watchIdentifiers(String itemId) => _watch(
        () => _identifiers.values.where((PhysicalIdentifier i) => i.itemId == itemId).toList()
          ..sort((PhysicalIdentifier a, PhysicalIdentifier b) => a.boundAt.compareTo(b.boundAt)),
      );

  @override
  Future<void> bindIdentifier(PhysicalIdentifier identifier, ItemEvent event) async {
    _checkIdentifier(identifier);
    _identifiers[_identifierKey(identifier.rawValue, identifier.type)] = identifier;
    _events[event.id] = event;
    await _record(<LocalSyncWrite>[_identifierWrite(identifier), _eventWrite(event)]);
    _changes.add(null);
  }

  @override
  Future<void> unbindIdentifier(String identifierId, {required DateTime deletedAt, required ItemEvent event}) async {
    final PhysicalIdentifier? identifier = await getIdentifier(identifierId);
    if (identifier == null) {
      return;
    }
    _identifiers.remove(_identifierKey(identifier.rawValue, identifier.type));
    deletedIdentifiers.add((identifier: identifier, deletedAt: deletedAt));
    _events[event.id] = event;
    await _record(<LocalSyncWrite>[_identifierWrite(identifier, deletedAt: deletedAt), _eventWrite(event)]);
    _changes.add(null);
  }

  @override
  Future<void> addEvent(ItemEvent event) async {
    _events[event.id] = event;
    await _record(<LocalSyncWrite>[_eventWrite(event)]);
    _changes.add(null);
  }

  @override
  Stream<List<ItemEvent>> watchEvents(String itemId) => _watch(
        () => _events.values.where((ItemEvent e) => e.itemId == itemId).toList()
          ..sort((ItemEvent a, ItemEvent b) => b.timestamp.compareTo(a.timestamp)),
      );

  @override
  Future<List<SyncedEntity>> syncedEntities(String collection) async => <SyncedEntity>[
        for (final SyncedEntity entity in _synced.values)
          if (entity.collection == collection) entity,
      ];

  @override
  Future<void> commitSync(ItemTrackerSyncCommit commit) async {
    for (final SyncedEntity entity in commit.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    for (final ResolvedItem resolved in commit.items) {
      final HouseholdItem item = resolved.item;
      _items.remove(item.id);
      deletedItems.removeWhere((({HouseholdItem item, DateTime deletedAt}) deleted) => deleted.item.id == item.id);
      if (resolved.deletedAt case final DateTime deletedAt) {
        deletedItems.add((item: item, deletedAt: deletedAt));
      } else {
        _items[item.id] = item;
      }
    }
    for (final ResolvedIdentifier resolved in commit.identifiers) {
      final PhysicalIdentifier identifier = resolved.identifier;
      _identifiers.removeWhere((String _, PhysicalIdentifier other) => other.id == identifier.id);
      deletedIdentifiers.removeWhere(
        (({PhysicalIdentifier identifier, DateTime deletedAt}) deleted) => deleted.identifier.id == identifier.id,
      );
      if (resolved.deletedAt case final DateTime deletedAt) {
        deletedIdentifiers.add((identifier: identifier, deletedAt: deletedAt));
      } else {
        _identifiers[_identifierKey(identifier.rawValue, identifier.type)] = identifier;
      }
    }
    for (final ItemEvent event in commit.events) {
      _events[event.id] = event;
    }
    _changes.add(null);
  }

  LocalSyncWrite _itemWrite(HouseholdItem item, {DateTime? deletedAt}) =>
      _write(ItemTrackerCollections.items, item.id, ItemTrackerCodec.itemFields(item, deletedAt: deletedAt));

  LocalSyncWrite _identifierWrite(PhysicalIdentifier identifier, {DateTime? deletedAt}) => _write(
        ItemTrackerCollections.identifiers,
        identifier.id,
        ItemTrackerCodec.identifierFields(identifier, deletedAt: deletedAt),
      );

  LocalSyncWrite _eventWrite(ItemEvent event) =>
      _write(ItemTrackerCollections.events, event.id, ItemTrackerCodec.eventFields(event));

  LocalSyncWrite _write(String collection, String id, Map<String, Object?> fields) =>
      LocalSyncWrite(collection: collection, id: id, fields: fields, current: _synced['$collection|$id']);

  /// Con sincronización, actualiza las copias y añade los registros al log.
  Future<void> _record(List<LocalSyncWrite> writes) async {
    final LocalSyncRecorder? recorder = _recorder;
    final ChangeLog? log = _changeLog;
    if (recorder == null || log == null) {
      return;
    }
    final LocalSyncChanges changes = recorder.record(writes, nextSeq: (await log.vector())[recorder.deviceId] + 1);
    for (final SyncedEntity entity in changes.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    await log.append(changes.records);
  }

  Future<void> close() => _changes.close();
}
