import 'home_plugin.dart';
import 'user_plugin_preference.dart';

/// Etapa alcanzada por un plugin registrado dentro del ciclo de vida
/// Existencia → Disponibilidad → Activación → Inicialización.
enum PluginStatus {
  /// El dispositivo no cumple las capacidades físicas del plugin.
  unavailable,

  /// El usuario lo desactivó.
  disabled,

  /// `initialize()` lanzó una excepción.
  failed,

  /// Inicializado correctamente y listo para renderizarse.
  ready,
}

/// Estado de un plugin registrado tras ejecutar el ciclo de vida.
class PluginState {
  final HomePlugin plugin;
  final UserPluginPreference preference;
  final PluginStatus status;
  final Object? error;

  const PluginState({
    required this.plugin,
    required this.preference,
    required this.status,
    this.error,
  });

  /// Un plugin activado se muestra en el dashboard aunque su inicialización
  /// haya fallado (con un tile de error local).
  bool get isVisibleOnDashboard =>
      status == PluginStatus.ready || status == PluginStatus.failed;
}
