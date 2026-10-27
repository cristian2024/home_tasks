import 'package:isar_community/isar.dart';

import 'isar_schema_module.dart';
import 'plugin_preferences/isar_plugin_preference.dart';

/// Punto único de apertura de la base de datos Isar.
abstract final class IsarDatabase {
  /// Esquemas propios de la infraestructura, presentes siempre.
  static const List<CollectionSchema<dynamic>> coreSchemas = <CollectionSchema<dynamic>>[IsarPluginPreferenceSchema];

  /// Abre (o devuelve, si ya está abierta) la base de datos [name] en
  /// [directory] con los esquemas de infraestructura y los de [modules].
  ///
  /// Lanza [StateError] si dos esquemas distintos usan el mismo nombre de
  /// colección.
  static Future<Isar> open({
    required String directory,
    Iterable<IsarSchemaModule> modules = const <IsarSchemaModule>[],
    String name = Isar.defaultName,
    bool inspector = false,
  }) async {
    final Isar? existing = Isar.getInstance(name);
    if (existing != null) {
      return existing;
    }
    return Isar.open(
      collectSchemas(modules),
      directory: directory,
      name: name,
      inspector: inspector,
    );
  }

  /// Une [coreSchemas] con los esquemas de [modules], sin duplicados.
  static List<CollectionSchema<dynamic>> collectSchemas(Iterable<IsarSchemaModule> modules) {
    final Map<String, CollectionSchema<dynamic>> byName = <String, CollectionSchema<dynamic>>{};
    for (final CollectionSchema<dynamic> schema in <CollectionSchema<dynamic>>[
      ...coreSchemas,
      for (final IsarSchemaModule module in modules) ...module.schemas,
    ]) {
      final CollectionSchema<dynamic>? previous = byName[schema.name];
      if (previous != null && !identical(previous, schema)) {
        throw StateError('Colección Isar duplicada: "${schema.name}".');
      }
      byName[schema.name] = schema;
    }
    return byName.values.toList();
  }
}
