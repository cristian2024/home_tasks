# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- `LanSyncTransport`: `DependencyModule` que añade un `LanTransport` a `SyncTransports` y lo libera con el locator. Quien compone la app solo lo elige.
- `LanTransport`, el `SyncTransport` de la red local:
  - se anuncia y busca por mDNS (bonsoir) con `_hometasks._tcp`; el registro TXT lleva el `discoveryId`, el id y el nombre del dispositivo, nunca el id del hogar;
  - acepta canales WebSocket en un puerto libre (`ws://<ip>:<puerto>/sync`) y rechaza a quien no presenta el mismo `discoveryId`;
  - cada mensaje es una trama binaria; `connect` falla con `SyncTransportException` si el otro no responde en `connectTimeout`.
- Pasa la batería `syncTransportContract` con dos instancias en loopback.
- README del paquete.
