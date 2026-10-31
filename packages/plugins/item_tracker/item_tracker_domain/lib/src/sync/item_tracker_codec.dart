import 'package:core_sync/core_sync.dart';

import '../entities/household_item.dart';
import '../entities/item_event.dart';
import '../entities/physical_identifier.dart';
import '../errors/item_tracker_exception.dart';
import '../value_objects/item_metadata.dart';
import 'synced_entity.dart';

/// Colecciones de item_tracker en la sincronización.
abstract final class ItemTrackerCollections {
  static const String items = 'item_tracker.items';
  static const String identifiers = 'item_tracker.identifiers';
  static const String events = 'item_tracker.events';

  static const Set<String> all = <String>{items, identifiers, events};
}

/// Conversión entre las entidades de item_tracker y sus campos sincronizados,
/// y diferencia entre dos versiones de los campos.
///
/// Las fechas viajan en ISO 8601 (UTC) y los enums por su nombre.
abstract final class ItemTrackerCodec {
  static const String deletedAt = 'deletedAt';
  static const String parentId = 'parentId';

  static Map<String, Object?> itemFields(HouseholdItem item, {DateTime? deletedAt}) => <String, Object?>{
        'name': item.name,
        'description': item.description,
        'metadata': item.metadata.values,
        'createdAt': _date(item.createdAt),
        'updatedAt': _date(item.updatedAt),
        parentId: item.parentId,
        ItemTrackerCodec.deletedAt: _dateOrNull(deletedAt),
      };

  /// El objeto, o `null` si a [entity] aún le faltan el nombre o la fecha de
  /// creación. Unos metadatos inválidos se leen vacíos.
  static HouseholdItem? itemOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? name = fields['name'];
    final Object? createdAt = fields['createdAt'];
    if (name is! String || createdAt is! String) {
      return null;
    }
    final Object? updatedAt = fields['updatedAt'];
    return HouseholdItem(
      id: entity.id,
      name: name,
      description: fields['description'] as String? ?? '',
      metadata: _metadataOf(fields['metadata']),
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : DateTime.parse(createdAt),
      parentId: fields[parentId] as String?,
    );
  }

  static Map<String, Object?> identifierFields(PhysicalIdentifier identifier, {DateTime? deletedAt}) =>
      <String, Object?>{
        'rawValue': identifier.rawValue,
        'type': identifier.type.name,
        'itemId': identifier.itemId,
        'boundAt': _date(identifier.boundAt),
        ItemTrackerCodec.deletedAt: _dateOrNull(deletedAt),
      };

  /// El identificador, o `null` si a [entity] aún le falta algún campo.
  static PhysicalIdentifier? identifierOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? rawValue = fields['rawValue'];
    final IdentifierType? type = _enumOf(IdentifierType.values, fields['type']);
    final Object? itemId = fields['itemId'];
    final Object? boundAt = fields['boundAt'];
    if (rawValue is! String || type == null || itemId is! String || boundAt is! String) {
      return null;
    }
    return PhysicalIdentifier(
      id: entity.id,
      rawValue: rawValue,
      type: type,
      itemId: itemId,
      boundAt: DateTime.parse(boundAt),
    );
  }

  static Map<String, Object?> eventFields(ItemEvent event) => <String, Object?>{
        'itemId': event.itemId,
        'kind': event.kind.name,
        'title': event.title,
        'description': event.description,
        'timestamp': _date(event.timestamp),
      };

  /// El evento, o `null` si a [entity] le falta algún campo.
  static ItemEvent? eventOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? itemId = fields['itemId'];
    final ItemEventKind? kind = _enumOf(ItemEventKind.values, fields['kind']);
    final Object? title = fields['title'];
    final Object? description = fields['description'];
    final Object? timestamp = fields['timestamp'];
    if (itemId is! String || kind == null || title is! String || description is! String || timestamp is! String) {
      return null;
    }
    return ItemEvent(
      id: entity.id,
      itemId: itemId,
      kind: kind,
      title: title,
      description: description,
      timestamp: DateTime.parse(timestamp),
    );
  }

  /// Momento del borrado guardado en [entity], o `null` si no está borrada.
  static DateTime? deletedAtOf(SyncedEntity entity) {
    final Object? value = entity.fields[deletedAt];
    return value is String ? DateTime.parse(value) : null;
  }

  /// Cambios para pasar de [before] a [after]. Sin [before] (entidad nueva),
  /// solo los campos con valor.
  static List<FieldChange> diff(Map<String, Object?>? before, Map<String, Object?> after) => <FieldChange>[
        for (final MapEntry<String, Object?>(:String key, :Object? value) in after.entries)
          if (before == null ? value != null : !_deepEquals(before[key], value)) ValueChange(key, value),
      ];

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _dateOrNull(DateTime? value) => value == null ? null : _date(value);

  static T? _enumOf<T extends Enum>(List<T> values, Object? name) =>
      values.where((T value) => value.name == name).firstOrNull;

  static ItemMetadata _metadataOf(Object? value) {
    if (value is! Map) {
      return const ItemMetadata.empty();
    }
    try {
      return ItemMetadata(Map<String, Object?>.from(value));
    } on ItemValidationException {
      return const ItemMetadata.empty();
    }
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.entries.every((MapEntry<Object?, Object?> entry) => b.containsKey(entry.key) && _deepEquals(entry.value, b[entry.key]));
    }
    return a == b;
  }
}
