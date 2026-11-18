import 'package:core_di/core_di.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:shopping_list_domain/testing.dart';
import 'package:shopping_list_shared_preferences/shopping_list_shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  shoppingListPreferencesContract(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferencesShoppingListPreferences();
  });

  test('otra instancia lee lo guardado (persiste entre arranques)', () async {
    final SharedPreferencesShoppingListPreferences first = SharedPreferencesShoppingListPreferences();
    await first.setLastQuickAddCategoryId('food');
    await first.setSwipeTipShown();

    final SharedPreferencesShoppingListPreferences second = SharedPreferencesShoppingListPreferences();

    expect(await second.lastQuickAddCategoryId(), 'food');
    expect(await second.swipeTipShown(), isTrue);
  });

  test('guarda sus claves con el prefijo y quita la categoría al volver a sin categoría', () async {
    final SharedPreferencesShoppingListPreferences preferences = SharedPreferencesShoppingListPreferences();
    await preferences.setLastQuickAddCategoryId('food');
    await preferences.setSwipeTipShown();
    expect((await SharedPreferences.getInstance()).getKeys(), <String>{
      'shopping_list.last_quick_add_category_id',
      'shopping_list.swipe_tip_shown',
    });

    await preferences.setLastQuickAddCategoryId(null);
    expect((await SharedPreferences.getInstance()).getKeys(), <String>{'shopping_list.swipe_tip_shown'});
  });

  test('SharedPreferencesShoppingList registra el contrato', () async {
    final ServiceLocator services = ServiceLocator();
    await const SharedPreferencesShoppingList().register(services);

    expect(services.get<ShoppingListPreferences>(), isA<SharedPreferencesShoppingListPreferences>());
    await services.reset();
  });
}
