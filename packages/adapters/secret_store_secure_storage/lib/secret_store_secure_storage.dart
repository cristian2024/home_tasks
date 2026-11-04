/// Adaptador de `SecretStore` (`core_secrets`) con flutter_secure_storage.
///
/// Quien compone la app solo elige [SecureStorageSecrets]; los demás paquetes
/// piden `SecretStore` al `ServiceLocator`.
library;

export 'src/secure_storage_secret_store.dart';
