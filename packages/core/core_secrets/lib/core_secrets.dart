/// Contrato para guardar secretos (la clave del hogar, tokens) en un almacén
/// seguro. Quien los necesita pide [SecretStore] al `ServiceLocator`; la
/// implementación la elige la app (p. ej. `secret_store_secure_storage`).
library;

export 'src/secret_store.dart';
