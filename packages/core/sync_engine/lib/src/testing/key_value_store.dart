import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../engine/local_recorder.dart';

/// Participante de prueba: entidades de clave-valor con conjuntos, fusionadas
/// con [SyncMetadata]. Escribe como lo haría un repositorio: estampa el HLC y
/// registra el cambio en el log a la vez.
class KeyValueStore implements SyncParticipant {
  KeyValueStore({required LocalRecorder Function() recorder, this.collection = 'kv'}) : _recorder = recorder;

  /// Campo que marca una entidad como borrada.
  static const String deletedField = 'deletedAt';

  final String collection;
  final LocalRecorder Function() _recorder;
  final Map<String, KeyValueEntity> _entities = <String, KeyValueEntity>{};

  @override
  Set<String> get collections => <String>{collection};

  /// Entidades (también las borradas), por id.
  Map<String, KeyValueEntity> get entities => Map<String, KeyValueEntity>.unmodifiable(_entities);

  /// Estado comparable entre dispositivos: valores y elementos presentes.
  Map<String, Object?> snapshot() => <String, Object?>{
        for (final String id in _entities.keys.toList()..sort()) id: _entities[id]!.snapshot(),
      };

  Future<void> put(String entityId, Map<String, Object?> values) => _write(entityId, <FieldChange>[
        for (final MapEntry<String, Object?> entry in values.entries) ValueChange(entry.key, entry.value),
      ]);

  Future<void> setElement(String entityId, String field, String element, {required bool present}) =>
      _write(entityId, <FieldChange>[ElementChange(field, element, present: present)]);

  Future<void> delete(String entityId) => put(entityId, <String, Object?>{deletedField: true});

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async {
    for (final ChangeRecord record in records) {
      _merge(record.entityId, record.changes, record.hlc);
    }
    return const <SyncConflict>[];
  }

  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {}

  Future<void> _write(String entityId, List<FieldChange> changes) async {
    final ChangeRecord record = await _recorder().record(collection, entityId, changes);
    _merge(entityId, record.changes, record.hlc);
  }

  void _merge(String entityId, List<FieldChange> changes, Hlc hlc) {
    final KeyValueEntity current = _entities[entityId] ?? KeyValueEntity(const <String, Object?>{}, SyncMetadata.empty);
    final SyncMerge merge = current.metadata.apply(changes, hlc);
    _entities[entityId] = KeyValueEntity(<String, Object?>{
      ...current.values,
      for (final FieldChange change in merge.winning)
        if (change is ValueChange) change.field: change.value,
    }, merge.metadata);
  }
}

/// Entidad de [KeyValueStore].
class KeyValueEntity extends Equatable {
  KeyValueEntity(Map<String, Object?> values, this.metadata) : values = Map<String, Object?>.unmodifiable(values);

  final Map<String, Object?> values;
  final SyncMetadata metadata;

  bool get isDeleted => values[KeyValueStore.deletedField] == true;

  Map<String, Object?> snapshot() => <String, Object?>{
        'values': <String, Object?>{for (final String key in values.keys.toList()..sort()) key: values[key]},
        'elements': <String, Object?>{
          for (final String field in metadata.elements.keys.toList()..sort())
            field: metadata.presentElements(field).toList()..sort(),
        },
        'origin': metadata.originDeviceId,
      };

  @override
  List<Object?> get props => <Object?>[values, metadata];
}
