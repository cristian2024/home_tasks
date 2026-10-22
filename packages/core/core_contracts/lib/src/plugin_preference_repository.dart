import 'user_plugin_preference.dart';

/// Persistencia de las preferencias del usuario sobre cada plugin, separada de
/// la definición estática del plugin ([HomePlugin]).
///
/// La implementación concreta vive en `core_storage`.
abstract interface class PluginPreferenceRepository {
  /// Devuelve todas las preferencias guardadas. Los plugins sin preferencia
  /// guardada no aparecen en la lista.
  Future<List<UserPluginPreference>> getAll();

  /// Inserta o reemplaza la preferencia de `preference.pluginId`.
  Future<void> save(UserPluginPreference preference);

  /// Inserta o reemplaza varias preferencias en una sola operación atómica.
  Future<void> saveAll(List<UserPluginPreference> preferences);

  /// Emite la lista completa de preferencias cada vez que cambia.
  Stream<List<UserPluginPreference>> watch();
}
