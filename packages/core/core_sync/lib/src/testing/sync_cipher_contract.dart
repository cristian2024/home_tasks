import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../contracts/sync_cipher.dart';
import '../sync_exception.dart';

/// Crea el cifrador para un test.
typedef SyncCipherFactory = FutureOr<SyncCipher> Function();

/// Tests de contrato de [SyncCipher]. Toda implementación debe pasarlos.
void syncCipherContract(String implementation, {required SyncCipherFactory create}) {
  group('SyncCipher ($implementation)', () {
    late SyncCipher cipher;
    late Uint8List key;
    final Uint8List plaintext = Uint8List.fromList(utf8.encode('{"name":"Leche ñ"}'));
    final Uint8List associatedData = Uint8List.fromList(utf8.encode('house-1|1|device-a|7'));
    final Matcher throwsCipherException = throwsA(isA<SyncCipherException>());

    setUp(() async {
      cipher = await create();
      key = await cipher.newKey();
    });

    test('newKey y randomBytes dan bytes aleatorios de la longitud pedida', () async {
      final Uint8List other = await cipher.newKey();

      expect(key, hasLength(SyncCipher.keyLength));
      expect(other, isNot(key));
      expect(await cipher.randomBytes(24), hasLength(24));
      expect(await cipher.randomBytes(24), isNot(await cipher.randomBytes(24)));
      expect(await cipher.randomBytes(0), isEmpty);
    });

    test('deriveKey es determinista y cambia con la clave y el uso', () async {
      final Uint8List derived = await cipher.deriveKey(key, purpose: 'discovery');

      expect(derived, hasLength(SyncCipher.keyLength));
      expect(await cipher.deriveKey(key, purpose: 'discovery'), derived);
      expect(await cipher.deriveKey(key, purpose: 'records'), isNot(derived));
      expect(await cipher.deriveKey(await cipher.newKey(), purpose: 'discovery'), isNot(derived));
    });

    test('encrypt y decrypt son inversos, también con un mensaje vacío', () async {
      final Uint8List sealed = await cipher.encrypt(plaintext, key: key, associatedData: associatedData);
      final Uint8List empty = await cipher.encrypt(Uint8List(0), key: key, associatedData: Uint8List(0));

      expect(await cipher.decrypt(sealed, key: key, associatedData: associatedData), plaintext);
      expect(await cipher.decrypt(empty, key: key, associatedData: Uint8List(0)), isEmpty);
    });

    test('encrypt da un resultado distinto cada vez y no deja ver el texto', () async {
      final Uint8List first = await cipher.encrypt(plaintext, key: key, associatedData: associatedData);
      final Uint8List second = await cipher.encrypt(plaintext, key: key, associatedData: associatedData);

      expect(first, isNot(second));
      expect(utf8.decode(first, allowMalformed: true), isNot(contains('Leche')));
    });

    test('decrypt falla con otra clave, otros datos asociados o el mensaje alterado', () async {
      final Uint8List sealed = await cipher.encrypt(plaintext, key: key, associatedData: associatedData);
      final Uint8List tampered = Uint8List.fromList(sealed)..[sealed.length ~/ 2] ^= 0x01;

      await expectLater(cipher.decrypt(sealed, key: await cipher.newKey(), associatedData: associatedData),
          throwsCipherException);
      await expectLater(
          cipher.decrypt(sealed, key: key, associatedData: Uint8List.fromList(utf8.encode('house-1|2|device-a|7'))),
          throwsCipherException);
      await expectLater(cipher.decrypt(tampered, key: key, associatedData: associatedData), throwsCipherException);
      await expectLater(cipher.decrypt(Uint8List(3), key: key, associatedData: associatedData), throwsCipherException);
    });

    test('mac es determinista, cambia con la clave y los datos, y verifyMac lo comprueba', () async {
      final Uint8List mac = await cipher.mac(plaintext, key: key);

      expect(mac, hasLength(SyncCipher.keyLength));
      expect(await cipher.mac(plaintext, key: key), mac);
      expect(await cipher.mac(plaintext, key: await cipher.newKey()), isNot(mac));
      expect(await cipher.mac(associatedData, key: key), isNot(mac));
      expect(await cipher.verifyMac(plaintext, mac, key: key), isTrue);
      expect(await cipher.verifyMac(associatedData, mac, key: key), isFalse);
      expect(await cipher.verifyMac(plaintext, mac.sublist(1), key: key), isFalse);
    });

    test('rechaza claves de otra longitud', () async {
      final Uint8List shortKey = Uint8List(16);

      await expectLater(cipher.deriveKey(shortKey, purpose: 'x'), throwsArgumentError);
      await expectLater(cipher.encrypt(plaintext, key: shortKey, associatedData: associatedData), throwsArgumentError);
      await expectLater(cipher.decrypt(plaintext, key: shortKey, associatedData: associatedData), throwsArgumentError);
      await expectLater(cipher.mac(plaintext, key: shortKey), throwsArgumentError);
      await expectLater(cipher.verifyMac(plaintext, plaintext, key: shortKey), throwsArgumentError);
      await expectLater(cipher.randomBytes(-1), throwsArgumentError);
    });
  });
}
