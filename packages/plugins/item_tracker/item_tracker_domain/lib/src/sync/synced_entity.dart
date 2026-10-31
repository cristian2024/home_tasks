import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

/// Copia sincronizada de una entidad: el último valor de cada campo y la
/// marca con que se escribió. Se fusiona con los registros de cambio, en
/// cualquier orden, y de ella sale lo que lee la app.
///
/// Puede estar incompleta (llegó un cambio antes que el registro que la
/// crea): entonces no se muestra hasta que llega el resto.
class SyncedEntity extends Equatable {
  SyncedEntity({
    required this.collection,
    required this.id,
    Map<String, Object?> fields = const <String, Object?>{},
    SyncMetadata? metadata,
  })  : fields = Map<String, Object?>.unmodifiable(fields),
        metadata = metadata ?? SyncMetadata.empty;

  final String collection;
  final String id;
  final Map<String, Object?> fields;
  final SyncMetadata metadata;

  /// Fusiona [changes], hechos con la marca [hlc]: gana el valor de mayor
  /// marca por campo.
  SyncedEntity apply(List<FieldChange> changes, Hlc hlc) {
    final SyncMerge merge = metadata.apply(changes, hlc);
    return SyncedEntity(
      collection: collection,
      id: id,
      fields: <String, Object?>{
        ...fields,
        for (final FieldChange change in merge.winning)
          if (change is ValueChange) change.field: change.value,
      },
      metadata: merge.metadata,
    );
  }

  /// Fusiona los cambios de [record].
  SyncedEntity merge(ChangeRecord record) => apply(record.changes, record.hlc);

  @override
  List<Object?> get props => <Object?>[collection, id, fields, metadata];
}
