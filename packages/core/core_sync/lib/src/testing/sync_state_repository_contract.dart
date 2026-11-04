import 'dart:async';

import 'package:async/async.dart';
import 'package:hlc/hlc.dart';
import 'package:test/test.dart';

import '../contracts/sync_state_repository.dart';
import '../model/household.dart';

/// Crea un repositorio vacío para un test.
typedef SyncStateRepositoryFactory = FutureOr<SyncStateRepository> Function();

/// Tests de contrato de [SyncStateRepository]. Toda implementación debe
/// pasarlos.
void syncStateRepositoryContract(String implementation, {required SyncStateRepositoryFactory create}) {
  group('SyncStateRepository ($implementation)', () {
    late SyncStateRepository repository;
    final Household household = Household(id: 'house-1', epoch: 1, creatorDeviceId: 'device-a');
    SyncPeer peer(String deviceId, {String name = 'Tableta', int day = 1}) =>
        SyncPeer(deviceId: deviceId, name: name, lastSyncedAt: DateTime.utc(2026, 10, day, 18));

    setUp(() async => repository = await create());

    test('empieza vacío', () async {
      expect(await repository.readDevice(), isNull);
      expect(await repository.readHousehold(), isNull);
      expect(await repository.readLastHlc(), isNull);
      expect(await repository.peers(), isEmpty);
    });

    test('guarda y reemplaza la identidad del dispositivo', () async {
      await repository.saveDevice(DeviceIdentity(deviceId: 'device-a', name: 'Teléfono'));
      await repository.saveDevice(DeviceIdentity(deviceId: 'device-a', name: 'Teléfono de Ana'));

      expect(await repository.readDevice(), DeviceIdentity(deviceId: 'device-a', name: 'Teléfono de Ana'));
    });

    test('guarda el hogar, lo reemplaza en una época nueva y lo borra con sus dispositivos', () async {
      await repository.saveHousehold(household);
      await repository.savePeer(peer('device-b'));
      expect(await repository.readHousehold(), household);

      await repository.saveHousehold(household.nextEpoch());
      expect(await repository.readHousehold(), household.nextEpoch());

      await repository.clearHousehold();
      expect(await repository.readHousehold(), isNull);
      expect(await repository.peers(), isEmpty);
    });

    test('watchHousehold emite al escuchar y en cada cambio', () async {
      final StreamQueue<Household?> households = StreamQueue<Household?>(repository.watchHousehold());

      expect(await households.next, isNull);
      await repository.saveHousehold(household);
      await expectLater(households, emitsThrough(household));
      await repository.clearHousehold();
      await expectLater(households, emitsThrough(isNull));
      await households.cancel();
    });

    test('guarda y reemplaza el último HLC', () async {
      final Hlc first = Hlc(wallTime: 1761827400000, counter: 0, deviceId: 'device-a');
      final Hlc second = Hlc(wallTime: 1761827400000, counter: 1, deviceId: 'device-a');

      await repository.saveLastHlc(first);
      await repository.saveLastHlc(second);

      expect(await repository.readLastHlc(), second);
    });

    test('guarda, reemplaza, ordena y olvida dispositivos conocidos', () async {
      await repository.savePeer(peer('device-c'));
      await repository.savePeer(peer('device-b'));
      await repository.savePeer(peer('device-c', name: 'Portátil', day: 2));

      expect(await repository.peers(), <SyncPeer>[peer('device-b'), peer('device-c', name: 'Portátil', day: 2)]);

      await repository.removePeer('device-b');
      await repository.removePeer('device-x');
      expect(await repository.peers(), <SyncPeer>[peer('device-c', name: 'Portátil', day: 2)]);
    });
  });
}
