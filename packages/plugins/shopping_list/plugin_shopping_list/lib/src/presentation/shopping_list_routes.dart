/// Rutas del plugin. Son absolutas y planas para que la app las añada tal
/// cual a su `GoRouter`.
abstract final class ShoppingListRoutes {
  static const String base = '/shopping-list';
  static const String create = '$base/item/new';
  static const String editPattern = '$base/item/:id/edit';
  static const String categories = '$base/categories';

  /// Lo comprado.
  static const String bought = '$base/bought';

  /// Lo que espera a su siguiente ventana.
  static const String waiting = '$base/waiting';

  /// Editar [itemId]. Al guardar hace `pop` con su ID.
  static String edit(String itemId) => '$base/item/${Uri.encodeComponent(itemId)}/edit';
}
