import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_secrets/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  late ServiceLocator services;

  setUp(() {
    services = ServiceLocator()
      ..registerSingleton<ChangeLog>(InMemoryChangeLog())
      ..registerSingleton<SyncStateRepository>(InMemorySyncStateRepository())
      ..registerSingleton<ConflictRepository>(InMemoryConflictRepository())
      ..registerSingleton<SecretStore>(InMemorySecretStore())
      ..registerSingleton<SyncCipher>(FakeSyncCipher());
  });

  tearDown(() => services.reset());

  test('crea la identidad y registra el motor, con un HlcClock propio', () async {
    await SyncModule(deviceName: 'Teléfono', clock: FixedClock(DateTime.utc(2026))).register(services);

    final DeviceIdentity device = (await services.get<SyncStateRepository>().readDevice())!;
    expect(device.name, 'Teléfono');
    expect(services.get<HlcClock>().deviceId, device.deviceId);
    expect(services.isRegistered<HouseholdService>(), isTrue);
    expect(services.isRegistered<SyncEngine>(), isTrue);
    expect(services.isRegistered<ConflictInbox>(), isTrue);
    expect(services.get<SyncController>().status.phase, SyncPhase.disabled);
    expect(services.isRegistered<SyncParticipants>(), isTrue);
    expect(services.isRegistered<SyncTransports>(), isTrue);
  });

  test('continúa el último HLC guardado y respeta un HlcClock ya registrado', () async {
    final Hlc saved = Hlc(wallTime: DateTime.utc(2027).millisecondsSinceEpoch, counter: 4, deviceId: 'x');
    await services.get<SyncStateRepository>().saveLastHlc(saved);

    await const SyncModule().register(services);

    expect(services.get<HlcClock>().now().isAfter(saved), isTrue);

    final ServiceLocator other = ServiceLocator()
      ..registerSingleton<ChangeLog>(InMemoryChangeLog())
      ..registerSingleton<SyncStateRepository>(InMemorySyncStateRepository())
      ..registerSingleton<ConflictRepository>(InMemoryConflictRepository())
      ..registerSingleton<SecretStore>(InMemorySecretStore())
      ..registerSingleton<SyncCipher>(FakeSyncCipher());
    final HlcClock own = HlcClock(deviceId: 'propio', clock: const SystemClock());
    other.registerSingleton<HlcClock>(own);
    await const SyncModule().register(other);
    expect(other.get<HlcClock>(), same(own));
    await other.reset();
  });
}
