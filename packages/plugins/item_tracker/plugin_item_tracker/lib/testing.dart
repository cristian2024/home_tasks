/// Dobles de prueba del plugin para widget tests y apps de ejemplo.
library;

import 'dart:async';

import 'plugin_item_tracker.dart';

/// [HouseholdItemRepository] en memoria con la misma semántica que la
/// implementación Isar: unicidad de identificadores, orden de los listados y
/// streams que emiten al suscribirse y en cada cambio.
class InMemoryHouseholdItemRepository implements HouseholdItemRepository {
  final Map<String, HouseholdItem> _items = <String, HouseholdItem>{};
  final Map<String, PhysicalIdentifier> _identifiers = <String, PhysicalIdentifier>{};
  final Map<String, ItemEvent> _events = <String, ItemEvent>{};

  /// Identificadores quitados (borrado lógico), con el momento en que se quitaron.
  final List<({PhysicalIdentifier identifier, DateTime deletedAt})> deletedIdentifiers =
      <({PhysicalIdentifier identifier, DateTime deletedAt})>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  String _identifierKey(String rawValue, IdentifierType type) => '${type.name}:$rawValue';

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
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
    _changes.add(null);
  }

  @override
  Future<void> updateItem(HouseholdItem item, ItemEvent event) async {
    _items[item.id] = item;
    _events[event.id] = event;
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
    _changes.add(null);
  }

  @override
  Future<void> addEvent(ItemEvent event) async {
    _events[event.id] = event;
    _changes.add(null);
  }

  @override
  Stream<List<ItemEvent>> watchEvents(String itemId) => _watch(
        () => _events.values.where((ItemEvent e) => e.itemId == itemId).toList()
          ..sort((ItemEvent a, ItemEvent b) => b.timestamp.compareTo(a.timestamp)),
      );
}
