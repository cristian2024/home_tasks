# core_secrets

Contrato para guardar secretos (la clave del hogar de la sincronización, tokens) en un almacén seguro. Es Dart puro; la implementación la elige la app (p. ej. `secret_store_secure_storage`, sobre Keychain y Keystore).

## Contenido

- **`SecretStore`**:
  - `read(key)`: el valor guardado, o `null` si no hay ninguno.
  - `write(key, value)`: guarda el valor y reemplaza el anterior.
  - `delete(key)`: no falla si la clave no existe.

  Los valores son texto: quien guarda bytes los codifica (p. ej. en base64). Una clave vacía se rechaza con `ArgumentError`.

## Uso

Quien necesita un secreto pide `SecretStore` al `ServiceLocator`:

```dart
final SecretStore secrets = locator.get<SecretStore>();
await secrets.write('sync.household.key', base64Encode(keyBytes));
```

## Tests

`package:core_secrets/testing.dart` trae la batería `secretStoreContract`, que toda implementación debe pasar, e `InMemorySecretStore`, para tests y apps de ejemplo.

```sh
dart test
```
