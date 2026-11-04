# secret_store_secure_storage

Adaptador de `SecretStore` (`core_secrets`) con [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage): Keychain en iOS y macOS, Keystore en Android.

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[SecureStorageSecrets()]
```

`SecureStorageSecrets` registra `SecureStorageSecretStore` como `SecretStore`. Una clave vacía se rechaza con `ArgumentError`.

En iOS y macOS los secretos usan `first_unlock_this_device`:
- se pueden leer tras el primer desbloqueo, también en segundo plano;
- nunca salen del dispositivo: ni a iCloud Keychain ni a una copia restaurada en otro.

`SecureStorageSecretStore(storage: …)` permite pasar otra configuración de `FlutterSecureStorage`.

## Configuración nativa

En Android, la app excluye el almacén de las copias de seguridad (`android:allowBackup="false"` o `dataExtractionRules`). Si se restaurara en otro teléfono, la clave no se podría descifrar con su Keystore.

## Tests

Pasa la batería `secretStoreContract` con la plataforma en memoria de flutter_secure_storage (`FlutterSecureStorage.setMockInitialValues`). Otro test comprueba las opciones del Keychain en iOS y macOS.

```sh
flutter test
```

Cobertura: 100 %.
