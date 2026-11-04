import 'data_space.dart';
import 'data_space_exception.dart';

/// Espacios de este dispositivo y cuál es el activo. Se guarda fuera de las
/// bases de los espacios, porque hay que leerlo antes de abrir ninguna. Toda
/// implementación pasa `dataSpaceDirectoryContract`
/// (`package:core_spaces/testing.dart`).
abstract interface class DataSpaceDirectory {
  /// Todos los espacios, ordenados por `createdAt` y después por `id`.
  Future<List<DataSpace>> spaces();

  /// Emite [spaces] al escuchar y cada vez que cambian.
  Stream<List<DataSpace>> watchSpaces();

  /// El espacio activo, o `null` solo si no hay ninguno.
  Future<DataSpace?> active();

  /// Cambia el espacio activo. Lanza `UnknownDataSpaceException` si no existe.
  Future<void> setActive(String spaceId);

  /// Guarda [space] y reemplaza el que tenga su `id`. El primero que se guarda
  /// pasa a ser el activo. Lanza, sin guardar nada,
  /// `DuplicateHouseholdSpaceException` si otro espacio tiene su hogar y
  /// `DuplicateDatabaseNameException` si otro tiene su base.
  Future<void> save(DataSpace space);

  /// Quita el espacio [spaceId] de la lista (sus datos los borra
  /// `DataSpaceStorage`). No falla si no existe. Lanza
  /// `ActiveDataSpaceRemovalException` si es el activo.
  Future<void> remove(String spaceId);
}

/// Comprueba que [space] puede guardarse junto a [others] (los demás
/// espacios, sin el suyo). Para las implementaciones de
/// [DataSpaceDirectory.save].
void checkCanSaveSpace(DataSpace space, Iterable<DataSpace> others) {
  for (final DataSpace other in others) {
    if (other.id == space.id) {
      continue;
    }
    if (space.householdId != null && other.householdId == space.householdId) {
      throw DuplicateHouseholdSpaceException(householdId: space.householdId!, existingSpaceId: other.id);
    }
    if (other.databaseName == space.databaseName) {
      throw DuplicateDatabaseNameException(databaseName: space.databaseName, existingSpaceId: other.id);
    }
  }
}

/// [spaces] en el orden de [DataSpaceDirectory.spaces].
List<DataSpace> sortSpaces(Iterable<DataSpace> spaces) => spaces.toList()
  ..sort((DataSpace a, DataSpace b) {
    final int byDate = a.createdAt.compareTo(b.createdAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
