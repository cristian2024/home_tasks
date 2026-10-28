import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../hierarchy/item_tree.dart';
import '../repositories/household_item_repository.dart';

/// Consultas de solo lectura sobre los objetos.
class GetItem {
  const GetItem(this._repository);

  final HouseholdItemRepository _repository;

  /// Lanza [ItemNotFoundException] si el objeto no existe.
  Future<HouseholdItem> call(String itemId) async =>
      await _repository.getById(itemId) ?? (throw ItemNotFoundException(itemId));
}

class WatchItem {
  const WatchItem(this._repository);

  final HouseholdItemRepository _repository;

  Stream<HouseholdItem?> call(String itemId) => _repository.watchById(itemId);
}

class WatchItems {
  const WatchItems(this._repository);

  final HouseholdItemRepository _repository;

  Stream<List<HouseholdItem>> call() => _repository.watchAll();
}

/// Todos los objetos como árbol (contenedores, rutas, niveles). Emite de nuevo
/// en cada cambio.
class WatchItemTree {
  const WatchItemTree(this._repository);

  final HouseholdItemRepository _repository;

  Stream<ItemTree> call() => _repository.watchAll().map(ItemTree.new);
}

class SearchItems {
  const SearchItems(this._repository);

  final HouseholdItemRepository _repository;

  /// Con una consulta vacía devuelve todos los objetos.
  Future<List<HouseholdItem>> call(String query) => _repository.searchByName(query.trim());
}

class WatchItemIdentifiers {
  const WatchItemIdentifiers(this._repository);

  final HouseholdItemRepository _repository;

  Stream<List<PhysicalIdentifier>> call(String itemId) => _repository.watchIdentifiers(itemId);
}

class WatchItemEvents {
  const WatchItemEvents(this._repository);

  final HouseholdItemRepository _repository;

  Stream<List<ItemEvent>> call(String itemId) => _repository.watchEvents(itemId);
}
