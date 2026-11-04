import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:storage_isar/adapter.dart';

import '../datasources/shopping_local_data_source.dart';
import '../mappers/shopping_data_mapper.dart';
import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../sync/isar_shopping_list_sync.dart';

/// [ShoppingListRepository] sobre Isar. Pasa `shoppingListRepositoryContract`.
///
/// Con [services] se sincroniza si la app compuso la sincronización (ver
/// [IsarShoppingListSync]): registra cada escritura en la misma transacción
/// y, como [ShoppingListSyncStore], sirve a `ShoppingListSyncParticipant`.
/// Pasa `shoppingListSyncContract`.
class IsarShoppingListRepository implements ShoppingListRepository, ShoppingListSyncStore {
  factory IsarShoppingListRepository(Isar isar, {ServiceLocator? services}) =>
      IsarShoppingListRepository._(IsarShoppingListSync(isar, services), isar);

  IsarShoppingListRepository._(this._sync, Isar isar) : _source = ShoppingLocalDataSource(isar, _sync);

  final ShoppingLocalDataSource _source;
  final IsarShoppingListSync _sync;

  @override
  Future<List<SyncedEntity>> syncedEntities(String collection) => _sync.syncedEntities(collection);

  @override
  Future<void> commitSync(ShoppingListSyncCommit commit) => _sync.commit(commit);

  @override
  Future<void> saveItem(ShoppingItem item) => _source.putItem(ShoppingDataMapper.toIsarItem(item));

  @override
  Future<ShoppingItem?> getItem(String id) async {
    final IsarShoppingItem? model = await _source.getItem(id);
    return model == null ? null : ShoppingDataMapper.fromIsarItem(model);
  }

  @override
  Future<List<ShoppingItem>> getItems() async => _items(await _source.getItems());

  @override
  Stream<List<ShoppingItem>> watchItems() => _source.watchItems().map(_items);

  @override
  Future<void> deleteItems(List<String> ids, {required DateTime deletedAt}) =>
      _source.deleteItems(ids, deletedAt.toUtc());

  @override
  Future<void> saveCategories(List<ShoppingCategory> categories) =>
      _source.putCategories(categories.map(ShoppingDataMapper.toIsarCategory).toList());

  @override
  Future<List<ShoppingCategory>> getCategories() async => _categories(await _source.getCategories());

  @override
  Stream<List<ShoppingCategory>> watchCategories() => _source.watchCategories().map(_categories);

  @override
  Future<void> deleteCategory(String id, {required DateTime updatedAt}) =>
      _source.deleteCategory(id, updatedAt.toUtc());

  @override
  Future<bool> seedDefaultCategories(List<ShoppingCategory> defaults) =>
      _source.seedCategories(defaults.map(ShoppingDataMapper.toIsarCategory).toList());

  @override
  Future<void> recordPurchase(ShoppingItem item, ShoppingPurchase purchase) => _source.putItemWithPurchase(
        ShoppingDataMapper.toIsarItem(item),
        ShoppingDataMapper.toIsarPurchase(purchase),
      );

  @override
  Future<void> undoPurchase(ShoppingItem item, String purchaseId, {required DateTime deletedAt}) =>
      _source.putItemAndDeletePurchase(ShoppingDataMapper.toIsarItem(item), purchaseId, deletedAt.toUtc());

  @override
  Future<List<ShoppingPurchase>> getPurchases(String itemId) async =>
      (await _source.getPurchases(itemId)).map(ShoppingDataMapper.fromIsarPurchase).toList();

  static List<ShoppingItem> _items(List<IsarShoppingItem> models) =>
      models.map(ShoppingDataMapper.fromIsarItem).toList();

  static List<ShoppingCategory> _categories(List<IsarShoppingCategory> models) =>
      models.map(ShoppingDataMapper.fromIsarCategory).toList();
}
