import 'dart:convert';
import 'dart:typed_data';

import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:sync_crypto_cryptography/sync_crypto_cryptography.dart';
import 'package:test/test.dart';

void main() {
  syncCipherContract('XChaCha20SyncCipher', create: XChaCha20SyncCipher.new);

  group('XChaCha20SyncCipher', () {
    final Uint8List plaintext = Uint8List.fromList(utf8.encode('Leche'));
    final Uint8List associatedData = Uint8List.fromList(utf8.encode('house-1|1'));

    test('el resultado es nonce de 24 bytes, texto cifrado y MAC de 16 bytes', () async {
      final XChaCha20SyncCipher cipher = XChaCha20SyncCipher();
      final Uint8List sealed =
          await cipher.encrypt(plaintext, key: await cipher.newKey(), associatedData: associatedData);

      expect(sealed, hasLength(24 + plaintext.length + 16));
    });

    test('otra instancia con la misma clave descifra, deriva y verifica igual', () async {
      final XChaCha20SyncCipher sender = XChaCha20SyncCipher();
      final XChaCha20SyncCipher receiver = XChaCha20SyncCipher();
      final Uint8List key = await sender.newKey();
      final Uint8List sealed = await sender.encrypt(plaintext, key: key, associatedData: associatedData);

      expect(await receiver.decrypt(sealed, key: key, associatedData: associatedData), plaintext);
      expect(await receiver.deriveKey(key, purpose: 'records'), await sender.deriveKey(key, purpose: 'records'));
      expect(await receiver.verifyMac(plaintext, await sender.mac(plaintext, key: key), key: key), isTrue);
    });
  });

  test('CryptographySyncCipher registra XChaCha20SyncCipher como SyncCipher', () async {
    final ServiceLocator services = ServiceLocator();
    addTearDown(services.reset);

    await const CryptographySyncCipher().register(services);

    expect(services.get<SyncCipher>(), isA<XChaCha20SyncCipher>());
  });
}
