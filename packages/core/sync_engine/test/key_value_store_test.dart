import 'package:core_sync/core_sync.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

import 'helpers/household.dart';

void main() {
  test('KeyValueStore borra, compara por valor y no hace nada al resolver', () async {
    final List<SimulatedDevice> devices = await household(1);
    final KeyValueStore store = devices.single.store;

    await store.put('leche', <String, Object?>{'name': 'Leche'});
    final KeyValueEntity before = store.entities['leche']!;
    await store.delete('leche');
    await store.resolveConflict(
      SyncConflict(
        id: 'c',
        collection: 'kv',
        kind: 'k',
        entityIds: <String>['leche'],
        options: <ConflictOption>[ConflictOption('o')],
        provisionalOptionId: 'o',
        detectedAt: DateTime.utc(2026),
      ),
      'o',
    );

    expect(before.isDeleted, isFalse);
    expect(store.entities['leche']!.isDeleted, isTrue);
    expect(store.entities['leche'], isNot(before));
    expect(KeyValueEntity(before.values, before.metadata), before);
  });

  test('SyncSessionResult compara por valor', () async {
    final List<SimulatedDevice> devices = await household(2);
    final SyncSessionResult result = (await devices[0].syncWith(devices[1]))!;

    expect(
      SyncSessionResult(
        peer: result.peer,
        remoteVector: result.remoteVector,
        localVector: result.localVector,
        sent: result.sent,
        outcome: result.outcome,
      ),
      result,
    );
  });
}
