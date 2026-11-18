import 'package:test/test.dart';

import '../preferences/shopping_list_preferences.dart';

/// Tests de contrato de [ShoppingListPreferences]: cada implementación los
/// ejecuta con una fábrica que crea una vacía.
void shoppingListPreferencesContract(Future<ShoppingListPreferences> Function() create) {
  group('ShoppingListPreferences', () {
    late ShoppingListPreferences preferences;

    setUp(() async => preferences = await create());

    test('empieza sin categoría y sin haber sugerido el gesto', () async {
      expect(await preferences.lastQuickAddCategoryId(), isNull);
      expect(await preferences.swipeTipShown(), isFalse);
    });

    test('guarda la última categoría y vuelve a sin categoría', () async {
      await preferences.setLastQuickAddCategoryId('food');
      expect(await preferences.lastQuickAddCategoryId(), 'food');
      await preferences.setLastQuickAddCategoryId(null);
      expect(await preferences.lastQuickAddCategoryId(), isNull);
    });

    test('recuerda que ya sugirió el gesto', () async {
      await preferences.setSwipeTipShown();
      await preferences.setSwipeTipShown();
      expect(await preferences.swipeTipShown(), isTrue);
    });
  });
}
