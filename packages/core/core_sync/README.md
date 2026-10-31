# core_sync

Contratos y modelo de la sincronización entre dispositivos (§10.4 de la spec). Es Dart puro. Los dominios de las funcionalidades dependen de este paquete para describir y fusionar sus cambios; el motor está en `sync_engine` y las implementaciones (red, cifrado, Isar) en los adaptadores.

## Modelo

- **`ChangeRecord`**: cambio inmutable de una entidad. Es lo único que se intercambia.
  - Lleva `opId`, `deviceId`, `seq` (1, 2, 3… sin huecos por dispositivo), `collection`, `entityId`, un `Hlc` y los cambios de campos.
  - No lleva el hogar: se registra también antes de pertenecer a uno, y el hogar va en los datos asociados del cifrado al enviarlo.
  - `toJson` / `fromJson` para la red.
- **`FieldChange`** (`sealed`):
  - `ValueChange(field, value)`: el campo pasa a valer un valor JSON. Se fusiona por *last-write-wins*.
  - `ElementChange(field, element, present:)`: añade o quita un elemento de un conjunto (p. ej. `categoryIds`). Se fusiona elemento a elemento.
- **`VersionVector`**: `{deviceId: último seq}`. Con `includes`, `covers`, `advance`, `merge` y `countAhead` (cambios pendientes para otro).
- **`SyncMetadata`**: la marca del último cambio de cada campo y de cada elemento de los conjuntos de una entidad, y `createdHlc` (de ahí `originDeviceId`).
  - `apply(changes, hlc)` / `merge(record)` devuelven un `SyncMerge`: los metadatos nuevos y los cambios que ganan, que son los que hay que escribir.
  - La fusión es idempotente y conmutativa. El borrado es un campo más (`deletedAt`) que nadie vuelve a poner a `null`, así que siempre gana a una edición.
  - `toJson` / `fromJson` para guardarlos junto a la entidad.
- **`SyncedEntity`**: copia sincronizada de una entidad, la que guarda cada repositorio junto a sus entidades. El último valor de cada campo y sus `SyncMetadata`. Se fusiona con `apply` / `merge`. Un conjunto se guarda como la lista ordenada de sus elementos presentes. Puede estar incompleta si llegó un cambio antes que el registro que la crea.
- **`FieldDiff.between(before, after)`**: los `FieldChange` para pasar de una versión de los campos a otra. Un valor `Set<String>` es un conjunto y da un `ElementChange` por elemento añadido o quitado.
- **`Household`** (id, época, creador), **`DeviceIdentity`**, **`SyncPeer`**.
- **`SyncConflict`** y **`ConflictOption`**: conflicto de reglas de negocio con su resolución provisional y, cuando el usuario elige, `resolve(optionId)`.
- **`BlobRef`**: referencia a un binario por `sha256`. Reservada.
- Errores (`sealed SyncException`): `SyncTransportException` y `SyncCipherException`.

## Escrituras locales

`LocalSyncRecorder` convierte una escritura local de un repositorio en registros de cambio. El repositorio le pasa, por entidad escrita, un `LocalSyncWrite` con su copia sincronizada actual y sus campos después de escribir. Devuelve un registro por entidad que cambió, todos con la misma marca y `seq` consecutivos desde `nextSeq`, y las copias nuevas. El repositorio guarda ambos en la misma transacción que la entidad.

```dart
final LocalSyncChanges changes = recorder.record(<LocalSyncWrite>[
  LocalSyncWrite(collection: 'shopping_list.items', id: item.id, fields: fields, current: synced),
], nextSeq: (await log.vector())[recorder.deviceId] + 1);
```

## Contratos

| Contrato | Para qué |
| :--- | :--- |
| `ChangeLog` | Registros propios y recibidos: `append` (idempotente por `opId`), `vector`, `watchVector` y `missingFor(remote)`. |
| `SyncStateRepository` | Identidad del dispositivo, hogar, último HLC y dispositivos conocidos. |
| `ConflictRepository` | Bandeja de conflictos: `save`, `get`, `openConflicts` y `watchOpenConflicts`. |
| `SyncCipher` | Cifrado autenticado con datos asociados, derivación de claves, MAC y bytes aleatorios. |
| `SyncTransport` / `SyncChannel` | Anunciarse, ver a los del mismo `discoveryId`, conectar e intercambiar mensajes binarios. |
| `SyncParticipant` | Una funcionalidad que se sincroniza: `applyRemote` (atómico, idempotente y conmutativo) y `resolveConflict`. |

El `ServiceLocator` no lista todas las instancias de un tipo, así que los participantes y los transportes se apuntan en un registro. Cada adaptador lo hace en su `DependencyModule.register`, en el scope raíz:

```dart
SyncParticipants.of(services).add(ItemTrackerSyncParticipant(repository));
SyncTransports.of(services).add(lanTransport);
```

El motor los consulta con `all` y `forCollection`.

## Tests

`package:core_sync/testing.dart` trae:

- una batería por contrato, que toda implementación debe pasar: `changeLogContract`, `syncStateRepositoryContract`, `conflictRepositoryContract`, `syncCipherContract`, `syncTransportContract` y `syncParticipantContract` (aplica los registros de ejemplo en órdenes y lotes aleatorios, con repeticiones, y compara el estado);
- `InMemoryChangeLog`, `InMemorySyncStateRepository` e `InMemoryConflictRepository`;
- `InMemorySyncNetwork`, que crea `InMemorySyncTransport` unidos y permite cortar la comunicación entre dos dispositivos (`partition`, `heal`);
- `FakeSyncCipher`, que cumple la batería pero **no es seguro**.

```sh
dart test
```

Cobertura: 100 %.
