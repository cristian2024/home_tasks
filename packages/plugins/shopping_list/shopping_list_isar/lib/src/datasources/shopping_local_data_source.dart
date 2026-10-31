import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:storage_isar/adapter.dart';

import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../models/isar_shopping_list_flag.dart';
import '../models/isar_shopping_purchase.dart';
import '../sync/isar_shopping_list_sync.dart';

/// Acceso a las colecciones Isar de la lista de compras. Toda escritura va en
/// una transacción explícita (spec §10.1). Los borrados son lógicos
/// (`deletedAt`) y las lecturas solo devuelven lo activo. Con
/// [IsarShoppingListSync], cada escritura registra sus cambios en esa misma
/// transacción.
class ShoppingLocalDataSource {
  ShoppingLocalDataSource(this._isar, [this._sync]);

  /// Marca de que ya se crearon las categorías por defecto.
  static const String defaultsSeededFlag = 'defaultCategoriesSeeded';

  final Isar _isar;
  final IsarShoppingListSync? _sync;

  IsarCollection<IsarShoppingItem> get _items => _isar.isarShoppingItems;
  IsarCollection<IsarShoppingCategory> get _categories => _isar.isarShoppingCategorys;
  IsarCollection<IsarShoppingPurchase> get _purchases => _isar.isarShoppingPurchases;
  IsarCollection<IsarShoppingListFlag> get _flags => _isar.isarShoppingListFlags;

  /// Guarda el item, salvo que esté borrado.
  Future<void> putItem(IsarShoppingItem item) => _write(() async {
        if (await _isDeletedItem(item.id)) {
          return const <ShoppingSyncWrite>[];
        }
        await _items.putById(item);
        return <ShoppingSyncWrite>[IsarShoppingListSync.item(item)];
      });

  Future<IsarShoppingItem?> getItem(String id) async {
    final IsarShoppingItem? item = await _items.getById(id);
    return item?.deletedAt == null ? item : null;
  }

  Future<List<IsarShoppingItem>> getItems() => _items.filter().deletedAtIsNull().findAll();

  Stream<List<IsarShoppingItem>> watchItems() => _items.filter().deletedAtIsNull().watch(fireImmediately: true);

  /// Borra los items activos y sus compras en [deletedAt], en una sola
  /// transacción.
  Future<void> deleteItems(List<String> ids, DateTime deletedAt) => _write(() async {
        final List<ShoppingSyncWrite> writes = <ShoppingSyncWrite>[];
        for (final String id in ids) {
          final IsarShoppingItem? item = await getItem(id);
          if (item == null) {
            continue;
          }
          await _items.putById(item..deletedAt = deletedAt);
          writes.add(IsarShoppingListSync.deletion(ShoppingListCollections.items, id, deletedAt));
          final List<IsarShoppingPurchase> purchases = await _activePurchases(id).findAll();
          for (final IsarShoppingPurchase purchase in purchases) {
            purchase.deletedAt = deletedAt;
            writes.add(IsarShoppingListSync.deletion(ShoppingListCollections.purchases, purchase.id, deletedAt));
          }
          await _purchases.putAllById(purchases);
        }
        return writes;
      });

  /// Guarda las categorías que no están borradas.
  Future<void> putCategories(List<IsarShoppingCategory> categories) => _write(() => _putCategories(categories));

  Future<List<IsarShoppingCategory>> getCategories() =>
      _categories.filter().deletedAtIsNull().sortBySortOrder().thenById().findAll();

  Stream<List<IsarShoppingCategory>> watchCategories() =>
      _categories.filter().deletedAtIsNull().sortBySortOrder().thenById().watch(fireImmediately: true);

  /// Borra la categoría en [updatedAt] y la quita de sus items (con ese
  /// `updatedAt`) en una sola transacción. No hace nada si no existe.
  Future<void> deleteCategory(String id, DateTime updatedAt) => _write(() async {
        final IsarShoppingCategory? category = await _categories.getById(id);
        if (category == null || category.deletedAt != null) {
          return const <ShoppingSyncWrite>[];
        }
        await _categories.putById(category..deletedAt = updatedAt);
        final List<IsarShoppingItem> items =
            await _items.where().categoryIdsElementEqualTo(id).filter().deletedAtIsNull().findAll();
        for (final IsarShoppingItem item in items) {
          item
            ..categoryIds = <String>[for (final String categoryId in item.categoryIds) if (categoryId != id) categoryId]
            ..updatedAt = updatedAt;
        }
        await _items.putAllById(items);
        return <ShoppingSyncWrite>[
          IsarShoppingListSync.deletion(ShoppingListCollections.categories, id, updatedAt),
          ...items.map(IsarShoppingListSync.item),
        ];
      });

  /// Guarda [categories] y la marca de categorías creadas, solo si la marca
  /// no existe. Devuelve si las guardó.
  Future<bool> seedCategories(List<IsarShoppingCategory> categories) async {
    bool seeded = false;
    await _write(() async {
      if (await _flags.getByKey(defaultsSeededFlag) != null) {
        return const <ShoppingSyncWrite>[];
      }
      await _flags.putByKey(IsarShoppingListFlag()..key = defaultsSeededFlag);
      seeded = true;
      return _putCategories(categories);
    });
    return seeded;
  }

  /// Guarda el item y su compra, salvo que el item esté borrado. La compra
  /// anterior que se registra es la última activa del item.
  Future<void> putItemWithPurchase(IsarShoppingItem item, IsarShoppingPurchase purchase) => _write(() async {
        if (await _isDeletedItem(item.id)) {
          return const <ShoppingSyncWrite>[];
        }
        final IsarShoppingPurchase? previous =
            await _activePurchases(purchase.itemId).not().idEqualTo(purchase.id).sortByPurchasedAtDesc().thenByIdDesc().findFirst();
        await _items.putById(item);
        await _purchases.putById(purchase);
        return <ShoppingSyncWrite>[
          IsarShoppingListSync.item(item),
          IsarShoppingListSync.purchase(purchase, previousPurchase: previous?.id),
        ];
      });

  /// Guarda el item (salvo que esté borrado) y borra la compra en
  /// [deletedAt], aunque la sincronización ya no la mostrara.
  Future<void> putItemAndDeletePurchase(IsarShoppingItem item, String purchaseId, DateTime deletedAt) =>
      _write(() async {
        final List<ShoppingSyncWrite> writes = <ShoppingSyncWrite>[];
        if (!await _isDeletedItem(item.id)) {
          await _items.putById(item);
          writes.add(IsarShoppingListSync.item(item));
        }
        final IsarShoppingPurchase? purchase = await _purchases.getById(purchaseId);
        if (purchase != null) {
          await _purchases.putById(purchase..deletedAt = deletedAt);
          writes.add(IsarShoppingListSync.deletion(ShoppingListCollections.purchases, purchaseId, deletedAt));
        }
        return writes;
      });

  Future<List<IsarShoppingPurchase>> getPurchases(String itemId) =>
      _activePurchases(itemId).sortByPurchasedAtDesc().findAll();

  QueryBuilder<IsarShoppingPurchase, IsarShoppingPurchase, QAfterFilterCondition> _activePurchases(String itemId) =>
      _purchases.where().itemIdEqualToAnyPurchasedAt(itemId).filter().deletedAtIsNull();

  Future<List<ShoppingSyncWrite>> _putCategories(List<IsarShoppingCategory> categories) async {
    final List<IsarShoppingCategory> active = <IsarShoppingCategory>[
      for (final IsarShoppingCategory category in categories)
        if ((await _categories.getById(category.id))?.deletedAt == null) category,
    ];
    await _categories.putAllById(active);
    return active.map(IsarShoppingListSync.category).toList();
  }

  Future<bool> _isDeletedItem(String id) async => (await _items.getById(id))?.deletedAt != null;

  /// Ejecuta [body] en una transacción de escritura y registra lo que
  /// devuelve.
  Future<void> _write(Future<List<ShoppingSyncWrite>> Function() body) => _isar.writeTxn(() async {
        await _sync?.prepare();
        await _sync?.record(await body());
      });
}
