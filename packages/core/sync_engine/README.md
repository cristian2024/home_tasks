# sync_engine

Motor de la sincronización entre dispositivos (§10.4 de la spec). Es Dart puro y solo depende de contratos: `core_sync`, `core_secrets`, `core_di` y `core_utils`. Las implementaciones (red, cifrado, almacén seguro, Isar) las eligen los adaptadores.

## Contenido

- **`HouseholdService`**: identidad del dispositivo (`ensureDevice`, `renameDevice`) y hogar.
  - `create()` devuelve la invitación del hogar nuevo.
  - `join(invitation)` se une y fusiona los datos locales al sincronizar. Si ya está en ese hogar, adopta una época más nueva.
  - `leave()` borra la clave y el hogar, no los datos.
  - `expel(deviceId)` solo lo puede hacer el creador: abre una época nueva con otra clave y devuelve su invitación.
  - La clave va en el `SecretStore`, una por hogar (`HouseholdService.secretKeyFor(householdId)`), así que varios servicios sobre el mismo almacén (un espacio de datos por hogar) no se pisan. El resto va en el `SyncStateRepository`.
  - La clave de las versiones con un solo hogar (`sync.household.key`) se copia a la suya la primera vez que se lee, y se conserva y se mantiene al día mientras sea la del hogar actual: así una versión anterior sigue sincronizando. `leave()` la borra si es la de su hogar.
- **`HouseholdInvitation`**: el contenido del QR y del código para copiar. `encode()` da `HOMETASKS:` seguido de los campos en binario y en base32 (unos 120 caracteres con ids UUID): solo mayúsculas, dígitos y `:`, así que el QR usa el modo alfanumérico. `HouseholdInvitation.parse` lo lee sin importar mayúsculas ni espacios, y sigue leyendo las invitaciones de la versión 1 (`hometasks-sync:` con JSON en base64url).
- **`HouseholdKeys`**: claves derivadas por uso, hogar y época (autenticación, registros). `discoveryId()` es el anuncio en la red, que nunca revela el id del hogar.
- **`SyncEngine`**: `syncWith(transport, endpoint)` y `accept(channel)`. Ejecutan una **`SyncSession`**:
  1. `hello` con nonces;
  2. desafío con MAC;
  3. vector cifrado;
  4. lotes de registros, cada uno cifrado con su hogar, época, dispositivo y `seq` como datos asociados;
  5. `done`.

  Al terminar recuerda al otro dispositivo (`SyncPeer`).
- **`RecordApplier`**: aplica lo recibido.
  - Avanza el `HlcClock` y rechaza las marcas demasiado adelantadas, que vuelven a llegar en otra sesión.
  - Reparte los registros por colección entre los `SyncParticipants`. Los de una colección sin participante solo se guardan y se reenvían.
  - Guarda los conflictos nuevos y añade todo al `ChangeLog` (gossip).
- **`ConflictInbox`**: conflictos abiertos, `resolveAutomatically` (confirma la provisional) y `resolve(conflict, optionId)`. La resolución se registra en la colección `sync.conflicts`, y los demás dispositivos marcan el conflicto como resuelto al recibirla.
- **`SyncController`**: decide cuándo sincronizar y publica el estado.
  - Con hogar, arranca los transportes con el anuncio de la época.
  - Sincroniza al ver un dispositivo nuevo (inicia el de `deviceId` menor), tras un cambio local (con `debounce`), con `syncNow()` y con `resume()`. `pause()` detiene los transportes.
  - `watchStatus()` emite un `SyncStatus`: fase, última sincronización, cambios pendientes, dispositivos visibles y tipo del último error.
- **`LocalRecorder`**: registra cambios propios con el siguiente `seq`.
- **`SyncModule`** (`DependencyModule`): compone todo con lo que registraron los adaptadores. Crea la identidad del dispositivo y el `HlcClock` si no hay uno.

## Uso

`SyncModule` va **después** de los adaptadores que registran los contratos, los transportes y los participantes:

```dart
const List<DependencyModule> appAdapters = <DependencyModule>[
  IsarStorage(features: <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar(), SyncIsar()]),
  SecureStorageSecrets(),
  CryptographySyncCipher(),
  LanSyncTransport(),
  SyncModule(deviceName: 'Teléfono'),
];
```

La app arranca el controlador cuando está lista y lo pausa y reanuda con el ciclo de vida:

```dart
await locator.get<SyncController>().start();
```

## Tests

`package:sync_engine/testing.dart` trae:

- **`SyncSimulator`**: N dispositivos de un hogar con ediciones concurrentes, sincronizaciones por pares en orden aleatorio y cortes de red, reproducibles con una semilla. `converge()` reconecta todo y sincroniza hasta que coinciden. `converged` y `logsConverged()` lo comprueban.
- **`SimulatedDevice`**: un dispositivo compuesto con `SyncModule` sobre los dobles en memoria de `core_sync`.
- **`KeyValueStore`**: un participante de clave-valor que escribe como un repositorio.

```sh
dart test
```

Cobertura: 100 %.
