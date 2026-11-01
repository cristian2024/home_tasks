# Changelog

## 0.1.3 - 2026-11-01

### Cambiado

- `HouseholdInvitation.encode()` escribe la versión 2: `HOMETASKS:` seguido de los campos en binario y en base32. Con ids UUID ocupa unos 120 caracteres en lugar de 235, y el QR usa el modo alfanumérico, así que tiene muchos menos módulos. Un dispositivo con una versión anterior no lee las invitaciones nuevas.
- `HouseholdInvitation.parse` ignora mayúsculas, espacios y saltos de línea en el código, para poder pegarlo desde un mensaje. Sigue leyendo la versión 1.

## 0.1.2 - 2026-10-31

### Cambiado

- `HouseholdService` guarda la clave del hogar con un nombre por hogar (`secretKeyFor(householdId)`): varios servicios sobre el mismo `SecretStore`, cada uno en su hogar, ya no se pisan la clave.
- La clave de las versiones anteriores (`legacySecretKey`) se copia a la nueva la primera vez que se lee, comprobando la copia. Se conserva y se mantiene al día (`join` a otra época, `expel`) mientras sea la del hogar actual, para que volver a una versión anterior siga sincronizando. `leave()` borra las dos si son de su hogar.

### Obsoleto

- `HouseholdService.secretKey`: usar `secretKeyFor(householdId)`.

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
