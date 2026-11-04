import 'package:storage_isar/adapter.dart';

part 'isar_shopping_list_synced.g.dart';

/// Copia sincronizada de un item, una categoría o una compra
/// (`SyncedEntity`). La fila con [collection] igual a [migrationMarker] marca
/// que la migración ya se hizo.
@collection
class IsarShoppingListSynced {
  static const String migrationMarker = 'shopping_list.migrated';

  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: <CompositeIndex>[CompositeIndex('entityId')])
  late String collection;

  late String entityId;

  /// Campos en JSON.
  late String fieldsJson;

  /// `SyncMetadata.toJson` en JSON.
  late String metadataJson;
}
