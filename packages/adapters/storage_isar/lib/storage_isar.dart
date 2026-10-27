/// Adaptador de almacenamiento sobre Isar (`isar_community`).
///
/// Abre la base de datos con los esquemas de infraestructura y los de los
/// adaptadores Isar de cada plugin ([IsarSchemaModule]) e implementa
/// `PluginPreferenceRepository`. Solo lo importan los adaptadores Isar y
/// quien compone la app (la app o una app de ejemplo).
///
/// Reexporta la API de Isar para que todos los adaptadores Isar usen la misma
/// versión.
library;

export 'package:isar_community/isar.dart';

export 'src/isar_database.dart';
export 'src/isar_schema_module.dart';
export 'src/plugin_preferences/isar_plugin_preference_repository.dart';
