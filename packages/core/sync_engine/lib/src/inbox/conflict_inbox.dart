import 'package:core_sync/core_sync.dart';

import '../engine/local_recorder.dart';
import '../engine/record_applier.dart';

/// Bandeja de conflictos: los abiertos y cómo resolverlos. La resolución se
/// sincroniza: los demás dispositivos la marcan también en su bandeja.
class ConflictInbox {
  ConflictInbox({
    required ConflictRepository conflicts,
    required SyncParticipants participants,
    required LocalRecorder recorder,
  })  : _conflicts = conflicts,
        _participants = participants,
        _recorder = recorder;

  final ConflictRepository _conflicts;
  final SyncParticipants _participants;
  final LocalRecorder _recorder;

  Stream<List<SyncConflict>> watchOpen() => _conflicts.watchOpenConflicts();

  Future<List<SyncConflict>> open() => _conflicts.openConflicts();

  /// Confirma la resolución provisional.
  Future<void> resolveAutomatically(SyncConflict conflict) => resolve(conflict, conflict.provisionalOptionId);

  /// Aplica [optionId] con el participante de la colección del conflicto, lo
  /// marca resuelto y registra la resolución para los demás dispositivos.
  ///
  /// Lanza [ArgumentError] si [optionId] no es una de sus opciones y
  /// [StateError] si ningún participante se encarga de su colección.
  Future<void> resolve(SyncConflict conflict, String optionId) async {
    final SyncConflict resolved = conflict.resolve(optionId);
    final SyncParticipant? participant = _participants.forCollection(conflict.collection);
    if (participant == null) {
      throw StateError('Ningún participante se encarga de ${conflict.collection}');
    }
    await participant.resolveConflict(conflict, optionId);
    await _conflicts.save(resolved);
    await _recorder.record(
      RecordApplier.conflictsCollection,
      conflict.id,
      <FieldChange>[ValueChange(RecordApplier.resolvedOptionField, optionId)],
    );
  }
}
