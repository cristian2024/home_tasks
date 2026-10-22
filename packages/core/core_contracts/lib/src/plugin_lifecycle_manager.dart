import 'home_plugin.dart';
import 'plugin_preference_repository.dart';
import 'plugin_registry.dart';
import 'plugin_status.dart';
import 'user_plugin_preference.dart';

typedef PluginErrorHandler = void Function(
  String pluginId,
  Object error,
  StackTrace stackTrace,
);

/// Aplica el ciclo de vida Existencia → Disponibilidad → Activación →
/// Inicialización a los plugins del [PluginRegistry] (spec §3.2 y §6.2).
///
/// Un fallo en `isAvailable()`, `initialize()` o `dispose()` de un plugin se
/// reporta por [onError] y nunca bloquea a los demás.
class PluginLifecycleManager {
  final PluginRegistry _registry;
  final PluginPreferenceRepository _preferences;
  final PluginErrorHandler? onError;

  final Set<String> _initialized = {};

  PluginLifecycleManager({
    required PluginRegistry registry,
    required PluginPreferenceRepository preferences,
    this.onError,
  })  : _registry = registry,
        _preferences = preferences;

  /// Evalúa todos los plugins registrados, inicializa los activados y
  /// disponibles que aún no lo estén, y devuelve su estado ordenado por
  /// `sortOrder` (el orden de registro desempata).
  ///
  /// Un plugin sin preferencia guardada se considera activado, con
  /// `sortOrder` igual a su posición de registro.
  Future<List<PluginState>> load() async {
    final saved = {
      for (final preference in await _preferences.getAll())
        preference.pluginId: preference,
    };
    final plugins = _registry.allPlugins;

    final states = <PluginState>[];
    for (var i = 0; i < plugins.length; i++) {
      final plugin = plugins[i];
      final preference = saved[plugin.id] ??
          UserPluginPreference(pluginId: plugin.id, isEnabled: true, sortOrder: i);
      states.add(await _resolve(plugin, preference));
    }

    final registrationIndex = {
      for (var i = 0; i < plugins.length; i++) plugins[i].id: i,
    };
    states.sort((a, b) {
      final bySortOrder = a.preference.sortOrder.compareTo(b.preference.sortOrder);
      if (bySortOrder != 0) {
        return bySortOrder;
      }
      return registrationIndex[a.plugin.id]!.compareTo(registrationIndex[b.plugin.id]!);
    });
    return states;
  }

  /// Persiste la activación de [pluginId]. Al desactivarlo se invoca su
  /// `dispose()`; sus datos locales no se tocan. Devuelve el estado
  /// actualizado de todos los plugins.
  Future<List<PluginState>> setEnabled(String pluginId, {required bool enabled}) async {
    final current = await _stateOf(pluginId);
    await _preferences.save(current.preference.copyWith(isEnabled: enabled));
    if (!enabled) {
      await _disposePlugin(current.plugin);
    }
    return load();
  }

  /// Persiste un nuevo orden. [orderedPluginIds] debe contener exactamente los
  /// IDs de todos los plugins registrados.
  Future<List<PluginState>> reorder(List<String> orderedPluginIds) async {
    final registeredIds = _registry.allPlugins.map((plugin) => plugin.id).toSet();
    if (orderedPluginIds.length != registeredIds.length ||
        !registeredIds.containsAll(orderedPluginIds)) {
      throw ArgumentError.value(
        orderedPluginIds,
        'orderedPluginIds',
        'Debe contener exactamente los IDs de todos los plugins registrados',
      );
    }

    final states = {for (final state in await load()) state.plugin.id: state};
    await _preferences.saveAll([
      for (var i = 0; i < orderedPluginIds.length; i++)
        states[orderedPluginIds[i]]!.preference.copyWith(sortOrder: i),
    ]);
    return load();
  }

  /// Libera todos los plugins inicializados (cierre de la aplicación).
  Future<void> disposeAll() async {
    for (final plugin in _registry.allPlugins) {
      await _disposePlugin(plugin);
    }
  }

  Future<PluginState> _stateOf(String pluginId) async {
    if (_registry.getPlugin(pluginId) == null) {
      throw ArgumentError.value(pluginId, 'pluginId', 'Plugin no registrado');
    }
    final states = await load();
    return states.firstWhere((state) => state.plugin.id == pluginId);
  }

  Future<PluginState> _resolve(HomePlugin plugin, UserPluginPreference preference) async {
    PluginState state(PluginStatus status, [Object? error]) => PluginState(
          plugin: plugin,
          preference: preference,
          status: status,
          error: error,
        );

    try {
      if (!await plugin.isAvailable()) {
        await _disposePlugin(plugin);
        return state(PluginStatus.unavailable);
      }
    } catch (error, stackTrace) {
      onError?.call(plugin.id, error, stackTrace);
      return state(PluginStatus.unavailable, error);
    }

    if (!preference.isEnabled) {
      return state(PluginStatus.disabled);
    }

    if (_initialized.contains(plugin.id)) {
      return state(PluginStatus.ready);
    }
    try {
      await plugin.initialize();
      _initialized.add(plugin.id);
      return state(PluginStatus.ready);
    } catch (error, stackTrace) {
      onError?.call(plugin.id, error, stackTrace);
      return state(PluginStatus.failed, error);
    }
  }

  Future<void> _disposePlugin(HomePlugin plugin) async {
    if (!_initialized.remove(plugin.id)) {
      return;
    }
    try {
      await plugin.dispose();
    } catch (error, stackTrace) {
      onError?.call(plugin.id, error, stackTrace);
    }
  }
}
