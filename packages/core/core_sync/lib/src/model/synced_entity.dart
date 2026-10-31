import 'package:equatable/equatable.dart';
import 'package:hlc/hlc.dart';

import 'change_record.dart';
import 'field_change.dart';
import 'sync_metadata.dart';

/// Copia sincronizada de una entidad: el último valor de cada campo y la
/// marca con que se escribió. Se fusiona con los registros de cambio, en
/// cualquier orden, y de ella sale lo que lee la app.
///
/// Un conjunto (los campos de los [ElementChange]) se guarda como la lista
/// ordenada de sus elementos presentes.
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
  /// marca por campo y, en los conjuntos, por elemento.
  SyncedEntity apply(List<FieldChange> changes, Hlc hlc) {
    final SyncMerge merge = metadata.apply(changes, hlc);
    return SyncedEntity(
      collection: collection,
      id: id,
      fields: <String, Object?>{
        ...fields,
        for (final FieldChange change in merge.winning)
          change.field: switch (change) {
            ValueChange(:final Object? value) => value,
            ElementChange() => merge.metadata.presentElements(change.field).toList()..sort(),
          },
      },
      metadata: merge.metadata,
    );
  }

  /// Fusiona los cambios de [record].
  SyncedEntity merge(ChangeRecord record) => apply(record.changes, record.hlc);

  @override
  List<Object?> get props => <Object?>[collection, id, fields, metadata];
}
