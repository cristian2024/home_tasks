import 'dart:convert';

import '../../domain/entities/household_item.dart';
import '../../domain/entities/item_event.dart';
import '../../domain/entities/physical_identifier.dart';
import '../../domain/value_objects/item_metadata.dart';
import '../models/isar_household_item.dart';
import '../models/isar_item_event.dart';
import '../models/isar_physical_identifier.dart';

/// Conversión bidireccional entre entidades de dominio y colecciones Isar.
///
/// Isar devuelve las fechas en hora local: al leer se convierten siempre a
/// UTC (spec §20).
abstract final class ItemDataMapper {
  static IsarHouseholdItem toIsarItem(HouseholdItem item) => IsarHouseholdItem()
    ..id = item.id
    ..name = item.name
    ..description = item.description
    ..metadataJson = jsonEncode(item.metadata.values)
    ..createdAt = item.createdAt.toUtc()
    ..updatedAt = item.updatedAt.toUtc();

  static HouseholdItem fromIsarItem(IsarHouseholdItem model) => HouseholdItem(
        id: model.id,
        name: model.name,
        description: model.description,
        metadata: ItemMetadata((jsonDecode(model.metadataJson) as Map<String, Object?>)),
        createdAt: model.createdAt.toUtc(),
        updatedAt: model.updatedAt.toUtc(),
      );

  static IsarPhysicalIdentifier toIsarIdentifier(PhysicalIdentifier identifier) => IsarPhysicalIdentifier()
    ..id = identifier.id
    ..rawValue = identifier.rawValue
    ..type = identifier.type
    ..itemId = identifier.itemId
    ..boundAt = identifier.boundAt.toUtc();

  static PhysicalIdentifier fromIsarIdentifier(IsarPhysicalIdentifier model) => PhysicalIdentifier(
        id: model.id,
        rawValue: model.rawValue,
        type: model.type,
        itemId: model.itemId,
        boundAt: model.boundAt.toUtc(),
      );

  static IsarItemEvent toIsarEvent(ItemEvent event) => IsarItemEvent()
    ..id = event.id
    ..itemId = event.itemId
    ..kind = event.kind
    ..title = event.title
    ..description = event.description
    ..timestamp = event.timestamp.toUtc();

  static ItemEvent fromIsarEvent(IsarItemEvent model) => ItemEvent(
        id: model.id,
        itemId: model.itemId,
        kind: model.kind,
        title: model.title,
        description: model.description,
        timestamp: model.timestamp.toUtc(),
      );
}
