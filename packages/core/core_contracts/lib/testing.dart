/// Dobles de prueba de los contratos, para los tests de otros paquetes.
library;

import 'dart:async';

import 'core_contracts.dart';

/// [PluginPreferenceRepository] en memoria. [watch] emite en cada cambio.
class InMemoryPluginPreferenceRepository implements PluginPreferenceRepository {
  final Map<String, UserPluginPreference> _store = {};
  final StreamController<List<UserPluginPreference>> _changes =
      StreamController.broadcast();

  @override
  Future<List<UserPluginPreference>> getAll() async => _store.values.toList();

  @override
  Future<void> save(UserPluginPreference preference) => saveAll([preference]);

  @override
  Future<void> saveAll(List<UserPluginPreference> preferences) async {
    for (final preference in preferences) {
      _store[preference.pluginId] = preference;
    }
    _changes.add(_store.values.toList());
  }

  @override
  Stream<List<UserPluginPreference>> watch() => _changes.stream;

  Future<void> close() => _changes.close();
}
