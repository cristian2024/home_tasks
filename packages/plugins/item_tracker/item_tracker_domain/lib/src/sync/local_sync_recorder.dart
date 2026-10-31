import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';

import 'item_tracker_codec.dart';
import 'synced_entity.dart';

/// Una entidad escrita en local: su copia sincronizada actual (o `null` si es
/// nueva) y sus campos después de la escritura.
class LocalSyncWrite extends Equatable {
  LocalSyncWrite({required this.collection, required this.id, required Map<String, Object?> fields, this.current})
      : fields = Map<String, Object?>.unmodifiable(fields);

  final String collection;
  final String id;
  final Map<String, Object?> fields;
  final SyncedEntity? current;

  @override
  List<Object?> get props => <Object?>[collection, id, fields, current];
}

/// Resultado de [LocalSyncRecorder.record].
class LocalSyncChanges extends Equatable {
  LocalSyncChanges(List<ChangeRecord> records, List<SyncedEntity> entities)
      : records = List<ChangeRecord>.unmodifiable(records),
        entities = List<SyncedEntity>.unmodifiable(entities);

  static final LocalSyncChanges none = LocalSyncChanges(const <ChangeRecord>[], const <SyncedEntity>[]);

  /// Un registro por entidad que cambió, con `seq` consecutivos.
  final List<ChangeRecord> records;

  /// Las copias sincronizadas nuevas de esas entidades.
  final List<SyncedEntity> entities;

  @override
  List<Object?> get props => <Object?>[records, entities];
}

/// Convierte una escritura local de los repositorios en registros de cambio,
/// todos con la misma marca, y en las copias sincronizadas que la reflejan.
class LocalSyncRecorder {
  LocalSyncRecorder({required HlcClock hlcClock, IdGenerator ids = const UuidV4Generator()})
      : _hlcClock = hlcClock,
        _ids = ids;

  final HlcClock _hlcClock;
  final IdGenerator _ids;

  String get deviceId => _hlcClock.deviceId;

  /// Registros de [writes] a partir de [nextSeq]. Las entidades sin cambios
  /// no generan registro.
  LocalSyncChanges record(List<LocalSyncWrite> writes, {required int nextSeq}) {
    final List<(LocalSyncWrite, List<FieldChange>)> changed = <(LocalSyncWrite, List<FieldChange>)>[
      for (final LocalSyncWrite write in writes)
        if (ItemTrackerCodec.diff(write.current?.fields, write.fields) case final List<FieldChange> changes
            when changes.isNotEmpty)
          (write, changes),
    ];
    if (changed.isEmpty) {
      return LocalSyncChanges.none;
    }
    final Hlc hlc = _hlcClock.now();
    final List<ChangeRecord> records = <ChangeRecord>[];
    final List<SyncedEntity> entities = <SyncedEntity>[];
    for (final (LocalSyncWrite write, List<FieldChange> changes) in changed) {
      records.add(ChangeRecord(
        opId: _ids.newId(),
        deviceId: deviceId,
        seq: nextSeq + records.length,
        collection: write.collection,
        entityId: write.id,
        hlc: hlc,
        changes: changes,
      ));
      entities.add((write.current ?? SyncedEntity(collection: write.collection, id: write.id)).apply(changes, hlc));
    }
    return LocalSyncChanges(records, entities);
  }
}
