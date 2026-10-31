import 'dart:convert';

import 'package:core_sync/core_sync.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../models/isar_shopping_list_synced.dart';
import '../models/isar_shopping_purchase.dart';
import 'shopping_data_mapper.dart';

/// Conversión de las copias sincronizadas y de lo que la sincronización deja
/// para leer.
abstract final class SyncedEntityMapper {
  static IsarShoppingListSynced toIsar(SyncedEntity entity) => IsarShoppingListSynced()
    ..collection = entity.collection
    ..entityId = entity.id
    ..fieldsJson = jsonEncode(entity.fields)
    ..metadataJson = jsonEncode(entity.metadata.toJson());

  static SyncedEntity fromIsar(IsarShoppingListSynced model) => SyncedEntity(
        collection: model.collection,
        id: model.entityId,
        fields: jsonDecode(model.fieldsJson) as Map<String, Object?>,
        metadata: SyncMetadata.fromJson(jsonDecode(model.metadataJson)),
      );

  static IsarShoppingItem toIsarItem(ShoppingResolved<ShoppingItem> resolved) =>
      ShoppingDataMapper.toIsarItem(resolved.entity)..deletedAt = resolved.deletedAt?.toUtc();

  static IsarShoppingCategory toIsarCategory(ShoppingResolved<ShoppingCategory> resolved) =>
      ShoppingDataMapper.toIsarCategory(resolved.entity)..deletedAt = resolved.deletedAt?.toUtc();

  static IsarShoppingPurchase toIsarPurchase(ShoppingResolved<ShoppingPurchase> resolved) =>
      ShoppingDataMapper.toIsarPurchase(resolved.entity)..deletedAt = resolved.deletedAt?.toUtc();
}
