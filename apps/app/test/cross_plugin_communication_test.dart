import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';

import 'helpers/app_harness.dart';

/// Plugin que usa la lista de compras sin conocerla: solo depende de
/// `shopping_list_contract`. Escucha `ShoppingItemPurchased` mientras está
/// activo y pide las capacidades al locator en el momento de usarlas.
class _ShoppingConsumerPlugin implements HomePlugin {
  _ShoppingConsumerPlugin(this._locator);

  final ServiceLocator _locator;
  final List<String> purchased = <String>[];

  @override
  String get id => 'consumer';

  /// «Se acabó»: lo añade a la lista de compras si está disponible. Devuelve
  /// el ID del item o `null` si no hay lista de compras.
  Future<String?> runOut(String name) async {
    if (!_locator.isRegistered<ShoppingListWriter>()) {
      return null;
    }
    return _locator.get<ShoppingListWriter>().addItem(ShoppingItemRequest(name: name, urgency: Urgency.high));
  }

  /// Lo pendiente de comprar, o `null` si no hay lista de compras.
  Future<List<String>?> pendingNames() async {
    if (!_locator.isRegistered<ShoppingListQuery>()) {
      return null;
    }
    return <String>[
      for (final ShoppingItemSummary item in await _locator.get<ShoppingListQuery>().pendingItems()) item.name,
    ];
  }

  @override
  Future<void> initialize() => _locator.pushScope(
        id,
        init: (ServiceLocator locator) {
          final EventSubscriptions subscriptions = EventSubscriptions()
            ..listen<ShoppingItemPurchased>(
              locator.get<EventBus>(),
              (ShoppingItemPurchased event) => purchased.add(event.itemName),
            );
          locator.registerSingleton(subscriptions, dispose: (EventSubscriptions s) => s.cancelAll());
        },
      );

  @override
  Future<void> dispose() => _locator.dropScope(id);

  @override
  String get nameKey => 'consumer.name';

  @override
  String get descriptionKey => 'consumer.description';

  @override
  IconData get icon => Icons.extension;

  @override
  String get version => '1.0.0';

  @override
  Future<bool> isAvailable() async => true;

  @override
  List<RouteBase> get routes => <RouteBase>[];

  @override
  Widget buildDashboardTile(BuildContext context) => const SizedBox.shrink();
}

void main() {
  late AppHarness harness;
  late _ShoppingConsumerPlugin consumer;

  setUp(() async {
    final ServiceLocator locator = ServiceLocator();
    consumer = _ShoppingConsumerPlugin(locator);
    harness = AppHarness(includeShoppingList: true, extraPlugins: <HomePlugin>[consumer], locator: locator);
    await harness.plugins.load();
  });
  tearDown(() => harness.dispose());

  ShoppingListDependencies shopping() => harness.locator.get<ShoppingListDependencies>();

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('con la lista de compras activa, otro plugin añade, consulta y se entera de las compras', () async {
    final String? id = await consumer.runOut('Pilas');

    expect(id, isNotNull);
    expect(await consumer.pendingNames(), <String>['Pilas']);

    await shopping().markPurchased(id!);
    await flush();
    expect(consumer.purchased, <String>['Pilas']);
    expect(await consumer.pendingNames(), isEmpty);
  });

  test('con la lista de compras desactivada, el otro plugin sigue funcionando sin ella', () async {
    await harness.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: false);

    expect(await consumer.runOut('Pilas'), isNull);
    expect(await consumer.pendingNames(), isNull);

    // Al reactivarla, las capacidades vuelven y los datos siguen ahí.
    await harness.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: true);
    expect(await consumer.runOut('Pilas'), isNotNull);
    expect(await consumer.pendingNames(), <String>['Pilas']);
  });

  test('al desactivar el plugin consumidor se cancelan sus suscripciones', () async {
    final ShoppingItem bread = await shopping().createItem(name: 'Pan');
    await harness.plugins.setEnabled('consumer', enabled: false);

    await shopping().markPurchased(bread.id);
    await flush();

    expect(consumer.purchased, isEmpty);
  });
}
