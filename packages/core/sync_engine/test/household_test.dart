import 'dart:convert';
import 'dart:typed_data';

import 'package:core_secrets/testing.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:core_utils/core_utils.dart';
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
      expect(secrets.values, <String, String>{
        HouseholdService.secretKeyFor(invitation.household.id): base64Url.encode(invitation.key),
      });
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
      final HouseholdInvitation invitation = await service.create();
      await secrets.delete(HouseholdService.secretKeyFor(invitation.household.id));

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

  group('clave por hogar', () {
    final Household legacyHousehold = Household(id: 'hogar-antiguo', epoch: 1, creatorDeviceId: 'id-001');
    late String legacyKey;

    /// Estado de una versión con un solo hogar: el hogar guardado y su clave
    /// con el nombre antiguo.
    Future<void> legacySetup() async {
      await service.ensureDevice(defaultName: 'Teléfono');
      await state.saveHousehold(legacyHousehold);
      legacyKey = base64Url.encode(await FakeSyncCipher().newKey());
      await secrets.write(HouseholdService.legacySecretKey, legacyKey);
    }

    String keyOf(String householdId) => secrets.values[HouseholdService.secretKeyFor(householdId)]!;

    test('migra la clave antigua del hogar actual y la conserva', () async {
      await legacySetup();

      final HouseholdKeys? keys = await service.keys();

      expect(keys!.household, legacyHousehold);
      expect(secrets.values, <String, String>{
        HouseholdService.legacySecretKey: legacyKey,
        HouseholdService.secretKeyFor(legacyHousehold.id): legacyKey,
      });
      expect(base64Url.encode((await service.invitation()).key), legacyKey);
    });

    test('dos servicios sobre el mismo almacén, cada uno en su hogar, no se pisan', () async {
      // Ids propios (id-101…), como otro espacio con su propio hogar.
      final HouseholdService other = HouseholdService(
        state: InMemorySyncStateRepository(),
        secrets: secrets,
        cipher: FakeSyncCipher(),
        ids: _OffsetIds(100),
      );
      await service.ensureDevice(defaultName: 'Teléfono');
      await other.ensureDevice(defaultName: 'Teléfono');

      final HouseholdInvitation mine = await service.create();
      final HouseholdInvitation theirs = await other.create();

      expect(mine.household.id, isNot(theirs.household.id));
      expect(await service.invitation(), mine);
      expect(await other.invitation(), theirs);

      await other.leave();
      expect(await service.invitation(), mine);
    });

    test('con la clave antigua de otro hogar, un hogar nuevo usa la suya', () async {
      await legacySetup();
      final HouseholdService other = serviceFor(InMemorySyncStateRepository(), secrets);
      await other.ensureDevice(defaultName: 'Teléfono');

      final HouseholdInvitation created = await other.create();

      expect(keyOf(created.household.id), base64Url.encode(created.key));
      expect(secrets.values[HouseholdService.legacySecretKey], legacyKey);
      await other.leave();
      expect(secrets.values[HouseholdService.legacySecretKey], legacyKey, reason: 'no es la de su hogar');
    });

    test('expel de un hogar antiguo mantiene al día la clave antigua', () async {
      await legacySetup();

      final HouseholdInvitation rotated = await service.expel('b');

      expect(keyOf(legacyHousehold.id), base64Url.encode(rotated.key));
      expect(secrets.values[HouseholdService.legacySecretKey], base64Url.encode(rotated.key));
    });

    test('join a una época nueva de un hogar antiguo mantiene al día la clave antigua', () async {
      await legacySetup();
      final Uint8List newKey = await FakeSyncCipher().newKey();

      await service.join(HouseholdInvitation(household: legacyHousehold.nextEpoch(), key: newKey));

      expect(secrets.values[HouseholdService.legacySecretKey], base64Url.encode(newKey));
      expect(keyOf(legacyHousehold.id), base64Url.encode(newKey));
    });

    test('leave de un hogar antiguo borra las dos claves', () async {
      await legacySetup();

      await service.leave();

      expect(secrets.values, isEmpty);
    });

    test('un corte al copiar la clave se repite sin perderla', () async {
      await legacySetup();
      final _FailingSecretStore failing = _FailingSecretStore(secrets.values);
      final HouseholdService flaky = serviceFor(state, failing);

      failing.failWrites = true;
      await expectLater(flaky.keys(), throwsA(isA<_WriteFailure>()));
      expect(failing.values, <String, String>{HouseholdService.legacySecretKey: legacyKey});

      failing.failWrites = false;
      expect(await flaky.keys(), isNotNull);
      expect(failing.values[HouseholdService.secretKeyFor(legacyHousehold.id)], legacyKey);
    });

    test('si la copia no coincide, falla sin tocar la clave antigua', () async {
      await legacySetup();
      final _FailingSecretStore corrupting = _FailingSecretStore(secrets.values)..corruptWrites = true;

      await expectLater(serviceFor(state, corrupting).keys(), throwsStateError);
      expect(corrupting.values[HouseholdService.legacySecretKey], legacyKey);
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

      expect(invitation.encode(), startsWith('HOMETASKS:'));
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

    test('con UUID, el código es corto y solo lleva caracteres del modo alfanumérico del QR', () {
      final HouseholdInvitation invitation = HouseholdInvitation(
        household: Household(
          id: '0b6f4a0e-3c2d-4e5f-8a9b-1c2d3e4f5a6b',
          epoch: 300,
          creatorDeviceId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        ),
        key: Uint8List.fromList(List<int>.generate(SyncCipher.keyLength, (int i) => i * 7)),
      );

      final String code = invitation.encode();

      expect(code, matches(RegExp(r'^HOMETASKS:[A-Z2-7]+$')));
      expect(code.length, lessThanOrEqualTo(121));
      expect(HouseholdInvitation.parse(code), invitation);
    });

    test('parse acepta el código en minúsculas y con espacios o saltos de línea', () async {
      final HouseholdInvitation invitation = await _otherHousehold();
      final String code = invitation.encode();
      final String spaced = '  ${code.substring(0, 20)} \n${code.substring(20)}\t';

      expect(HouseholdInvitation.parse(code.toLowerCase()), invitation);
      expect(HouseholdInvitation.parse(spaced), invitation);
    });

    test('parse rechaza un código compacto dañado', () async {
      final String code = (await _otherHousehold()).encode();
      final String body = code.substring('HOMETASKS:'.length);

      for (final String text in <String>[
        'HOMETASKS:',
        'HOMETASKS:${body.substring(0, body.length - 10)}',
        'HOMETASKS:${body}AAAAAAAA',
        'HOMETASKS:${body.substring(1)}',
        'HOMETASKS:1$body',
        'HOMETASKS:Z${body.substring(1)}',
      ]) {
        expect(() => HouseholdInvitation.parse(text), throwsFormatException, reason: text);
      }
    });

    test('parse sigue leyendo las invitaciones de la versión 1', () async {
      final HouseholdInvitation invitation = await _otherHousehold();
      final String legacy = 'hometasks-sync:${base64Url.encode(utf8.encode(jsonEncode(<String, Object?>{
            'v': 1,
            'id': invitation.household.id,
            'epoch': invitation.household.epoch,
            'creator': invitation.household.creatorDeviceId,
            'key': base64Url.encode(invitation.key),
          })))}';

      expect(HouseholdInvitation.parse(legacy), invitation);
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
      final Household household = Household(id: 'household-secret-id', epoch: 1, creatorDeviceId: 'a');
      final HouseholdKeys keys = HouseholdKeys(household, key, cipher);
      final HouseholdKeys same = HouseholdKeys(household, Uint8List.fromList(key), cipher);
      final HouseholdKeys nextEpoch = HouseholdKeys(household.nextEpoch(), key, cipher);

      expect(await same.discoveryId(), await keys.discoveryId());
      expect(await same.authKey(), await keys.authKey());
      expect(await nextEpoch.discoveryId(), isNot(await keys.discoveryId()));
      expect(await nextEpoch.recordsKey(), isNot(await keys.recordsKey()));
      expect(await keys.authKey(), isNot(await keys.recordsKey()));
      expect(await keys.discoveryId(), isNot(contains(household.id)));
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

class _WriteFailure implements Exception {}

/// Ids `id-<n>` desde [offset] + 1, para que no coincidan con los de
/// `SequentialIds`.
class _OffsetIds implements IdGenerator {
  _OffsetIds(this._next);

  int _next;

  @override
  String newId() => 'id-${++_next}';
}

/// [InMemorySecretStore] cuyas escrituras pueden fallar o guardar otro valor.
class _FailingSecretStore extends InMemorySecretStore {
  _FailingSecretStore(super.initial);

  bool failWrites = false;
  bool corruptWrites = false;

  @override
  Future<void> write(String key, String value) {
    if (failWrites) {
      throw _WriteFailure();
    }
    return super.write(key, corruptWrites ? '$value-x' : value);
  }
}
