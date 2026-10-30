/// Adaptador de `SyncCipher` (`core_sync`) con el paquete cryptography.
///
/// Quien compone la app solo elige [CryptographySyncCipher]; el motor de la
/// sincronización pide `SyncCipher` al `ServiceLocator`.
library;

export 'src/cryptography_sync_cipher.dart';
