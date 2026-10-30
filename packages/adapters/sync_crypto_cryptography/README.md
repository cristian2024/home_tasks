# sync_crypto_cryptography

Adaptador de `SyncCipher` (`core_sync`) con el paquete [`cryptography`](https://pub.dev/packages/cryptography), en Dart puro (sin `cryptography_flutter`).

## Uso

Quien compone la app solo lo elige, antes de `SyncModule`:

```dart
adapters: <DependencyModule>[CryptographySyncCipher()]
```

`CryptographySyncCipher` registra `XChaCha20SyncCipher` como `SyncCipher`:
- `encrypt` / `decrypt`: XChaCha20-Poly1305 con datos asociados. Cada mensaje lleva un nonce aleatorio de 24 bytes; el resultado es nonce, texto cifrado y MAC de 16 bytes. Si la clave o los datos asociados no coinciden, o el mensaje se alteró, `decrypt` lanza `SyncCipherException`.
- `deriveKey`: HKDF-SHA256 sin sal, con el uso (`purpose`) como `info`. Da 32 bytes.
- `mac` / `verifyMac`: HMAC-SHA256. `verifyMac` compara en tiempo constante.
- `newKey` / `randomBytes`: `Random.secure()`.

Todas las claves son de 32 bytes; con otra longitud se lanza `ArgumentError`.

## Tests

Pasa la batería `syncCipherContract` de `package:core_sync/testing.dart`.

```sh
dart test
```

Cobertura: 100 %.
