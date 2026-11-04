# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- `SecureStorageSecrets`: `DependencyModule` que registra `SecureStorageSecretStore` como `SecretStore` de `core_secrets`. Quien compone la app solo lo elige.
- `SecureStorageSecretStore`: secretos en Keychain (iOS y macOS) y Keystore (Android) con flutter_secure_storage. En iOS y macOS se leen tras el primer desbloqueo y nunca salen del dispositivo (`first_unlock_this_device`, sin iCloud Keychain).
- Pasa la batería `secretStoreContract`.
- README del paquete.
