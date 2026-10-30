import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/adapter.dart';

import '../models/isar_household_item.dart';
import '../models/isar_item_event.dart';
import '../models/isar_physical_identifier.dart';

/// Acceso a las colecciones Isar de item_tracker. Toda escritura va en una
/// transacción explícita (spec §10.1).
class IsarLocalDataSource {
  IsarLocalDataSource(this._isar);

  final Isar _isar;

  IsarCollection<IsarHouseholdItem> get _items => _isar.isarHouseholdItems;
  IsarCollection<IsarPhysicalIdentifier> get _identifiers => _isar.isarPhysicalIdentifiers;
  IsarCollection<IsarItemEvent> get _events => _isar.isarItemEvents;

  /// Escribe todo en una sola transacción. Si [identifier] ya existe, Isar
  /// lanza un error de índice único y no se guarda nada.
  Future<void> saveItemWithIdentifier(
    IsarHouseholdItem item, {
    IsarPhysicalIdentifier? identifier,
    List<IsarItemEvent> events = const <IsarItemEvent>[],
  }) async {
    await _isar.writeTxn(() async {
      await _items.putById(item);
      if (identifier != null) {
        await _identifiers.putById(identifier);
      }
      await _events.putAllById(events);
    });
  }

  /// Igual que [saveItemWithIdentifier] para un identificador sobre un objeto
  /// existente.
  Future<void> saveIdentifierWithEvent(IsarPhysicalIdentifier identifier, IsarItemEvent event) async {
    await _isar.writeTxn(() async {
      await _identifiers.putById(identifier);
      await _events.putById(event);
    });
  }

  /// Marca el identificador como quitado y guarda [event] en una sola
  /// transacción. No hace nada si el identificador no existe.
  Future<void> softDeleteIdentifierWithEvent(String identifierId, DateTime deletedAt, IsarItemEvent event) async {
    await _isar.writeTxn(() async {
      final IsarPhysicalIdentifier? identifier = await _identifiers.getById(identifierId);
      if (identifier == null || identifier.isDeleted) {
        return;
      }
      identifier
        ..deletedId = identifier.id
        ..deletedAt = deletedAt;
      await _identifiers.putById(identifier);
      await _events.putById(event);
    });
  }

  /// Marca los objetos [itemIds] y sus identificadores activos como borrados,
  /// guarda [moved] y [events], todo en una sola transacción. Ignora los
  /// objetos que no existen o ya se borraron.
  Future<void> softDeleteItems(
    List<String> itemIds,
    DateTime deletedAt, {
    required List<IsarHouseholdItem> moved,
    required List<IsarItemEvent> events,
  }) async {
    await _isar.writeTxn(() async {
      for (final String id in itemIds) {
        final IsarHouseholdItem? item = await _items.getById(id);
        if (item == null || item.isDeleted) {
          continue;
        }
        item.deletedAt = deletedAt;
        await _items.putById(item);
        final List<IsarPhysicalIdentifier> identifiers =
            await _identifiers.where().itemIdEqualTo(id).filter().deletedIdIsNull().findAll();
        for (final IsarPhysicalIdentifier identifier in identifiers) {
          identifier
            ..deletedId = identifier.id
            ..deletedAt = deletedAt;
        }
        await _identifiers.putAllById(identifiers);
      }
      await _items.putAllById(moved);
      await _events.putAllById(events);
    });
  }

  Future<void> saveEvent(IsarItemEvent event) async {
    await _isar.writeTxn(() => _events.putById(event));
  }

  /// Objeto activo con ese [id].
  Future<IsarHouseholdItem?> getItem(String id) async {
    final IsarHouseholdItem? item = await _items.getById(id);
    return item == null || item.isDeleted ? null : item;
  }

  /// Objetos activos.
  Future<List<IsarHouseholdItem>> getItems() => _items.filter().deletedAtIsNull().findAll();

  Stream<IsarHouseholdItem?> watchItem(String id) => _items
      .where()
      .idEqualTo(id)
      .filter()
      .deletedAtIsNull()
      .watch(fireImmediately: true)
      .map((List<IsarHouseholdItem> rows) => rows.isEmpty ? null : rows.first);

  Stream<List<IsarHouseholdItem>> watchItems() =>
      _items.filter().deletedAtIsNull().sortByUpdatedAtDesc().watch(fireImmediately: true);

  Future<List<IsarHouseholdItem>> searchItems(String query) => _items
      .filter()
      .deletedAtIsNull()
      .nameContains(query, caseSensitive: false)
      .sortByUpdatedAtDesc()
      .findAll();

  /// Identificador activo con ese valor y tipo.
  Future<IsarPhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type) =>
      _identifiers.where().rawValueTypeDeletedIdEqualTo(rawValue, type, null).findFirst();

  /// Identificador activo con ese [id].
  Future<IsarPhysicalIdentifier?> getIdentifier(String id) async {
    final IsarPhysicalIdentifier? identifier = await _identifiers.getById(id);
    return identifier == null || identifier.isDeleted ? null : identifier;
  }

  /// Identificadores activos del objeto.
  Stream<List<IsarPhysicalIdentifier>> watchIdentifiers(String itemId) => _identifiers
      .where()
      .itemIdEqualTo(itemId)
      .filter()
      .deletedIdIsNull()
      .sortByBoundAt()
      .watch(fireImmediately: true);

  Stream<List<IsarItemEvent>> watchEvents(String itemId) =>
      _events.where().itemIdEqualToAnyTimestamp(itemId).sortByTimestampDesc().watch(fireImmediately: true);
}
