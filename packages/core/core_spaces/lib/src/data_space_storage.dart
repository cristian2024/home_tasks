/// Las bases de los espacios en el motor de almacenamiento. Toda
/// implementación pasa `dataSpaceStorageContract`
/// (`package:core_spaces/testing.dart`).
abstract interface class DataSpaceStorage {
  /// Nombres de las bases que existen.
  Future<Set<String>> databaseNames();

  /// Borra la base [databaseName] con todos sus datos. No falla si no existe.
  /// Lanza `DataSpaceInUseException`, sin borrar nada, si está abierta.
  Future<void> delete(String databaseName);
}
