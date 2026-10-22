import 'home_plugin.dart';

class PluginRegistry {
  final Map<String, HomePlugin> _plugins = {};

  void register(HomePlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw StateError('Error: Plugin duplicado detectado con ID "${plugin.id}".');
    }
    _plugins[plugin.id] = plugin;
  }

  HomePlugin? getPlugin(String id) => _plugins[id];

  /// Plugins en orden de registro.
  List<HomePlugin> get allPlugins => List.unmodifiable(_plugins.values);
}
