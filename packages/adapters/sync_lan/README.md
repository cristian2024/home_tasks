# sync_lan

Adaptador de `SyncTransport` (`core_sync`) para la red local: descubrimiento mDNS con [`bonsoir`](https://pub.dev/packages/bonsoir) y canales WebSocket con `dart:io`.

## Uso

Quien compone la app solo lo elige, antes de `SyncModule`:

```dart
adapters: <DependencyModule>[LanSyncTransport()]
```

`LanSyncTransport` añade un `LanTransport` a `SyncTransports` (el motor lo encuentra ahí) y lo registra en el locator para liberarlo con `reset()`.

## Cómo funciona

- **Anuncio:** servicio mDNS `_hometasks._tcp` con el nombre del id del dispositivo. El registro TXT lleva:
  - `d`: el `discoveryId`, derivado de la clave de la época. Nunca el id del hogar.
  - `id` y `n`: id y nombre del dispositivo.
- **Descubrimiento:** resuelve los servicios del mismo tipo y muestra los que tienen el mismo `discoveryId`, sin incluir este dispositivo. Usa la primera IPv4; si no hay, la IPv6 o el nombre del host.
- **Conexión:** servidor `HttpServer` en un puerto libre que acepta WebSocket en `/sync`.
  - El cliente envía su `discoveryId` en la cabecera `x-sync-discovery`. El servidor responde 403 si no coincide y 404 a cualquier otra petición.
  - Es solo un filtro: la autenticación real la hace el motor con la clave del hogar.
  - Cada mensaje es una trama binaria; las de texto se ignoran.
- **Primer plano:** la app lo detiene al pasar a segundo plano (`SyncController.pause`). `stop()` deja de anunciarse, de buscar y de aceptar conexiones; los canales abiertos siguen.

## Configuración nativa

- **iOS:** `NSLocalNetworkUsageDescription` y `NSBonjourServices` con `_hometasks._tcp` en `Info.plist`.
- **Android:** permisos `INTERNET`, `ACCESS_NETWORK_STATE` y `CHANGE_WIFI_MULTICAST_STATE`.

Otro tipo de servicio: `LanSyncTransport(serviceType: '_otro._tcp')`, y declararlo igual en iOS.

## Tests

Pasa la batería `syncTransportContract` con dos `LanTransport` reales en loopback (servidor y WebSocket de verdad). mDNS se sustituye por `LoopbackBonsoir` (`test/helpers/`), una plataforma de bonsoir en memoria.

```sh
flutter test
```
