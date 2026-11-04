import 'dart:convert';

import 'package:core_sync/core_sync.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../models/isar_household_item.dart';
import '../models/isar_item_tracker_synced.dart';
import '../models/isar_physical_identifier.dart';
import 'item_data_mapper.dart';

/// Conversión de las copias sincronizadas y de lo que la sincronización deja
/// para leer.
abstract final class SyncedEntityMapper {
  static IsarItemTrackerSynced toIsar(SyncedEntity entity) => IsarItemTrackerSynced()
    ..collection = entity.collection
    ..entityId = entity.id
    ..fieldsJson = jsonEncode(entity.fields)
    ..metadataJson = jsonEncode(entity.metadata.toJson());

  static SyncedEntity fromIsar(IsarItemTrackerSynced model) => SyncedEntity(
        collection: model.collection,
        id: model.entityId,
        fields: jsonDecode(model.fieldsJson) as Map<String, Object?>,
        metadata: SyncMetadata.fromJson(jsonDecode(model.metadataJson)),
      );

  static IsarHouseholdItem toIsarItem(ResolvedItem resolved) =>
      ItemDataMapper.toIsarItem(resolved.item)..deletedAt = resolved.deletedAt?.toUtc();

  static IsarPhysicalIdentifier toIsarIdentifier(ResolvedIdentifier resolved) =>
      ItemDataMapper.toIsarIdentifier(resolved.identifier)
        ..deletedId = resolved.isActive ? null : resolved.identifier.id
        ..deletedAt = resolved.deletedAt?.toUtc();

  /// Campos sincronizados de un objeto tal como está guardado.
  static Map<String, Object?> itemFields(IsarHouseholdItem model) => ItemTrackerCodec.itemFields(
        ItemDataMapper.fromIsarItem(model),
        deletedAt: model.deletedAt?.toUtc(),
      );

  /// Campos sincronizados de un identificador tal como está guardado.
  static Map<String, Object?> identifierFields(IsarPhysicalIdentifier model) => ItemTrackerCodec.identifierFields(
        ItemDataMapper.fromIsarIdentifier(model),
        deletedAt: model.isDeleted ? (model.deletedAt ?? model.boundAt).toUtc() : null,
      );
}
