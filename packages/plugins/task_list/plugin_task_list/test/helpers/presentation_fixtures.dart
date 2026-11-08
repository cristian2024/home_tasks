import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_task_list/plugin_task_list.dart';
import 'package:plugin_task_list/testing.dart';

import 'domain_fixtures.dart';

/// Monta el plugin inicializado dentro de una app mínima con su tarjeta en
/// `/` y sus rutas, como lo compone la app: repositorio en memoria (en lugar
/// del adaptador) y reloj fijo.
class PluginHarness {
  PluginHarness({InMemoryTaskListRepository? repository}) : repository = repository ?? InMemoryTaskListRepository() {
    locator
      ..registerSingleton<TaskListRepository>(this.repository)
      ..registerSingleton<IdGenerator>(TestIds())
      ..registerSingleton<Clock>(clock);
    plugin = TaskListPlugin(locator: locator, localization: localization);
  }

  final InMemoryTaskListRepository repository;
  final FixedClock clock = FixedClock(t0);
  final ServiceLocator locator = ServiceLocator();
  final LocalizationCoordinator localization = LocalizationCoordinator();
  late final TaskListPlugin plugin;
  late GoRouter router;
  bool _initialized = false;

  TaskListDependencies get deps => locator.get<TaskListDependencies>();

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      await plugin.initialize();
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    String initialLocation = TaskListRoutes.base,
    double textScale = 1,
    bool dark = false,
  }) async {
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
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: LocalizationCoordinator.supportedLocales,
        localizationsDelegates: LocalizationCoordinator.localizationsDelegates,
        routerConfig: router,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La categoría por defecto con [defaultKey] (p. ej. `cleaning`).
  Future<TaskCategory> category(String defaultKey) async =>
      (await repository.getCategories()).firstWhere((TaskCategory category) => category.defaultKey == defaultKey);

  /// Crea una tarea con los casos de uso del plugin.
  Future<HouseholdTask> task(
    String title, {
    Urgency urgency = Urgency.normal,
    DateTime? dueDate,
    Recurrence? recurrence,
    List<String> categoryIds = const <String>[],
  }) async {
    await initialize();
    return deps.createTask(
      title: title,
      urgency: urgency,
      dueDate: dueDate,
      recurrence: recurrence,
      categoryIds: categoryIds,
    );
  }

  Future<void> dispose() async {
    if (_initialized) {
      await plugin.dispose();
    }
    await locator.reset();
    await repository.close();
  }
}
