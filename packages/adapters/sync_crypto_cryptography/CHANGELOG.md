# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- `CryptographySyncCipher`: `DependencyModule` que registra `XChaCha20SyncCipher` como `SyncCipher` de `core_sync`. Quien compone la app solo lo elige.
- `XChaCha20SyncCipher`, con el paquete cryptography en Dart puro:
  - cifrado autenticado XChaCha20-Poly1305 con datos asociados y un nonce aleatorio de 24 bytes por mensaje;
  - derivación de claves con HKDF-SHA256 (el uso va en `info`);
  - MAC con HMAC-SHA256, comprobado en tiempo constante;
  - claves y bytes aleatorios de `Random.secure()`.
- Pasa la batería `syncCipherContract`.
- README del paquete.
