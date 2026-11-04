import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';

/// Repositorio de la lista de compras: items, categorías e historial de
/// compras. Las operaciones que escriben varias entidades son atómicas.
///
/// Los borrados son lógicos (spec §10.4.3): lo borrado no aparece en ninguna
/// consulta ni stream y no vuelve aunque se guarde otra vez con su ID.
abstract interface class ShoppingListRepository {
  /// Guarda un item nuevo o reemplaza el que tenga su ID. Si ese item se
  /// borró, no hace nada.
  Future<void> saveItem(ShoppingItem item);

  Future<ShoppingItem?> getItem(String id);

  /// Todos los items, sin orden garantizado.
  Future<List<ShoppingItem>> getItems();

  /// Todos los items al suscribirse y cada vez que cambian, sin orden
  /// garantizado.
  Stream<List<ShoppingItem>> watchItems();

  /// Borra los items y su historial de compras en [deletedAt], en una sola
  /// transacción. Los IDs que no existen se ignoran.
  Future<void> deleteItems(List<String> ids, {required DateTime deletedAt});

  /// Guarda las categorías nuevas o reemplaza las que tengan su ID, en una
  /// sola transacción (p. ej. al reordenar). Las borradas se ignoran.
  Future<void> saveCategories(List<ShoppingCategory> categories);

  /// Categorías por `sortOrder`.
  Future<List<ShoppingCategory>> getCategories();

  /// Como [getCategories], al suscribirse y cada vez que cambian.
  Stream<List<ShoppingCategory>> watchCategories();

  /// Borra la categoría en [updatedAt] y la quita de los items que la tienen
  /// (con ese `updatedAt`), en una sola transacción. Si no existe, no hace
  /// nada.
  Future<void> deleteCategory(String id, {required DateTime updatedAt});

  /// Crea [defaults] solo la primera vez que se llama, aunque el usuario
  /// borre después todas las categorías. Devuelve si las creó.
  Future<bool> seedDefaultCategories(List<ShoppingCategory> defaults);

  /// Guarda el item ya actualizado y su compra en una sola transacción. Si el
  /// item se borró, no hace nada.
  Future<void> recordPurchase(ShoppingItem item, ShoppingPurchase purchase);

  /// Restaura [item] como estaba antes de la compra y borra la compra
  /// [purchaseId] en [deletedAt], en una sola transacción.
  Future<void> undoPurchase(ShoppingItem item, String purchaseId, {required DateTime deletedAt});

  /// Compras del item, de la más reciente a la más antigua.
  Future<List<ShoppingPurchase>> getPurchases(String itemId);
}
