import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';

import 'helpers/presentation_fixtures.dart';

void main() {
  test('datos del plugin', () {
    final ShoppingListPlugin plugin = ShoppingListPlugin(locator: ServiceLocator());

    expect(plugin.id, 'shopping_list');
    expect(plugin.nameKey, 'shoppingList.title');
    expect(plugin.descriptionKey, 'shoppingList.description');
    expect(plugin.version, '0.1.1');
    expect(plugin.routes, hasLength(4));
    expect(plugin.entryRoute, ShoppingListRoutes.base);
  });

  test('isAvailable siempre es true', () async {
    expect(await ShoppingListPlugin(locator: ServiceLocator()).isAvailable(), isTrue);
  });

  group('ciclo de vida', () {
    late PluginHarness harness;

    setUp(() => harness = PluginHarness());
    tearDown(() => harness.dispose());

    test('initialize crea las categorías por defecto y registra las capacidades públicas', () async {
      await harness.initialize();

      expect(await harness.repository.getCategories(), hasLength(5));
      expect(harness.locator.isRegistered<ShoppingListQuery>(), isTrue);
      expect(harness.locator.isRegistered<ShoppingListWriter>(), isTrue);
      expect(harness.deps.shareService(), same(harness.share));
    });

    test('dispose quita las capacidades: otro plugin ve que no están', () async {
      await harness.initialize();
      await harness.plugin.dispose();

      expect(harness.locator.isRegistered<ShoppingListQuery>(), isFalse);
      expect(harness.locator.isRegistered<ShoppingListWriter>(), isFalse);
      expect(harness.locator.isRegistered<ShoppingListDependencies>(), isFalse);
    });

    test('otro plugin añade cosas con ShoppingListWriter y las ve con ShoppingListQuery', () async {
      await harness.initialize();

      final String id = await harness.locator.get<ShoppingListWriter>().addItem(ShoppingItemRequest(name: 'Pilas'));

      expect((await harness.locator.get<ShoppingListQuery>().pendingItems()).single.id, id);
    });

    test('sin EventBus, IdGenerator ni Clock en el locator usa los suyos', () async {
      final ServiceLocator locator = ServiceLocator()
        ..registerSingleton<ShoppingListRepository>(harness.repository);
      final ShoppingListPlugin plugin = ShoppingListPlugin(locator: locator, localization: LocalizationCoordinator());
      addTearDown(locator.reset);

      await plugin.initialize();
      final ShoppingItem item = await locator.get<ShoppingListDependencies>().createItem(name: 'Pan');
      await locator.get<ShoppingListDependencies>().markPurchased(item.id);

      expect(item.id, hasLength(36));
      expect(locator.get<ShoppingListDependencies>().shareService(), isNull);
      await plugin.dispose();
    });
  });

  group('textos', () {
    late LocalizationCoordinator localization;
    late ShoppingListPlugin plugin;

    setUp(() {
      localization = LocalizationCoordinator();
      plugin = ShoppingListPlugin(locator: ServiceLocator(), localization: localization);
    });

    tearDown(() {
      localization
        ..overrideTranslations(ShoppingListPlugin.pluginId, 'es', <String, Object?>{})
        ..overrideTranslations(ShoppingListPlugin.pluginId, 'en', <String, Object?>{})
        ..setLanguage('es');
    });

    test('los textos que reemplaza la app tienen prioridad sobre los del plugin', () {
      plugin.registerLocalization();
      localization.overrideTranslations(ShoppingListPlugin.pluginId, 'es', <String, Object?>{
        'shopping_list': <String, Object?>{'title': 'La compra'},
      });

      expect(localization.translate(plugin.nameKey), 'La compra');
      expect(localization.translate(plugin.descriptionKey), startsWith('Lo que hay que comprar'));

      localization.setLanguage('en');
      expect(localization.translate(plugin.nameKey), 'Shopping list');
    });
  });
}
