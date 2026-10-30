# Changelog

## 0.1.1 - 2026-10-30

### Interno

- El test de `HouseholdKeys` comprueba que el anuncio en la red no contiene el id completo del hogar, en lugar de una sola letra que a veces aparecía por azar.

## 0.1.0 - 2026-10-30

### Añadido

- `HouseholdService`, `HouseholdInvitation` y `HouseholdKeys`: identidad del dispositivo y hogar (crear, invitar, unirse, salir y expulsar con rotación de clave), con la clave en el `SecretStore`.
- `SyncEngine` y `SyncSession`: sesiones autenticadas con un desafío MAC, vector cifrado, registros cifrados por separado y gossip.
- `RecordApplier`: aplica lo recibido con los participantes, avanza el HLC, rechaza marcas adelantadas y guarda los conflictos nuevos.
- `ConflictInbox`: bandeja de conflictos con resolución automática o manual, que se sincroniza a los demás dispositivos.
- `SyncController` y `SyncStatus`: planificación (al ver un dispositivo, tras un cambio local, `syncNow`, `pause` y `resume`) y estado visible.
- `LocalRecorder` y `SyncModule`.
- Errores `NotInHouseholdException`, `AlreadyInHouseholdException`, `NotHouseholdCreatorException`, `SyncAuthenticationException` y `SyncProtocolException`, bajo el `sealed` `SyncEngineException`.
- `package:sync_engine/testing.dart`: `SyncSimulator`, `SimulatedDevice` y `KeyValueStore`.
- README del paquete.
