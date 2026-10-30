import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

/// Aplica los registros recibidos: avanza el HLC, los pasa al participante de
/// su colección, guarda los conflictos nuevos y los añade al log para
/// reenviarlos.
class RecordApplier {
  RecordApplier({
    required ChangeLog log,
    required SyncParticipants participants,
    required ConflictRepository conflicts,
    required SyncStateRepository state,
    required HlcClock hlcClock,
  })  : _log = log,
        _participants = participants,
        _conflicts = conflicts,
        _state = state,
        _hlcClock = hlcClock;

  /// Colección del motor con las resoluciones de conflictos: el id de la
  /// entidad es el del conflicto y el campo [resolvedOptionField], la opción.
  static const String conflictsCollection = 'sync.conflicts';
  static const String resolvedOptionField = 'resolvedOptionId';

  final ChangeLog _log;
  final SyncParticipants _participants;
  final ConflictRepository _conflicts;
  final SyncStateRepository _state;
  final HlcClock _hlcClock;

  /// Aplica [records]. Se salta los que ya tiene. Rechaza, sin aplicarlos ni
  /// guardarlos, los de una marca demasiado adelantada: volverán a llegar en
  /// otra sesión. Los de una colección sin participante solo se guardan.
  Future<ApplyOutcome> apply(List<ChangeRecord> records) async {
    final VersionVector known = await _log.vector();
    final List<ChangeRecord> accepted = <ChangeRecord>[];
    final Set<String> seen = <String>{};
    int rejected = 0;
    for (final ChangeRecord record in records) {
      if (known.includes(record) || !seen.add(record.opId)) {
        continue;
      }
      try {
        _hlcClock.receive(record.hlc);
        accepted.add(record);
      } on HlcException {
        rejected++;
      }
    }
    final Map<String, List<ChangeRecord>> byCollection = <String, List<ChangeRecord>>{};
    for (final ChangeRecord record in accepted) {
      byCollection.putIfAbsent(record.collection, () => <ChangeRecord>[]).add(record);
    }
    final List<SyncConflict> detected = <SyncConflict>[];
    for (final MapEntry<String, List<ChangeRecord>> group in byCollection.entries) {
      final SyncParticipant? participant = _participants.forCollection(group.key);
      if (participant != null) {
        detected.addAll(await participant.applyRemote(group.value));
      }
    }
    final List<SyncConflict> added = <SyncConflict>[];
    for (final SyncConflict conflict in detected) {
      if (await _conflicts.get(conflict.id) == null) {
        await _conflicts.save(conflict);
        added.add(conflict);
      }
    }
    await _applyResolutions(byCollection[conflictsCollection] ?? const <ChangeRecord>[]);
    await _log.append(accepted);
    await _state.saveLastHlc(_hlcClock.last);
    return ApplyOutcome(applied: accepted.length, rejected: rejected, conflicts: added);
  }

  /// Marca resueltos los conflictos abiertos que otro dispositivo resolvió.
  Future<void> _applyResolutions(List<ChangeRecord> records) async {
    for (final ChangeRecord record in records) {
      final SyncConflict? conflict = await _conflicts.get(record.entityId);
      for (final FieldChange change in record.changes) {
        if (conflict != null &&
            !conflict.isResolved &&
            change is ValueChange &&
            change.field == resolvedOptionField &&
            conflict.options.any((ConflictOption option) => option.id == change.value)) {
          await _conflicts.save(conflict.resolve(change.value! as String));
        }
      }
    }
  }
}

/// Resultado de [RecordApplier.apply].
class ApplyOutcome extends Equatable {
  ApplyOutcome({required this.applied, required this.rejected, required List<SyncConflict> conflicts})
      : conflicts = List<SyncConflict>.unmodifiable(conflicts);

  static final ApplyOutcome none = ApplyOutcome(applied: 0, rejected: 0, conflicts: const <SyncConflict>[]);

  /// Registros nuevos aplicados y guardados.
  final int applied;

  /// Registros rechazados por su marca.
  final int rejected;

  /// Conflictos nuevos.
  final List<SyncConflict> conflicts;

  ApplyOutcome operator +(ApplyOutcome other) => ApplyOutcome(
        applied: applied + other.applied,
        rejected: rejected + other.rejected,
        conflicts: <SyncConflict>[...conflicts, ...other.conflicts],
      );

  @override
  List<Object?> get props => <Object?>[applied, rejected, conflicts];
}
