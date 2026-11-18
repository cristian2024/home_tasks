/// Preferencias de la lista de compras que son del dispositivo, no de los
/// datos: no se sincronizan.
///
/// Toda implementación debe pasar `shoppingListPreferencesContract`
/// (`package:shopping_list_domain/testing.dart`).
abstract interface class ShoppingListPreferences {
  /// La última categoría usada al crear un item desde la lista; `null` si
  /// nunca se usó o fue «Sin categoría».
  Future<String?> lastQuickAddCategoryId();

  Future<void> setLastQuickAddCategoryId(String? categoryId);

  /// Si ya se sugirió el gesto de deslizar para borrar.
  Future<bool> swipeTipShown();

  Future<void> setSwipeTipShown();
}

/// [ShoppingListPreferences] en memoria: lo guardado dura lo que la app
/// abierta. El plugin la usa si quien compone no registra otra.
class InMemoryShoppingListPreferences implements ShoppingListPreferences {
  String? _lastQuickAddCategoryId;
  bool _swipeTipShown = false;

  @override
  Future<String?> lastQuickAddCategoryId() async => _lastQuickAddCategoryId;

  @override
  Future<void> setLastQuickAddCategoryId(String? categoryId) async => _lastQuickAddCategoryId = categoryId;

  @override
  Future<bool> swipeTipShown() async => _swipeTipShown;

  @override
  Future<void> setSwipeTipShown() async => _swipeTipShown = true;
}
