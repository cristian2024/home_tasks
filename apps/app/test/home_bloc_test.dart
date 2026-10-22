import 'package:bloc_test/bloc_test.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/home/bloc/home_bloc.dart';
import 'package:home_utility_app/plugins/plugin_controller.dart';

import 'helpers/app_harness.dart';

void main() {
  late FakeHomePlugin failing;
  late PluginController controller;
  late InMemoryPluginPreferenceRepository preferences;

  setUp(() {
    failing = FakeHomePlugin('b', failOnInitialize: true);
    final registry = PluginRegistry()
      ..register(FakeHomePlugin('a'))
      ..register(failing)
      ..register(FakeHomePlugin('c'));
    preferences = InMemoryPluginPreferenceRepository();
    controller = PluginController(PluginLifecycleManager(registry: registry, preferences: preferences));
  });

  tearDown(() => preferences.close());

  List<(String, PluginStatus)> tiles(HomeState state) => [for (final t in state.tiles) (t.plugin.id, t.status)];

  blocTest<HomeBloc, HomeState>(
    'al iniciar carga los plugins; el que falla aparece con estado failed',
    build: () => HomeBloc(controller),
    act: (bloc) => bloc.add(const HomeStarted()),
    verify: (bloc) {
      expect(bloc.state.loading, isFalse);
      expect(tiles(bloc.state), [('a', PluginStatus.ready), ('b', PluginStatus.failed), ('c', PluginStatus.ready)]);
    },
  );

  blocTest<HomeBloc, HomeState>(
    'reintentar vuelve a inicializar el plugin que falló',
    build: () => HomeBloc(controller),
    act: (bloc) async {
      bloc.add(const HomeStarted());
      await Future<void>.delayed(Duration.zero);
      failing.failOnInitialize = false;
      bloc.add(const HomeRetryRequested());
    },
    verify: (bloc) {
      expect(bloc.state.retrying, isFalse);
      expect(tiles(bloc.state)[1], ('b', PluginStatus.ready));
      expect(failing.initializeCalls, 2);
    },
  );

  blocTest<HomeBloc, HomeState>(
    'mover una tarjeta persiste el orden y refleja el cambio',
    build: () => HomeBloc(controller),
    act: (bloc) async {
      bloc.add(const HomeStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HomeTileMoved(2, 0));
    },
    verify: (bloc) async {
      expect(tiles(bloc.state).map((t) => t.$1), ['c', 'a', 'b']);
      final saved = {for (final p in await preferences.getAll()) p.pluginId: p.sortOrder};
      expect(saved, {'c': 0, 'a': 1, 'b': 2});
    },
  );

  blocTest<HomeBloc, HomeState>(
    'refleja los cambios hechos desde el catálogo',
    build: () => HomeBloc(controller),
    act: (bloc) async {
      bloc.add(const HomeStarted());
      await Future<void>.delayed(Duration.zero);
      await controller.setEnabled('a', enabled: false);
    },
    verify: (bloc) => expect(tiles(bloc.state).map((t) => t.$1), ['b', 'c']),
  );
}
