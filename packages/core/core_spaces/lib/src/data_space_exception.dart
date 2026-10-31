/// Errores de los espacios de datos.
sealed class DataSpaceException implements Exception {
  const DataSpaceException();
}

/// No hay ningún espacio con [spaceId].
final class UnknownDataSpaceException extends DataSpaceException {
  const UnknownDataSpaceException(this.spaceId);

  final String spaceId;

  @override
  String toString() => 'UnknownDataSpaceException: no hay ningún espacio $spaceId';
}

/// El hogar [householdId] ya tiene su espacio, [existingSpaceId]: como mucho
/// hay un espacio por hogar.
final class DuplicateHouseholdSpaceException extends DataSpaceException {
  const DuplicateHouseholdSpaceException({required this.householdId, required this.existingSpaceId});

  final String householdId;
  final String existingSpaceId;

  @override
  String toString() => 'DuplicateHouseholdSpaceException: el hogar $householdId ya es el espacio $existingSpaceId';
}

/// La base [databaseName] ya es de otro espacio, [existingSpaceId]: dos
/// espacios mezclarían sus datos.
final class DuplicateDatabaseNameException extends DataSpaceException {
  const DuplicateDatabaseNameException({required this.databaseName, required this.existingSpaceId});

  final String databaseName;
  final String existingSpaceId;

  @override
  String toString() => 'DuplicateDatabaseNameException: la base $databaseName ya es del espacio $existingSpaceId';
}

/// No se puede quitar el espacio activo: primero hay que cambiar a otro.
final class ActiveDataSpaceRemovalException extends DataSpaceException {
  const ActiveDataSpaceRemovalException(this.spaceId);

  final String spaceId;

  @override
  String toString() => 'ActiveDataSpaceRemovalException: $spaceId es el espacio activo';
}

/// La base [databaseName] está abierta: borrarla la corrompería.
final class DataSpaceInUseException extends DataSpaceException {
  const DataSpaceInUseException(this.databaseName);

  final String databaseName;

  @override
  String toString() => 'DataSpaceInUseException: la base $databaseName está abierta';
}
