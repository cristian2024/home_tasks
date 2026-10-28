import 'package:isar_community/isar.dart';

import 'isar_feature.dart';
import 'plugin_preferences/isar_plugin_preference.dart';

/// Apertura de la base de datos Isar. La usa `IsarStorage`.
abstract final class IsarDatabase {
  /// Esquemas propios de la infraestructura, presentes siempre.
  static const List<CollectionSchema<dynamic>> coreSchemas = <CollectionSchema<dynamic>>[IsarPluginPreferenceSchema];

  /// Abre (o devuelve, si ya está abierta) la base de datos [name] en
  /// [directory] con los esquemas de infraestructura y los de [features].
  ///
  /// Lanza [StateError] si dos esquemas distintos usan el mismo nombre de
  /// colección.
  static Future<Isar> open({
    required String directory,
    Iterable<IsarFeature> features = const <IsarFeature>[],
    String name = Isar.defaultName,
  }) async {
    final Isar? existing = Isar.getInstance(name);
    if (existing != null) {
      return existing;
    }
    return Isar.open(
      collectSchemas(features),
      directory: directory,
      name: name,
    );
  }

  /// Une [coreSchemas] con los esquemas de [features], sin duplicados.
  static List<CollectionSchema<dynamic>> collectSchemas(Iterable<IsarFeature> features) {
    final Map<String, CollectionSchema<dynamic>> byName = <String, CollectionSchema<dynamic>>{};
    for (final CollectionSchema<dynamic> schema in <CollectionSchema<dynamic>>[
      ...coreSchemas,
      for (final IsarFeature feature in features) ...feature.schemas,
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
