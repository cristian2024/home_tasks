import 'data_space.dart';
import 'data_space_directory.dart';
import 'data_space_exception.dart';
import 'data_space_storage.dart';

/// Borra las bases de espacios que ya no están en [directory]: las que dejó
/// un borrado interrumpido entre quitar el espacio de la lista y borrar sus
/// datos. Solo toca las que empiezan por [DataSpace.databasePrefix], así que
/// nunca borra otra base (p. ej. la de antes de los espacios). Se salta las
/// abiertas. Devuelve los nombres borrados.
Future<Set<String>> deleteOrphanDatabases({
  required DataSpaceDirectory directory,
  required DataSpaceStorage storage,
}) async {
  final Set<String> inUse = <String>{
    for (final DataSpace space in await directory.spaces()) space.databaseName,
  };
  final Set<String> deleted = <String>{};
  for (final String name in await storage.databaseNames()) {
    if (!name.startsWith(DataSpace.databasePrefix) || inUse.contains(name)) {
      continue;
    }
    try {
      await storage.delete(name);
      deleted.add(name);
    } on DataSpaceInUseException {
      // Abierta por otro: se intentará en el próximo arranque.
    }
  }
  return deleted;
}
