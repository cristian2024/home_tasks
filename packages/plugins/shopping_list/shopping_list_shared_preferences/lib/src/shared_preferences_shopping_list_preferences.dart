import 'package:core_di/core_di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

/// Registra [SharedPreferencesShoppingListPreferences] como
/// `ShoppingListPreferences`. Quien compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[SharedPreferencesShoppingList()]
/// ```
class SharedPreferencesShoppingList implements DependencyModule {
  const SharedPreferencesShoppingList();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<ShoppingListPreferences>(SharedPreferencesShoppingListPreferences());
}

/// [ShoppingListPreferences] en `shared_preferences`: son del dispositivo, así
/// que valen para todos los espacios de datos y no se sincronizan.
class SharedPreferencesShoppingListPreferences implements ShoppingListPreferences {
  SharedPreferencesShoppingListPreferences({this.keyPrefix = defaultKeyPrefix});

  static const String defaultKeyPrefix = 'shopping_list.';

  /// Prefijo de las claves de `shared_preferences`.
  final String keyPrefix;

  String get _lastCategoryKey => '${keyPrefix}last_quick_add_category_id';
  String get _swipeTipKey => '${keyPrefix}swipe_tip_shown';

  @override
  Future<String?> lastQuickAddCategoryId() async => (await SharedPreferences.getInstance()).getString(_lastCategoryKey);

  @override
  Future<void> setLastQuickAddCategoryId(String? categoryId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (categoryId == null) {
      await preferences.remove(_lastCategoryKey);
    } else {
      await preferences.setString(_lastCategoryKey, categoryId);
    }
  }

  @override
  Future<bool> swipeTipShown() async => (await SharedPreferences.getInstance()).getBool(_swipeTipKey) ?? false;

  @override
  Future<void> setSwipeTipShown() async => (await SharedPreferences.getInstance()).setBool(_swipeTipKey, true);
}
