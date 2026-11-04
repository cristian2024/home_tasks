import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

/// Ids `id-1`, `id-2`… (no son UUID, pero sirven para ordenar).
class SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${(++_next).toString().padLeft(3, '0')}';
}

/// [count] dispositivos en la misma red, con el primero como creador del
/// hogar y el resto unidos, ya anunciándose. Se liberan al terminar el test.
Future<List<SimulatedDevice>> household(
  int count, {
  InMemorySyncNetwork? network,
  FixedClock? clock,
  bool advertise = true,
}) async {
  final InMemorySyncNetwork sharedNetwork = network ?? InMemorySyncNetwork();
  final FixedClock sharedClock = clock ?? FixedClock(DateTime.utc(2026, 10, 30, 12));
  final SequentialIds ids = SequentialIds();
  final List<SimulatedDevice> devices = <SimulatedDevice>[
    for (int i = 0; i < count; i++)
      await SimulatedDevice.create('device-$i', network: sharedNetwork, clock: sharedClock, ids: ids),
  ];
  for (final SimulatedDevice device in devices) {
    addTearDown(device.dispose);
  }
  final HouseholdInvitation invitation = await devices.first.households.create();
  for (final SimulatedDevice device in devices.skip(1)) {
    await device.households.join(invitation);
  }
  if (advertise) {
    for (final SimulatedDevice device in devices) {
      await device.advertise();
    }
  }
  return devices;
}
