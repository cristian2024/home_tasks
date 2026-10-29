import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_hardware/testing.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_utility_app/app.dart';
import 'package:home_utility_app/app_module_registrar.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:home_utility_app/i18n/strings.g.dart' as app_i18n;
import 'package:home_utility_app/plugins/plugin_controller.dart';
import 'package:home_utility_app/settings/app_settings.dart';
import 'package:home_utility_app/settings/app_settings_controller.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:plugin_item_tracker/testing.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:plugin_shopping_list/testing.dart';

import 'in_memory_app_settings_repository.dart';

/// Plugin mínimo para probar la app con más de un módulo.
class FakeHomePlugin implements HomePlugin {
  FakeHomePlugin(this.id, {this.available = true, this.failOnInitialize = false});

  @override
  final String id;
  bool available;
  bool failOnInitialize;
  int initializeCalls = 0;
  int disposeCalls = 0;

  String get route => '/$id';

  @override
  String get nameKey => '$id.name';

  @override
  String get descriptionKey => '$id.description';

  @override
  IconData get icon => Icons.widgets_outlined;

  @override
  String get version => '1.0.0';

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (failOnInitialize) {
      throw StateError('fallo de prueba');
    }
  }

  @override
  Future<void> dispose() async => disposeCalls++;

  @override
  List<RouteBase> get routes => <RouteBase>[
        GoRoute(path: route, builder: (_, _) => Scaffold(appBar: AppBar(title: Text('Pantalla $id')))),
      ];

  @override
  Widget buildDashboardTile(BuildContext context) =>
      Card(child: ListTile(title: Text('Tarjeta $id'), onTap: () => GoRouter.of(context).push(route)));
}

/// Entorno de la app sin base de datos: plugin real con hardware falso y
/// repositorio en memoria registrado en el locator (como lo haría un
/// adaptador), más los [extraPlugins] que se indiquen. Con
/// [includeShoppingList] registra también la lista de compras real, con su
/// repositorio en memoria.
class AppHarness {
  AppHarness({
    List<HomePlugin> extraPlugins = const <HomePlugin>[],
    AppSettings savedSettings = const AppSettings(),
    bool includeShoppingList = false,
    ServiceLocator? locator,
  })  : extraPlugins = extraPlugins,
        locator = locator ?? ServiceLocator(),
        preferences = InMemoryPluginPreferenceRepository(),
        settingsRepository = InMemoryAppSettingsRepository(savedSettings) {
    // Como bootstrapApp: el EventBus va en el scope raíz, compartido por
    // todos los plugins.
    this.locator
      ..registerSingleton<EventBus>(EventBus(), dispose: (EventBus bus) => bus.dispose())
      ..registerSingleton<HouseholdItemRepository>(items)
      ..registerSingleton<ShoppingListRepository>(shoppingItems);
    localization.register(
      'app',
      (String code) => app_i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (String key) {
        final Object? value = app_i18n.appStrings[key];
        return value is String ? value : null;
      },
    );
    localization.register(
      'fakes',
      (_) {},
      translate: (String key) => key.endsWith('.name') ? 'Módulo ${key.split('.').first}' : null,
    );
    final PluginRegistry registry = createPluginRegistry(
      locator: this.locator,
      localization: localization,
      factories: <PluginFactory>[
        (ServiceLocator locator, LocalizationCoordinator localization) => ItemTrackerPlugin(
              locator: locator,
              localization: localization,
              cameraScannerFactory: FakeCameraScanner.new,
              nfcScannerFactory: FakeNfcScanner.new,
              permissions: FakeHardwarePermissions(),
            )..registerLocalization(),
        if (includeShoppingList)
          (ServiceLocator locator, LocalizationCoordinator localization) =>
              ShoppingListPlugin(locator: locator, localization: localization)..registerLocalization(),
        for (final HomePlugin plugin in extraPlugins) (_, _) => plugin,
      ],
    );
    environment = AppEnvironment(
      locator: this.locator,
      localization: localization,
      registry: registry,
      plugins: PluginController(PluginLifecycleManager(registry: registry, preferences: preferences)),
      settings: AppSettingsController(
        repository: settingsRepository,
        localization: localization,
        initial: savedSettings,
        systemLanguageCode: 'es',
      ),
    );
  }

  final List<HomePlugin> extraPlugins;
  final InMemoryPluginPreferenceRepository preferences;
  final InMemoryAppSettingsRepository settingsRepository;
  final ServiceLocator locator;
  final LocalizationCoordinator localization = LocalizationCoordinator();
  final InMemoryHouseholdItemRepository items = InMemoryHouseholdItemRepository();
  final InMemoryShoppingListRepository shoppingItems = InMemoryShoppingListRepository();
  late final AppEnvironment environment;

  PluginController get plugins => environment.plugins;

  Future<void> pump(WidgetTester tester, {String initialLocation = '/'}) async {
    await plugins.load();
    await tester.pumpWidget(HomeUtilityApp(environment: environment, initialLocation: initialLocation));
    await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    localization.setLanguage('es');
    await environment.dispose();
    await preferences.close();
  }
}
