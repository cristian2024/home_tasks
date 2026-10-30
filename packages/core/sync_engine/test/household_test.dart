import 'dart:convert';
import 'dart:typed_data';

import 'package:core_secrets/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'helpers/household.dart';

void main() {
  late InMemorySyncStateRepository state;
  late InMemorySecretStore secrets;
  late HouseholdService service;

  HouseholdService serviceFor(InMemorySyncStateRepository state, InMemorySecretStore secrets) =>
      HouseholdService(state: state, secrets: secrets, cipher: FakeSyncCipher(), ids: SequentialIds());

  setUp(() {
    state = InMemorySyncStateRepository();
    secrets = InMemorySecretStore();
    service = serviceFor(state, secrets);
  });

  group('identidad del dispositivo', () {
    test('ensureDevice la crea una vez y renameDevice cambia el nombre', () async {
      final DeviceIdentity created = await service.ensureDevice(defaultName: 'Teléfono');

      expect(created, DeviceIdentity(deviceId: 'id-001', name: 'Teléfono'));
      expect(await service.ensureDevice(defaultName: 'Otro'), created);
      expect(await service.renameDevice('Teléfono de Ana'), DeviceIdentity(deviceId: 'id-001', name: 'Teléfono de Ana'));
      expect(await state.readDevice(), DeviceIdentity(deviceId: 'id-001', name: 'Teléfono de Ana'));
    });

    test('sin identidad, las operaciones del hogar fallan', () async {
      await expectLater(service.create(), throwsStateError);
      await expectLater(service.renameDevice('x'), throwsStateError);
    });
  });

  group('hogar', () {
    setUp(() => service.ensureDevice(defaultName: 'Teléfono'));

    test('create guarda el hogar y la clave, y devuelve la invitación', () async {
      final HouseholdInvitation invitation = await service.create();

      expect(invitation.household, Household(id: 'id-002', epoch: 1, creatorDeviceId: 'id-001'));
      expect(await service.current(), invitation.household);
      expect(secrets.values[HouseholdService.secretKey], base64Url.encode(invitation.key));
      expect(await service.invitation(), invitation);
      expect((await service.keys())!.household, invitation.household);
    });

    test('create falla si ya hay hogar', () async {
      await service.create();

      await expectLater(service.create(), throwsA(isA<AlreadyInHouseholdException>()));
    });

    test('sin hogar no hay claves ni invitación', () async {
      expect(await service.keys(), isNull);
      await expectLater(service.invitation(), throwsA(isA<NotInHouseholdException>()));
    });

    test('sin la clave no hay claves aunque haya hogar', () async {
      await service.create();
      await secrets.delete(HouseholdService.secretKey);

      expect(await service.keys(), isNull);
    });

    test('join se une, adopta una época más nueva e ignora una más vieja', () async {
      final HouseholdInvitation first = await _otherHousehold(epoch: 1);
      final HouseholdInvitation second = await _otherHousehold(epoch: 2);

      await service.join(first);
      expect(await service.current(), first.household);

      await service.join(second);
      await service.join(first);
      expect(await service.current(), second.household);
      expect((await service.invitation()).key, second.key);
    });

    test('join a otro hogar falla', () async {
      await service.create();

      await expectLater(service.join(await _otherHousehold()), throwsA(isA<AlreadyInHouseholdException>()));
    });

    test('join sin identidad falla', () async {
      final HouseholdService fresh = serviceFor(InMemorySyncStateRepository(), InMemorySecretStore());

      await expectLater(fresh.join(await _otherHousehold()), throwsStateError);
    });

    test('leave borra el hogar, la clave y los dispositivos conocidos', () async {
      await service.create();
      await state.savePeer(SyncPeer(deviceId: 'b', name: 'b', lastSyncedAt: DateTime.utc(2026)));

      await service.leave();
      await service.leave();

      expect(await service.current(), isNull);
      expect(secrets.values, isEmpty);
      expect(await state.peers(), isEmpty);
    });

    test('watch emite los cambios del hogar', () async {
      final Future<List<Household?>> emitted = service.watch().take(3).toList();

      final HouseholdInvitation invitation = await service.create();
      await service.leave();

      expect(await emitted, <Household?>[null, invitation.household, null]);
    });

    test('expel, solo del creador, abre una época con otra clave y olvida al expulsado', () async {
      final HouseholdInvitation original = await service.create();
      await state.savePeer(SyncPeer(deviceId: 'b', name: 'b', lastSyncedAt: DateTime.utc(2026)));
      await state.savePeer(SyncPeer(deviceId: 'c', name: 'c', lastSyncedAt: DateTime.utc(2026)));

      final HouseholdInvitation rotated = await service.expel('b');

      expect(rotated.household, original.household.nextEpoch());
      expect(rotated.key, isNot(original.key));
      expect(await service.invitation(), rotated);
      expect((await state.peers()).map((SyncPeer peer) => peer.deviceId), <String>['c']);
    });

    test('expel falla sin hogar o si no es el creador', () async {
      await expectLater(service.expel('b'), throwsA(isA<NotInHouseholdException>()));

      await service.join(await _otherHousehold());
      await expectLater(service.expel('b'), throwsA(isA<NotHouseholdCreatorException>()));
    });
  });

  group('HouseholdInvitation', () {
    test('encode y parse son inversos, con y sin relay', () async {
      final HouseholdInvitation invitation = await _otherHousehold();
      final HouseholdInvitation withRelay = HouseholdInvitation(
        household: invitation.household,
        key: invitation.key,
        relayUrl: 'https://relay.example',
      );

      expect(invitation.encode(), startsWith('hometasks-sync:'));
      expect(HouseholdInvitation.parse(invitation.encode()), invitation);
      expect(HouseholdInvitation.parse(withRelay.encode()), withRelay);
      expect(HouseholdInvitation.parse(withRelay.encode()).relayUrl, 'https://relay.example');
    });

    test('copia la clave y rechaza una de otra longitud', () async {
      final Uint8List key = Uint8List(SyncCipher.keyLength);
      final HouseholdInvitation invitation =
          HouseholdInvitation(household: Household(id: 'h', epoch: 1, creatorDeviceId: 'a'), key: key);

      key[0] = 1;

      expect(invitation.key[0], 0);
      expect(
        () => HouseholdInvitation(household: invitation.household, key: Uint8List(16)),
        throwsArgumentError,
      );
    });

    test('parse rechaza lo que no es una invitación válida', () {
      String encoded(Map<String, Object?> json) => 'hometasks-sync:${base64Url.encode(utf8.encode(jsonEncode(json)))}';
      final Map<String, Object?> valid = <String, Object?>{
        'v': 1,
        'id': 'h',
        'epoch': 1,
        'creator': 'a',
        'key': base64Url.encode(Uint8List(32)),
      };

      expect(HouseholdInvitation.parse(encoded(valid)).household.id, 'h');
      for (final String text in <String>[
        'https://example.com',
        'hometasks-sync:%%%',
        encoded(<String, Object?>{...valid, 'v': 2}),
        encoded(<String, Object?>{...valid, 'epoch': 0}),
        encoded(<String, Object?>{...valid, 'key': base64Url.encode(Uint8List(3))}),
        'hometasks-sync:${base64Url.encode(utf8.encode('[1]'))}',
      ]) {
        expect(() => HouseholdInvitation.parse(text), throwsFormatException, reason: text);
      }
    });
  });

  group('HouseholdKeys', () {
    test('los dispositivos del hogar derivan lo mismo; otra época u otro hogar, no', () async {
      final FakeSyncCipher cipher = FakeSyncCipher();
      final Uint8List key = await cipher.newKey();
      final Household household = Household(id: 'h', epoch: 1, creatorDeviceId: 'a');
      final HouseholdKeys keys = HouseholdKeys(household, key, cipher);
      final HouseholdKeys same = HouseholdKeys(household, Uint8List.fromList(key), cipher);
      final HouseholdKeys nextEpoch = HouseholdKeys(household.nextEpoch(), key, cipher);

      expect(await same.discoveryId(), await keys.discoveryId());
      expect(await same.authKey(), await keys.authKey());
      expect(await nextEpoch.discoveryId(), isNot(await keys.discoveryId()));
      expect(await nextEpoch.recordsKey(), isNot(await keys.recordsKey()));
      expect(await keys.authKey(), isNot(await keys.recordsKey()));
      expect(await keys.discoveryId(), isNot(contains('h')));
      expect(keys.recordAssociatedData('a', 1), isNot(keys.recordAssociatedData('a', 2)));
    });
  });

  test('las excepciones describen el error', () {
    expect(const NotInHouseholdException().toString(), startsWith('NotInHouseholdException: '));
    expect(const AlreadyInHouseholdException('h').message, contains('h'));
    expect(const NotHouseholdCreatorException().message, isNotEmpty);
    expect(const SyncAuthenticationException('x').toString(), 'SyncAuthenticationException: x');
    expect(const SyncProtocolException('y').message, 'y');
  });
}

Future<HouseholdInvitation> _otherHousehold({int epoch = 1}) async => HouseholdInvitation(
      household: Household(id: 'other-house', epoch: epoch, creatorDeviceId: 'other-device'),
      key: await FakeSyncCipher().newKey(),
    );
