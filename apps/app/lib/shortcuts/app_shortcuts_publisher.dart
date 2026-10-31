import 'dart:async';
import 'dart:developer' as developer;

import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';

import '../plugins/plugin_controller.dart';
import 'app_shortcut_defaults.dart';

/// Publica como accesos rápidos del icono los plugins del inicio que tienen
/// pantalla principal ([HomePluginEntryRoute]), en su orden y con su nombre
/// traducido. Los vuelve a publicar cuando cambian los plugins o el idioma.
class AppShortcutsPublisher {
  AppShortcutsPublisher({
    required AppShortcutService service,
    required PluginController plugins,
    required LocalizationCoordinator localization,
    Map<String, String> icons = AppShortcutDefaults.icons,
    int maxShortcuts = AppShortcutDefaults.maxShortcuts,
  })  : _service = service,
        _plugins = plugins,
        _localization = localization,
        _icons = icons,
        _maxShortcuts = maxShortcuts;

  final AppShortcutService _service;
  final PluginController _plugins;
  final LocalizationCoordinator _localization;
  final Map<String, String> _icons;
  final int _maxShortcuts;
  List<AppShortcut>? _published;
  bool _started = false;

  /// `id` (el del plugin) de cada acceso que pulsa el usuario.
  Stream<String> get selections => _service.selections;

  /// Publica los accesos y empieza a seguir los cambios. No hace nada si ya
  /// había empezado.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _plugins.addListener(_publish);
    _localization.languageCode.addListener(_publish);
    _publish();
  }

  /// Accesos que corresponden ahora a los plugins del inicio.
  List<AppShortcut> currentShortcuts() => <AppShortcut>[
        for (final PluginState state in _plugins.dashboard)
          if (state.plugin is HomePluginEntryRoute)
            AppShortcut(
              id: state.plugin.id,
              title: _localization.translate(state.plugin.nameKey),
              iconName: _icons[state.plugin.id],
            ),
      ].take(_maxShortcuts).toList();

  /// Ruta de la pantalla principal del plugin [pluginId], aunque esté
  /// desactivado (el guard del router decide si se abre), o `null` si no
  /// existe o no tiene pantalla principal.
  String? entryRouteOf(String pluginId) {
    final HomePlugin? plugin = _plugins.stateOf(pluginId)?.plugin;
    return plugin is HomePluginEntryRoute ? (plugin as HomePluginEntryRoute).entryRoute : null;
  }

  /// Deja de seguir los cambios. Los accesos siguen en el lanzador.
  void dispose() {
    if (_started) {
      _plugins.removeListener(_publish);
      _localization.languageCode.removeListener(_publish);
      _started = false;
    }
  }

  void _publish() {
    final List<AppShortcut> shortcuts = currentShortcuts();
    if (listEquals(shortcuts, _published)) {
      return;
    }
    _published = shortcuts;
    unawaited(_service.setShortcuts(shortcuts).catchError((Object error, StackTrace stackTrace) {
      developer.log('No se pudieron publicar los accesos rápidos', name: 'home_utility_app', error: error, stackTrace: stackTrace);
    }));
  }
}
