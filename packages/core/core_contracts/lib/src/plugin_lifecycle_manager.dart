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

  final Set<String> _initialized = <String>{};

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
    final Map<String, UserPluginPreference> saved = <String, UserPluginPreference>{
      for (final UserPluginPreference preference in await _preferences.getAll())
        preference.pluginId: preference,
    };
    final List<HomePlugin> plugins = _registry.allPlugins;

    final List<PluginState> states = <PluginState>[];
    for (int i = 0; i < plugins.length; i++) {
      final HomePlugin plugin = plugins[i];
      final UserPluginPreference preference = saved[plugin.id] ??
          UserPluginPreference(pluginId: plugin.id, isEnabled: true, sortOrder: i);
      states.add(await _resolve(plugin, preference));
    }

    final Map<String, int> registrationIndex = <String, int>{
      for (int i = 0; i < plugins.length; i++) plugins[i].id: i,
    };
    states.sort((PluginState a, PluginState b) {
      final int bySortOrder = a.preference.sortOrder.compareTo(b.preference.sortOrder);
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
    final PluginState current = await _stateOf(pluginId);
    await _preferences.save(current.preference.copyWith(isEnabled: enabled));
    if (!enabled) {
      await _disposePlugin(current.plugin);
    }
    return load();
  }

  /// Persiste un nuevo orden. [orderedPluginIds] debe contener exactamente los
  /// IDs de todos los plugins registrados.
  Future<List<PluginState>> reorder(List<String> orderedPluginIds) async {
    final Set<String> registeredIds = _registry.allPlugins.map((HomePlugin plugin) => plugin.id).toSet();
    if (orderedPluginIds.length != registeredIds.length ||
        !registeredIds.containsAll(orderedPluginIds)) {
      throw ArgumentError.value(
        orderedPluginIds,
        'orderedPluginIds',
        'Debe contener exactamente los IDs de todos los plugins registrados',
      );
    }

    final Map<String, PluginState> states = <String, PluginState>{
      for (final PluginState state in await load()) state.plugin.id: state,
    };
    await _preferences.saveAll(<UserPluginPreference>[
      for (int i = 0; i < orderedPluginIds.length; i++)
        states[orderedPluginIds[i]]!.preference.copyWith(sortOrder: i),
    ]);
    return load();
  }

  /// Libera todos los plugins inicializados (cierre de la aplicación).
  Future<void> disposeAll() async {
    for (final HomePlugin plugin in _registry.allPlugins) {
      await _disposePlugin(plugin);
    }
  }

  Future<PluginState> _stateOf(String pluginId) async {
    if (_registry.getPlugin(pluginId) == null) {
      throw ArgumentError.value(pluginId, 'pluginId', 'Plugin no registrado');
    }
    final List<PluginState> states = await load();
    return states.firstWhere((PluginState state) => state.plugin.id == pluginId);
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
