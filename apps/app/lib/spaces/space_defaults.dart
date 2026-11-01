/// Valores de los espacios de datos.
abstract final class SpaceDefaults {
  /// Base de las versiones con un solo espacio (la que `IsarStorage` abre sin
  /// nombre). El primer espacio la conserva: migrar no copia ningún dato.
  static const String legacyDatabaseName = 'default';
}
