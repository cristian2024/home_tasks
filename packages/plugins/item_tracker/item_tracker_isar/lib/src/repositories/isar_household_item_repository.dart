import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:storage_isar/adapter.dart';

import '../datasources/isar_local_data_source.dart';
import '../mappers/item_data_mapper.dart';
import '../models/isar_household_item.dart';
import '../models/isar_item_event.dart';
import '../models/isar_physical_identifier.dart';

/// [HouseholdItemRepository] sobre Isar. Pasa
/// `householdItemRepositoryContract`.
class IsarHouseholdItemRepository implements HouseholdItemRepository {
  IsarHouseholdItemRepository(Isar isar) : _source = IsarLocalDataSource(isar);

  final IsarLocalDataSource _source;

  @override
  Future<void> createItem(
    HouseholdItem item, {
    PhysicalIdentifier? identifier,
    required List<ItemEvent> events,
  }) =>
      _guardIdentifier(
        identifier,
        () => _source.saveItemWithIdentifier(
          ItemDataMapper.toIsarItem(item),
          identifier: identifier == null ? null : ItemDataMapper.toIsarIdentifier(identifier),
          events: <IsarItemEvent>[for (final ItemEvent event in events) ItemDataMapper.toIsarEvent(event)],
        ),
      );

  @override
  Future<void> updateItem(HouseholdItem item, ItemEvent event) => _source.saveItemWithIdentifier(
        ItemDataMapper.toIsarItem(item),
        events: <IsarItemEvent>[ItemDataMapper.toIsarEvent(event)],
      );

  @override
  Future<HouseholdItem?> getById(String id) async {
    final IsarHouseholdItem? model = await _source.getItem(id);
    return model == null ? null : ItemDataMapper.fromIsarItem(model);
  }

  @override
  Future<List<HouseholdItem>> getAll() async => (await _source.getItems()).map(ItemDataMapper.fromIsarItem).toList();

  @override
  Future<void> moveItem(HouseholdItem item, List<ItemEvent> events) => _source.saveItemWithIdentifier(
        ItemDataMapper.toIsarItem(item),
        events: <IsarItemEvent>[for (final ItemEvent event in events) ItemDataMapper.toIsarEvent(event)],
      );

  @override
  Future<void> deleteItems(
    List<String> itemIds, {
    required DateTime deletedAt,
    List<HouseholdItem> moved = const <HouseholdItem>[],
    required List<ItemEvent> events,
  }) =>
      _source.softDeleteItems(
        itemIds,
        deletedAt.toUtc(),
        moved: <IsarHouseholdItem>[for (final HouseholdItem item in moved) ItemDataMapper.toIsarItem(item)],
        events: <IsarItemEvent>[for (final ItemEvent event in events) ItemDataMapper.toIsarEvent(event)],
      );

  @override
  Stream<HouseholdItem?> watchById(String id) =>
      _source
          .watchItem(id)
          .map((IsarHouseholdItem? model) => model == null ? null : ItemDataMapper.fromIsarItem(model));

  @override
  Stream<List<HouseholdItem>> watchAll() =>
      _source.watchItems().map((List<IsarHouseholdItem> models) => models.map(ItemDataMapper.fromIsarItem).toList());

  @override
  Future<List<HouseholdItem>> searchByName(String query) async =>
      (await _source.searchItems(query)).map(ItemDataMapper.fromIsarItem).toList();

  @override
  Future<PhysicalIdentifier?> findIdentifier(String rawValue, IdentifierType type) async {
    final IsarPhysicalIdentifier? model = await _source.findIdentifier(rawValue, type);
    return model == null ? null : ItemDataMapper.fromIsarIdentifier(model);
  }

  @override
  Future<PhysicalIdentifier?> getIdentifier(String id) async {
    final IsarPhysicalIdentifier? model = await _source.getIdentifier(id);
    return model == null ? null : ItemDataMapper.fromIsarIdentifier(model);
  }

  @override
  Stream<List<PhysicalIdentifier>> watchIdentifiers(String itemId) => _source
      .watchIdentifiers(itemId)
      .map((List<IsarPhysicalIdentifier> models) => models.map(ItemDataMapper.fromIsarIdentifier).toList());

  @override
  Future<void> bindIdentifier(PhysicalIdentifier identifier, ItemEvent event) => _guardIdentifier(
        identifier,
        () => _source.saveIdentifierWithEvent(
          ItemDataMapper.toIsarIdentifier(identifier),
          ItemDataMapper.toIsarEvent(event),
        ),
      );

  @override
  Future<void> unbindIdentifier(String identifierId, {required DateTime deletedAt, required ItemEvent event}) =>
      _source.softDeleteIdentifierWithEvent(identifierId, deletedAt.toUtc(), ItemDataMapper.toIsarEvent(event));

  @override
  Future<void> addEvent(ItemEvent event) => _source.saveEvent(ItemDataMapper.toIsarEvent(event));

  @override
  Stream<List<ItemEvent>> watchEvents(String itemId) =>
      _source
          .watchEvents(itemId)
          .map((List<IsarItemEvent> models) => models.map(ItemDataMapper.fromIsarEvent).toList());

  /// Traduce la violación del índice único (otra escritura asoció el mismo
  /// identificador entre la comprobación y la transacción) al error de dominio.
  Future<void> _guardIdentifier(PhysicalIdentifier? identifier, Future<void> Function() write) async {
    try {
      await write();
    } on IsarError catch (error) {
      if (identifier == null || !_isUniqueViolation(error)) {
        rethrow;
      }
      final IsarPhysicalIdentifier? existing = await _source.findIdentifier(identifier.rawValue, identifier.type);
      throw IdentifierAlreadyBoundException(
        rawValue: identifier.rawValue,
        type: identifier.type,
        boundItemId: existing?.itemId ?? identifier.itemId,
      );
    }
  }

  /// En web Isar lanza [IsarUniqueViolationError]; en nativo, un [IsarError]
  /// genérico con este mensaje.
  static bool _isUniqueViolation(IsarError error) =>
      error is IsarUniqueViolationError || error.message.contains('Unique index violated');
}
