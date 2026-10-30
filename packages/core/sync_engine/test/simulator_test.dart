import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

void main() {
  for (final int seed in <int>[1, 2, 3, 4, 5, 6, 7, 8]) {
    test('con la semilla $seed, cuatro dispositivos convergen', () async {
      final SyncSimulator simulator = await SyncSimulator.create(devices: 4, seed: seed);
      addTearDown(simulator.dispose);

      await simulator.run(steps: 250);
      await simulator.converge();

      expect(simulator.converged, isTrue, reason: '${simulator.states}');
      expect(await simulator.logsConverged(), isTrue);
      expect(simulator.completedSessions, greaterThan(0));
      expect(simulator.devices.first.store.entities, isNotEmpty);
    });
  }
}
