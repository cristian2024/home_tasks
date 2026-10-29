/// Dobles de prueba de los contratos y tests de contrato reutilizables, para
/// los tests de otros paquetes.
library;

import 'dart:async';

import 'core_contracts.dart';

export 'src/testing/plugin_preference_repository_contract.dart';

/// [PluginPreferenceRepository] en memoria. Cumple
/// [pluginPreferenceRepositoryContract].
class InMemoryPluginPreferenceRepository implements PluginPreferenceRepository {
  final Map<String, UserPluginPreference> _store = <String, UserPluginPreference>{};
  final StreamController<List<UserPluginPreference>> _changes =
      StreamController<List<UserPluginPreference>>.broadcast();

  @override
  Future<List<UserPluginPreference>> getAll() async => _store.values.toList();

  @override
  Future<void> save(UserPluginPreference preference) => saveAll(<UserPluginPreference>[preference]);

  @override
  Future<void> saveAll(List<UserPluginPreference> preferences) async {
    for (final UserPluginPreference preference in preferences) {
      _store[preference.pluginId] = preference;
    }
    _changes.add(_store.values.toList());
  }

  /// Emite el estado actual al suscribirse y la lista completa en cada cambio.
  @override
  Stream<List<UserPluginPreference>> watch() {
    StreamSubscription<List<UserPluginPreference>>? changes;
    late final StreamController<List<UserPluginPreference>> controller;
    controller = StreamController<List<UserPluginPreference>>(
      onListen: () {
        controller.add(_store.values.toList());
        changes = _changes.stream.listen(controller.add);
      },
      // No devuelve el futuro de cancel(): `first` lo esperaría y, con el
      // reloj simulado de testWidgets, no se completa.
      onCancel: () {
        unawaited(changes?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  Future<void> close() => _changes.close();
}
