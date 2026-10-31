import 'package:storage_isar/adapter.dart';

part 'isar_item_tracker_synced.g.dart';

/// Copia sincronizada de un objeto o un identificador (`SyncedEntity`). La
/// fila con [collection] igual a [migrationMarker] marca que la migración ya
/// se hizo.
@collection
class IsarItemTrackerSynced {
  static const String migrationMarker = 'item_tracker.migrated';

  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: <CompositeIndex>[CompositeIndex('entityId')])
  late String collection;

  late String entityId;

  /// Campos en JSON.
  late String fieldsJson;

  /// `SyncMetadata.toJson` en JSON.
  late String metadataJson;
}
