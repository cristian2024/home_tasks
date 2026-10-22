/// Dobles de prueba del plugin para widget tests y apps de ejemplo.
library;

import 'dart:async';

import 'plugin_item_tracker.dart';

/// [HouseholdItemRepository] en memoria con la misma semántica que la
/// implementación Isar: unicidad de identificadores, orden de los listados y
/// streams que emiten al suscribirse y en cada cambio.
class InMemoryHouseholdItemRepository implements HouseholdItemRepository {
  final Map<String, HouseholdItem> _items = {};
  final Map<String, PhysicalIdentifier> _identifiers = {};
  final Map<String, ItemEvent> _events = {};
  final StreamController<void> _changes = StreamController.broadcast();

  String _identifierKey(String rawValue, IdentifierType type) => '${type.name}:$rawValue';

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  void _checkIdentifier(PhysicalIdentifier identifier) {
    final existing = _identifiers[_identifierKey(identifier.rawValue, identifier.type)];
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
    for (final event in events) {
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
  Stream<HouseholdItem?> watchById(String id) => _watch(() => _items[id]);

  List<HouseholdItem> _sortedItems() => _items.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Stream<List<HouseholdItem>> watchAll() => _watch(_sortedItems);

  @override
  Future<List<HouseholdItem>> searchByName(String query) async {
    final needle = query.toLowerCase();
    return _sortedItems().where((item) => item.name.toLowerCase().contains(needle)).toList();
  }

  @override
  Future<PhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type) async =>
      _identifiers[_identifierKey(rawValue, type)];

  @override
  Stream<List<PhysicalIdentifier>> watchIdentifiers(String itemId) => _watch(
        () => _identifiers.values.where((i) => i.itemId == itemId).toList()
          ..sort((a, b) => a.boundAt.compareTo(b.boundAt)),
      );

  @override
  Future<void> bindIdentifier(PhysicalIdentifier identifier, ItemEvent event) async {
    _checkIdentifier(identifier);
    _identifiers[_identifierKey(identifier.rawValue, identifier.type)] = identifier;
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
        () => _events.values.where((e) => e.itemId == itemId).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      );
}
