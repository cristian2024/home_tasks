import 'shopping_item_summary.dart';

/// Consulta de lo pendiente en la lista de compras.
abstract interface class ShoppingListQuery {
  /// Lo que hay que comprar ahora: los pendientes y los recurrentes cuya
  /// ventana está abierta o ya pasó. Lo más urgente primero y, a igual
  /// urgencia, por nombre.
  Future<List<ShoppingItemSummary>> pendingItems();

  /// Como [pendingItems], al suscribirse y cada vez que cambia.
  Stream<List<ShoppingItemSummary>> watchPendingItems();
}
