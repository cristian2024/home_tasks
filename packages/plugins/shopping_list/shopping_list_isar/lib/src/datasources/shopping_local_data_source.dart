import 'package:storage_isar/adapter.dart';

import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../models/isar_shopping_list_flag.dart';
import '../models/isar_shopping_purchase.dart';

/// Acceso a las colecciones Isar de la lista de compras. Toda escritura va en
/// una transacción explícita (spec §10.1).
class ShoppingLocalDataSource {
  ShoppingLocalDataSource(this._isar);

  /// Marca de que ya se crearon las categorías por defecto.
  static const String defaultsSeededFlag = 'defaultCategoriesSeeded';

  final Isar _isar;

  IsarCollection<IsarShoppingItem> get _items => _isar.isarShoppingItems;
  IsarCollection<IsarShoppingCategory> get _categories => _isar.isarShoppingCategorys;
  IsarCollection<IsarShoppingPurchase> get _purchases => _isar.isarShoppingPurchases;
  IsarCollection<IsarShoppingListFlag> get _flags => _isar.isarShoppingListFlags;

  Future<void> putItem(IsarShoppingItem item) => _isar.writeTxn(() => _items.putById(item));

  Future<IsarShoppingItem?> getItem(String id) => _items.getById(id);

  Future<List<IsarShoppingItem>> getItems() => _items.where().findAll();

  Stream<List<IsarShoppingItem>> watchItems() => _items.where().watch(fireImmediately: true);

  /// Borra los items y sus compras en una sola transacción.
  Future<void> deleteItems(List<String> ids) => _isar.writeTxn(() async {
        await _items.deleteAllById(ids);
        for (final String id in ids) {
          await _purchases.where().itemIdEqualToAnyPurchasedAt(id).deleteAll();
        }
      });

  Future<void> putCategories(List<IsarShoppingCategory> categories) =>
      _isar.writeTxn(() => _categories.putAllById(categories));

  Future<List<IsarShoppingCategory>> getCategories() => _categories.where().sortBySortOrder().thenById().findAll();

  Stream<List<IsarShoppingCategory>> watchCategories() =>
      _categories.where().sortBySortOrder().thenById().watch(fireImmediately: true);

  /// Borra la categoría y la quita de sus items (con [updatedAt]) en una sola
  /// transacción. No hace nada si no existe.
  Future<void> deleteCategory(String id, DateTime updatedAt) => _isar.writeTxn(() async {
        if (!await _categories.deleteById(id)) {
          return;
        }
        final List<IsarShoppingItem> items = await _items.where().categoryIdsElementEqualTo(id).findAll();
        for (final IsarShoppingItem item in items) {
          item
            ..categoryIds = <String>[for (final String categoryId in item.categoryIds) if (categoryId != id) categoryId]
            ..updatedAt = updatedAt;
        }
        await _items.putAllById(items);
      });

  /// Guarda [categories] y la marca de categorías creadas, solo si la marca
  /// no existe. Devuelve si las guardó.
  Future<bool> seedCategories(List<IsarShoppingCategory> categories) => _isar.writeTxn(() async {
        if (await _flags.getByKey(defaultsSeededFlag) != null) {
          return false;
        }
        await _flags.putByKey(IsarShoppingListFlag()..key = defaultsSeededFlag);
        await _categories.putAllById(categories);
        return true;
      });

  Future<void> putItemWithPurchase(IsarShoppingItem item, IsarShoppingPurchase purchase) => _isar.writeTxn(() async {
        await _items.putById(item);
        await _purchases.putById(purchase);
      });

  Future<void> putItemAndDeletePurchase(IsarShoppingItem item, String purchaseId) => _isar.writeTxn(() async {
        await _items.putById(item);
        await _purchases.deleteById(purchaseId);
      });

  Future<List<IsarShoppingPurchase>> getPurchases(String itemId) =>
      _purchases.where().itemIdEqualToAnyPurchasedAt(itemId).sortByPurchasedAtDesc().findAll();
}
