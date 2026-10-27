import 'package:core_contracts/core_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late PluginRegistry registry;
  late InMemoryPluginPreferenceRepository preferences;
  late List<(String, Object)> reportedErrors;
  late PluginLifecycleManager manager;

  setUp(() {
    registry = PluginRegistry();
    preferences = InMemoryPluginPreferenceRepository();
    reportedErrors = <(String, Object)>[];
    manager = PluginLifecycleManager(
      registry: registry,
      preferences: preferences,
      onError: (String pluginId, Object error, StackTrace _) => reportedErrors.add((pluginId, error)),
    );
  });

  tearDown(() => preferences.close());

  List<String> ids(List<PluginState> states) => <String>[for (final PluginState s in states) s.plugin.id];

  group('load', () {
    test('sin preferencias guardadas activa todo en orden de registro', () async {
      final FakePlugin a = FakePlugin('a');
      final FakePlugin b = FakePlugin('b');
      registry
        ..register(a)
        ..register(b);

      final List<PluginState> states = await manager.load();

      expect(ids(states), <String>['a', 'b']);
      expect(states.map((PluginState s) => s.status), everyElement(PluginStatus.ready));
      expect(a.initializeCalls, 1);
      expect(b.initializeCalls, 1);
    });

    test('ordena por sortOrder guardado', () async {
      registry
        ..register(FakePlugin('a'))
        ..register(FakePlugin('b'))
        ..register(FakePlugin('c'));
      await preferences.saveAll(const <UserPluginPreference>[
        UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 2),
        UserPluginPreference(pluginId: 'b', isEnabled: true, sortOrder: 0),
        UserPluginPreference(pluginId: 'c', isEnabled: true, sortOrder: 1),
      ]);

      expect(ids(await manager.load()), <String>['b', 'c', 'a']);
    });

    test('no inicializa plugins desactivados', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);
      await preferences.save(
        const UserPluginPreference(pluginId: 'a', isEnabled: false, sortOrder: 0),
      );

      final List<PluginState> states = await manager.load();

      expect(states.single.status, PluginStatus.disabled);
      expect(states.single.isVisibleOnDashboard, isFalse);
      expect(a.initializeCalls, 0);
    });

    test('no inicializa plugins no disponibles', () async {
      final FakePlugin a = FakePlugin('a', available: false);
      registry.register(a);

      final List<PluginState> states = await manager.load();

      expect(states.single.status, PluginStatus.unavailable);
      expect(states.single.isVisibleOnDashboard, isFalse);
      expect(a.initializeCalls, 0);
    });

    test('un fallo en initialize no bloquea a los demás plugins', () async {
      final Exception error = Exception('boom');
      registry
        ..register(FakePlugin('a', initializeError: error))
        ..register(FakePlugin('b'));

      final List<PluginState> states = await manager.load();

      expect(states[0].status, PluginStatus.failed);
      expect(states[0].error, error);
      expect(states[0].isVisibleOnDashboard, isTrue);
      expect(states[1].status, PluginStatus.ready);
      expect(reportedErrors, <(String, Object)>[('a', error)]);
    });

    test('es idempotente: no reinicializa plugins listos', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);

      await manager.load();
      await manager.load();

      expect(a.initializeCalls, 1);
    });

    test('reintenta en la siguiente carga un plugin que falló', () async {
      final FakePlugin a = FakePlugin('a', initializeError: Exception('boom'));
      registry.register(a);
      await manager.load();

      a.initializeError = null;
      final List<PluginState> states = await manager.load();

      expect(states.single.status, PluginStatus.ready);
      expect(a.initializeCalls, 2);
    });

    test('libera un plugin inicializado que deja de estar disponible', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);
      await manager.load();

      a.available = false;
      final List<PluginState> states = await manager.load();

      expect(states.single.status, PluginStatus.unavailable);
      expect(a.disposeCalls, 1);
    });
  });

  group('setEnabled', () {
    test('desactivar persiste la preferencia e invoca dispose', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);
      await manager.load();

      final List<PluginState> states = await manager.setEnabled('a', enabled: false);

      expect(states.single.status, PluginStatus.disabled);
      expect(a.disposeCalls, 1);
      expect(
        await preferences.getAll(),
        <UserPluginPreference>[const UserPluginPreference(pluginId: 'a', isEnabled: false, sortOrder: 0)],
      );
    });

    test('la desactivación sobrevive a un reinicio (nuevo manager)', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);
      await manager.setEnabled('a', enabled: false);

      final PluginLifecycleManager restarted = PluginLifecycleManager(registry: registry, preferences: preferences);
      final List<PluginState> states = await restarted.load();

      expect(states.single.status, PluginStatus.disabled);
    });

    test('reactivar inicializa de nuevo el plugin', () async {
      final FakePlugin a = FakePlugin('a');
      registry.register(a);
      await manager.load();
      await manager.setEnabled('a', enabled: false);

      final List<PluginState> states = await manager.setEnabled('a', enabled: true);

      expect(states.single.status, PluginStatus.ready);
      expect(a.initializeCalls, 2);
    });

    test('un error en dispose se reporta sin propagarse', () async {
      final Exception error = Exception('dispose');
      registry.register(FakePlugin('a', disposeError: error));
      await manager.load();

      final List<PluginState> states = await manager.setEnabled('a', enabled: false);

      expect(states.single.status, PluginStatus.disabled);
      expect(reportedErrors, <(String, Object)>[('a', error)]);
    });

    test('lanza ArgumentError para un plugin no registrado', () {
      expect(() => manager.setEnabled('missing', enabled: false), throwsArgumentError);
    });
  });

  group('reorder', () {
    test('persiste el nuevo orden conservando la activación', () async {
      registry
        ..register(FakePlugin('a'))
        ..register(FakePlugin('b'));
      await manager.setEnabled('b', enabled: false);

      final List<PluginState> states = await manager.reorder(<String>['b', 'a']);

      expect(ids(states), <String>['b', 'a']);
      expect(states.first.status, PluginStatus.disabled);
    });

    test('lanza ArgumentError si la lista no coincide con los registrados', () {
      registry
        ..register(FakePlugin('a'))
        ..register(FakePlugin('b'));

      expect(() => manager.reorder(<String>['a']), throwsArgumentError);
      expect(() => manager.reorder(<String>['a', 'x']), throwsArgumentError);
    });
  });

  test('disposeAll libera solo los plugins inicializados', () async {
    final FakePlugin a = FakePlugin('a');
    final FakePlugin b = FakePlugin('b');
    registry
      ..register(a)
      ..register(b);
    await preferences.save(
      const UserPluginPreference(pluginId: 'b', isEnabled: false, sortOrder: 1),
    );
    await manager.load();

    await manager.disposeAll();

    expect(a.disposeCalls, 1);
    expect(b.disposeCalls, 0);
  });
}
