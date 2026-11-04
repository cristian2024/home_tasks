import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';

import '../contracts/sync_participant.dart';
import '../model/change_record.dart';
import '../model/sync_conflict.dart';

/// Crea el participante, con sus datos vacíos, para un test.
typedef SyncParticipantFactory<P extends SyncParticipant> = FutureOr<P> Function();

/// Tests de contrato de [SyncParticipant]: aplicar es idempotente y
/// conmutativo. Toda funcionalidad que se sincroniza debe pasarlos.
///
/// - [records]: registros de ejemplo de sus colecciones, con ediciones
///   concurrentes y, si los tiene, casos de conflicto.
/// - [readState]: lee los datos del participante en una forma comparable con
///   `==` (p. ej. la lista de entidades ordenada por id).
/// - [seed]: semilla de los órdenes aleatorios.
void syncParticipantContract<P extends SyncParticipant>(
  String implementation, {
  required SyncParticipantFactory<P> create,
  required List<ChangeRecord> records,
  required Future<Object?> Function(P participant) readState,
  int seed = 1,
  int shuffles = 20,
}) {
  group('SyncParticipant ($implementation)', () {
    Future<(Object?, Set<String>)> applyInBatches(List<List<ChangeRecord>> batches) async {
      final P participant = await create();
      final Set<String> conflictIds = <String>{};
      for (final List<ChangeRecord> batch in batches) {
        final List<SyncConflict> conflicts = await participant.applyRemote(batch);
        conflictIds.addAll(conflicts.map((SyncConflict conflict) => conflict.id));
      }
      return (await readState(participant), conflictIds);
    }

    test('los registros son de sus colecciones', () async {
      final P participant = await create();

      expect(records, isNotEmpty);
      for (final ChangeRecord record in records) {
        expect(participant.collections, contains(record.collection));
      }
    });

    test('aplicar dos veces da lo mismo que aplicar una', () async {
      final (Object? once, Set<String> onceConflicts) = await applyInBatches(<List<ChangeRecord>>[records]);
      final (Object? twice, Set<String> twiceConflicts) =
          await applyInBatches(<List<ChangeRecord>>[records, records]);

      expect(twice, once);
      expect(twiceConflicts, onceConflicts);
    });

    test('el orden, los lotes y las repeticiones no cambian el resultado', () async {
      final Random random = Random(seed);
      final (Object? expected, Set<String> expectedConflicts) = await applyInBatches(<List<ChangeRecord>>[records]);

      for (int round = 0; round < shuffles; round++) {
        final List<ChangeRecord> shuffled = <ChangeRecord>[
          ...records,
          for (final ChangeRecord record in records)
            if (random.nextBool()) record,
        ]..shuffle(random);
        final List<List<ChangeRecord>> batches = <List<ChangeRecord>>[];
        for (int start = 0; start < shuffled.length;) {
          final int end = min(shuffled.length, start + 1 + random.nextInt(shuffled.length));
          batches.add(shuffled.sublist(start, end));
          start = end;
        }

        final (Object? state, Set<String> conflicts) = await applyInBatches(batches);

        expect(state, expected, reason: 'ronda $round, semilla $seed');
        expect(conflicts, expectedConflicts, reason: 'ronda $round, semilla $seed');
      }
    });
  });
}
