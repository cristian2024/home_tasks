import 'package:core_contracts/core_contracts.dart';
import 'package:go_router/go_router.dart';

import '../plugins/plugin_controller.dart';

/// Motivo por el que se bloquea una ruta de plugin.
enum BlockedReason { disabled, unavailable }

/// Bloquea las rutas de plugins que no están listos (§12.3): desactivados,
/// no disponibles o con la inicialización fallida (sus dependencias no están
/// registradas).
class PluginRouteGuard {
  PluginRouteGuard({required PluginRegistry registry, required this.controller})
    : _prefixes = {
        for (final plugin in registry.allPlugins)
          for (final route in plugin.routes.whereType<GoRoute>())
            ?_prefixOf(route.path): plugin.id,
      };

  final PluginController controller;

  /// Primer segmento de cada ruta de plugin (`/item-tracker`) → ID del plugin.
  final Map<String, String> _prefixes;

  static String? _prefixOf(String path) {
    final segments = Uri.parse(path).pathSegments;
    return segments.isEmpty ? null : '/${segments.first}';
  }

  /// `null` si [path] puede abrirse; si no, el motivo del bloqueo.
  BlockedReason? check(String path) {
    final prefix = _prefixOf(path);
    final pluginId = prefix == null ? null : _prefixes[prefix];
    if (pluginId == null) {
      return null;
    }
    final state = controller.stateOf(pluginId);
    return switch (state?.status) {
      PluginStatus.ready => null,
      PluginStatus.disabled => BlockedReason.disabled,
      _ => BlockedReason.unavailable,
    };
  }
}
