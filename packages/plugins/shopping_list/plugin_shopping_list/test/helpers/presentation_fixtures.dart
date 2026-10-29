import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_events/testing.dart';
import 'package:core_share/core_share.dart';
import 'package:core_share/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:plugin_shopping_list/testing.dart';

import 'domain_fixtures.dart';

/// Monta el plugin inicializado dentro de una app mínima con su dashboard en
/// `/` y sus rutas, como lo compone la app: repositorio en memoria (en lugar
/// del adaptador), reloj fijo y, si [share], un `ShareService` falso.
class PluginHarness {
  PluginHarness({bool share = true}) {
    locator
      ..registerSingleton<ShoppingListRepository>(repository)
      ..registerSingleton<IdGenerator>(TestIds())
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<EventBus>(eventBus);
    if (share) {
      locator.registerSingleton<ShareService>(this.share);
    }
    plugin = ShoppingListPlugin(locator: locator, localization: localization);
  }

  final InMemoryShoppingListRepository repository = InMemoryShoppingListRepository();
  final FixedClock clock = FixedClock(t0);
  final RecordingEventBus eventBus = RecordingEventBus();
  final FakeShareService share = FakeShareService();
  final ServiceLocator locator = ServiceLocator();
  final LocalizationCoordinator localization = LocalizationCoordinator();
  late final ShoppingListPlugin plugin;
  late GoRouter router;
  bool _initialized = false;

  ShoppingListDependencies get deps => locator.get<ShoppingListDependencies>();

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      await plugin.initialize();
    }
  }

  Future<void> pump(WidgetTester tester, {String initialLocation = ShoppingListRoutes.base}) async {
    await initialize();
    router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (BuildContext context, _) => Scaffold(body: plugin.buildDashboardTile(context))),
        ...plugin.routes,
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: LocalizationCoordinator.supportedLocales,
        localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La categoría por defecto con [defaultKey] (p. ej. `food`).
  Future<ShoppingCategory> category(String defaultKey) async => (await repository.getCategories())
      .firstWhere((ShoppingCategory category) => category.defaultKey == defaultKey);

  Future<void> dispose() async {
    if (_initialized) {
      await plugin.dispose();
    }
    await locator.reset();
    await repository.close();
  }
}
