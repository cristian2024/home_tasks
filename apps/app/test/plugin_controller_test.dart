import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/navigation/plugin_route_guard.dart';
import 'package:home_utility_app/plugins/plugin_controller.dart';

import 'helpers/app_harness.dart';

void main() {
  late PluginRegistry registry;
  late InMemoryPluginPreferenceRepository preferences;
  late PluginController controller;
  late List<FakeHomePlugin> plugins;

  setUp(() {
    plugins = <FakeHomePlugin>[FakeHomePlugin('a'), FakeHomePlugin('b'), FakeHomePlugin('c'), FakeHomePlugin('d')];
    registry = PluginRegistry();
    plugins.forEach(registry.register);
    preferences = InMemoryPluginPreferenceRepository();
    controller = PluginController(PluginLifecycleManager(registry: registry, preferences: preferences));
  });

  tearDown(() => preferences.close());

  List<String> ids(List<PluginState> states) => <String>[for (final PluginState s in states) s.plugin.id];

  test('notifica al cargar y expone el dashboard', () async {
    int notifications = 0;
    controller.addListener(() => notifications++);
    expect(controller.isLoaded, isFalse);

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(notifications, 1);
    expect(ids(controller.dashboard), <String>['a', 'b', 'c', 'd']);
    expect(controller.stateOf('b')?.status, PluginStatus.ready);
    expect(controller.stateOf('x'), isNull);
  });

  test('mover una tarjeta conserva al final los plugins ocultos', () async {
    await controller.load();
    await controller.setEnabled('b', enabled: false);
    expect(ids(controller.dashboard), <String>['a', 'c', 'd']);

    await controller.moveDashboardTile(2, 0); // d al principio

    expect(ids(controller.dashboard), <String>['d', 'a', 'c']);
    expect(ids(controller.states), <String>['d', 'a', 'c', 'b']);

    await controller.moveDashboardTile(0, 2); // d al final
    expect(ids(controller.dashboard), <String>['a', 'c', 'd']);
  });

  test('el guard bloquea las rutas de plugins no listos', () async {
    plugins[2].available = false;
    plugins[3].failOnInitialize = true;
    await controller.load();
    await controller.setEnabled('b', enabled: false);
    final PluginRouteGuard guard = PluginRouteGuard(registry: registry, controller: controller);

    expect(guard.check('/a'), isNull);
    expect(guard.check('/a/sub/ruta'), isNull);
    expect(guard.check('/b'), BlockedReason.disabled);
    expect(guard.check('/c'), BlockedReason.unavailable);
    expect(guard.check('/d'), BlockedReason.unavailable);
    expect(guard.check('/'), isNull);
    expect(guard.check('/plugins-catalog'), isNull);
    expect(guard.check('/ab'), isNull, reason: 'el prefijo es un segmento completo');
  });
}
