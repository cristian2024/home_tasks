import 'shopping_item_request.dart';

/// Añadir cosas a la lista de compras desde otro plugin (p. ej. «se acabó»).
abstract interface class ShoppingListWriter {
  /// Añade [request] como pendiente y devuelve el ID del item.
  ///
  /// Si ya hay uno pendiente con el mismo nombre (sin distinguir mayúsculas
  /// ni espacios de sobra) no lo duplica: le sube la urgencia si la pedida es
  /// mayor y devuelve su ID.
  Future<String> addItem(ShoppingItemRequest request);
}
