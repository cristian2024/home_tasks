import 'package:isar_community/isar.dart';

import 'plugin_preferences/isar_plugin_preference.dart';
import 'storage_schema_contributor.dart';

/// Punto único de apertura de la base de datos local.
abstract final class LocalDatabase {
  /// Esquemas propios de la infraestructura, presentes siempre.
  static const List<CollectionSchema<dynamic>> coreSchemas = [IsarPluginPreferenceSchema];

  /// Abre (o devuelve, si ya está abierta) la base de datos [name] en
  /// [directory] con los esquemas de infraestructura y los de [contributors].
  ///
  /// Lanza [StateError] si dos esquemas distintos usan el mismo nombre de
  /// colección.
  static Future<Isar> open({
    required String directory,
    Iterable<StorageSchemaContributor> contributors = const [],
    String name = Isar.defaultName,
    bool inspector = false,
  }) async {
    final existing = Isar.getInstance(name);
    if (existing != null) {
      return existing;
    }
    return Isar.open(
      collectSchemas(contributors),
      directory: directory,
      name: name,
      inspector: inspector,
    );
  }

  /// Une [coreSchemas] con los esquemas de [contributors], sin duplicados.
  static List<CollectionSchema<dynamic>> collectSchemas(
    Iterable<StorageSchemaContributor> contributors,
  ) {
    final byName = <String, CollectionSchema<dynamic>>{};
    final all = [
      ...coreSchemas,
      for (final contributor in contributors) ...contributor.storageSchemas,
    ];
    for (final schema in all) {
      final previous = byName[schema.name];
      if (previous != null && !identical(previous, schema)) {
        throw StateError('Colección Isar duplicada: "${schema.name}".');
      }
      byName[schema.name] = schema;
    }
    return byName.values.toList();
  }
}
