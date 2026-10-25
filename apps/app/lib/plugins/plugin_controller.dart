import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/foundation.dart';

/// Estado de los plugins compartido por el dashboard, el catálogo y el guard
/// del router. Envuelve a [PluginLifecycleManager] y notifica cada cambio.
class PluginController extends ChangeNotifier {
  PluginController(this._manager);

  final PluginLifecycleManager _manager;
  List<PluginState> _states = const <PluginState>[];
  bool _loaded = false;

  /// Todos los plugins registrados, ordenados por `sortOrder`.
  List<PluginState> get states => _states;

  /// Plugins que se muestran en el dashboard (activos y disponibles, aunque
  /// su inicialización haya fallado).
  List<PluginState> get dashboard =>
      _states.where((PluginState state) => state.isVisibleOnDashboard).toList();

  bool get isLoaded => _loaded;

  PluginState? stateOf(String pluginId) =>
      _states.where((PluginState state) => state.plugin.id == pluginId).firstOrNull;

  /// Carga (o recarga) los plugins: inicializa los activos que falten y
  /// reintenta los que fallaron.
  Future<void> load() => _update(_manager.load);

  Future<void> setEnabled(String pluginId, {required bool enabled}) =>
      _update(() => _manager.setEnabled(pluginId, enabled: enabled));

  /// Mueve una tarjeta del dashboard de [oldIndex] a la posición final
  /// [newIndex] (convención de `ReorderableListView.onReorderItem`). Los
  /// plugins que no se muestran conservan su orden relativo, al final.
  Future<void> moveDashboardTile(int oldIndex, int newIndex) {
    final List<String> visible = dashboard.map((PluginState state) => state.plugin.id).toList();
    final String moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);
    final Iterable<String> hidden = _states
        .map((PluginState state) => state.plugin.id)
        .where((String id) => !visible.contains(id));
    return _update(() => _manager.reorder(<String>[...visible, ...hidden]));
  }

  Future<void> disposePlugins() => _manager.disposeAll();

  Future<void> _update(Future<List<PluginState>> Function() action) async {
    _states = await action();
    _loaded = true;
    notifyListeners();
  }
}
