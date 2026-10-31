/// Adaptador de `SyncTransport` (`core_sync`) para la red local.
///
/// Quien compone la app solo elige [LanSyncTransport]; el motor de la
/// sincronización encuentra el transporte en `SyncTransports`.
library;

export 'src/lan_sync_transport.dart';
export 'src/lan_transport.dart';
