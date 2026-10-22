/// Persistencia local de la aplicación sobre Isar (`isar_community`).
///
/// Reexporta la API de Isar para que los paquetes que definen colecciones la
/// obtengan de aquí con una única versión. Solo la capa `data` de un paquete
/// puede importar esta librería.
library;

export 'package:isar_community/isar.dart';

export 'src/local_database.dart';
export 'src/plugin_preferences/isar_plugin_preference_repository.dart';
export 'src/storage_schema_contributor.dart';
