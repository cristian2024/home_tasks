import 'package:core_storage/core_storage.dart';

import '../../domain/entities/physical_identifier.dart';
import '../models/isar_household_item.dart';
import '../models/isar_item_event.dart';
import '../models/isar_physical_identifier.dart';

/// Acceso a Isar del plugin. Toda escritura va en una transacción explícita
/// (spec §10.1).
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
    List<IsarItemEvent> events = const [],
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

  Future<void> saveEvent(IsarItemEvent event) async {
    await _isar.writeTxn(() => _events.putById(event));
  }

  Future<IsarHouseholdItem?> getItem(String id) => _items.getById(id);

  Stream<IsarHouseholdItem?> watchItem(String id) => _items
      .where()
      .idEqualTo(id)
      .watch(fireImmediately: true)
      .map((rows) => rows.isEmpty ? null : rows.first);

  Stream<List<IsarHouseholdItem>> watchItems() =>
      _items.where().sortByUpdatedAtDesc().watch(fireImmediately: true);

  Future<List<IsarHouseholdItem>> searchItems(String query) =>
      _items.filter().nameContains(query, caseSensitive: false).sortByUpdatedAtDesc().findAll();

  Future<IsarPhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type) =>
      _identifiers.where().rawValueTypeEqualTo(rawValue, type).findFirst();

  Stream<List<IsarPhysicalIdentifier>> watchIdentifiers(String itemId) =>
      _identifiers.where().itemIdEqualTo(itemId).sortByBoundAt().watch(fireImmediately: true);

  Stream<List<IsarItemEvent>> watchEvents(String itemId) =>
      _events.where().itemIdEqualToAnyTimestamp(itemId).sortByTimestampDesc().watch(fireImmediately: true);
}
