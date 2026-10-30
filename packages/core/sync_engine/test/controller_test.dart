import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine/testing.dart';
import 'package:test/test.dart';

import 'helpers/household.dart';

/// Motor que falla con [error] en cada sesión.
class _FailingEngine implements SyncEngine {
  _FailingEngine(this.error);

  Object error;

  @override
  Future<SyncSessionResult> syncWith(SyncTransport transport, SyncEndpoint endpoint) async => throw error;

  @override
  Future<SyncSessionResult> accept(SyncChannel channel) async {
    await channel.close();
    throw error;
  }

  @override
  int get batchSize => 0;

  @override
  Duration get timeout => Duration.zero;
}

Future<SyncStatus> _statusWhere(SimulatedDevice device, bool Function(SyncStatus status) test) =>
    device.controller.watchStatus().firstWhere(test).timeout(const Duration(seconds: 5));

void main() {
  test('sin hogar está desactivado; al crearlo se anuncia y queda esperando', () async {
    final InMemorySyncNetwork network = InMemorySyncNetwork();
    final SimulatedDevice a = await SimulatedDevice.create(
      'a',
      network: network,
      clock: FixedClock(DateTime.utc(2026)),
      ids: SequentialIds(),
    );
    addTearDown(a.dispose);
    final InMemorySyncTransport observer = network.transport();
    addTearDown(observer.dispose);

    await a.controller.start();
    await a.controller.start();
    expect(a.controller.status, SyncStatus());

    final HouseholdInvitation invitation = await a.households.create();
    await _statusWhere(a, (SyncStatus status) => status.phase == SyncPhase.idle);
    await observer.start(SyncAdvertisement(
      discoveryId: await HouseholdKeys(invitation.household, invitation.key, FakeSyncCipher()).discoveryId(),
      deviceId: 'observer',
      deviceName: 'observer',
    ));
    expect((await observer.watchEndpoints().first).single.deviceId, a.deviceId);

    await a.households.leave();
    await _statusWhere(a, (SyncStatus status) => status.phase == SyncPhase.disabled);
    expect(await observer.watchEndpoints().first, isEmpty);
  });

  test('sincroniza solo al ver a otro dispositivo y tras un cambio local', () async {
    final List<SimulatedDevice> devices = await household(2, advertise: false);
    final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
    await a.store.put('leche', <String, Object?>{'name': 'Leche'});

    await b.controller.start();
    await a.controller.start();

    final SyncStatus synced = await _statusWhere(a, (SyncStatus status) => status.lastSyncAt != null);
    await _statusWhere(a, (SyncStatus status) => status.phase == SyncPhase.idle);
    await _statusWhere(b, (SyncStatus status) => status.lastSyncAt != null && status.phase == SyncPhase.idle);
    expect(synced.lastSyncAt, DateTime.utc(2026, 10, 30, 12));
    expect(a.controller.status.visibleDevices.single.deviceId, b.deviceId);
    expect(a.controller.status.pendingChanges, 0);
    expect(a.controller.status.lastError, isNull);
    expect(b.store.entities.keys, <String>['leche']);

    await b.store.put('pan', <String, Object?>{'name': 'Pan'});
    await _statusWhere(b, (SyncStatus status) => status.pendingChanges == 1);
    await _statusWhere(b, (SyncStatus status) => status.pendingChanges == 0);
    expect(a.store.entities.keys, unorderedEquals(<String>['leche', 'pan']));
  });

  test('syncNow sincroniza con los visibles; pause y resume detienen y reanudan', () async {
    final List<SimulatedDevice> devices = await household(2, advertise: false);
    final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
    await a.controller.start();
    await b.controller.start();
    await _statusWhere(a, (SyncStatus status) => status.lastSyncAt != null);

    await b.controller.pause();
    expect(b.controller.status.phase, SyncPhase.disabled);
    await _statusWhere(a, (SyncStatus status) => status.visibleDevices.isEmpty);

    await b.store.put('pan', <String, Object?>{'name': 'Pan'});
    await b.controller.resume();
    expect(b.controller.status.phase, SyncPhase.idle);
    await b.controller.syncNow();
    expect(a.store.entities.keys, <String>['pan']);
  });

  test('stop lo desactiva y guarda el último HLC', () async {
    final List<SimulatedDevice> devices = await household(1, advertise: false);
    final SimulatedDevice a = devices.single;
    await a.controller.start();
    await a.store.put('leche', <String, Object?>{'name': 'Leche'});

    await a.controller.stop();

    expect(a.controller.status.phase, SyncPhase.disabled);
    expect(await a.state.readLastHlc(), a.services.get<HlcClock>().last);
  });

  group('errores', () {
    Future<(SyncController, InMemorySyncTransport)> controllerWith(_FailingEngine engine) async {
      final List<SimulatedDevice> devices = await household(2, advertise: false);
      final (SimulatedDevice a, SimulatedDevice b) = (devices[0], devices[1]);
      final SyncTransports transports = SyncTransports()..add(a.transport);
      final SyncController controller = SyncController(
        engine: engine,
        households: a.households,
        log: a.log,
        transports: transports,
        state: a.state,
        hlcClock: a.services.get<HlcClock>(),
        debounce: Duration.zero,
      );
      addTearDown(controller.stop);
      await controller.start();
      await b.advertise();
      await controller.watchStatus().firstWhere((SyncStatus s) => s.visibleDevices.isNotEmpty);
      return (controller, b.transport);
    }

    final Map<Object, SyncErrorKind?> cases = <Object, SyncErrorKind?>{
      const SyncTransportException('sin red'): SyncErrorKind.transport,
      const SyncAuthenticationException('clave'): SyncErrorKind.authentication,
      const SyncProtocolException('versión'): SyncErrorKind.protocol,
      StateError('otro'): SyncErrorKind.unknown,
      const NotInHouseholdException(): null,
    };
    for (final MapEntry<Object, SyncErrorKind?> entry in cases.entries) {
      test('${entry.key.runtimeType} queda como ${entry.value}', () async {
        final (SyncController controller, _) = await controllerWith(_FailingEngine(entry.key));

        await controller.syncNow();

        expect(controller.status.lastError, entry.value);
        expect(controller.status.phase, SyncPhase.idle);
        expect(controller.status.lastSyncAt, isNull);
      });
    }

    test('también al aceptar una sesión', () async {
      final (SyncController controller, InMemorySyncTransport other) =
          await controllerWith(_FailingEngine(const SyncProtocolException('x')));

      final SyncEndpoint endpoint = (await other.watchEndpoints().first).single;
      final SyncChannel channel = await other.connect(endpoint);
      await channel.messages.toList();

      expect(
        (await controller.watchStatus().firstWhere((SyncStatus s) => s.lastError != null)).lastError,
        SyncErrorKind.protocol,
      );
    });
  });

  test('SyncStatus guarda la fecha en UTC y copyWith cambia solo lo pedido', () {
    final SyncStatus status = SyncStatus(lastSyncAt: DateTime(2026, 10, 30, 9), lastError: SyncErrorKind.transport);

    expect(status.lastSyncAt!.isUtc, isTrue);
    expect(status.copyWith(), status);
    expect(status.copyWith(lastError: () => null).lastError, isNull);
    expect(status.copyWith(phase: SyncPhase.syncing).lastError, SyncErrorKind.transport);
  });
}
