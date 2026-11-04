# sync_isar

Adaptador Isar de la sincronización (`core_sync`) sobre `storage_isar`.

## Uso

Quien compone la app lo añade a `IsarStorage`, antes de `SyncModule`:

```dart
IsarStorage(features: <IsarFeature>[ItemTrackerIsar(), ShoppingListIsar(), SyncIsar()])
```

Con la base abierta, `SyncIsar` registra en el `ServiceLocator`:

| Contrato | Implementación |
| :--- | :--- |
| `ChangeLog` | `IsarChangeLog` |
| `SyncStateRepository` | `IsarSyncStateRepository` |
| `ConflictRepository` | `IsarConflictRepository` |
| — | `IsarChangeLogWriter` (para otros adaptadores Isar) |

La clave del hogar no se guarda aquí: va en el `SecretStore`.

## Colecciones

- `IsarSyncChangeRecord`: cada `ChangeRecord`, propio o recibido, en JSON. Índices únicos por `opId` y por `deviceId` + `seq`.
- `IsarSyncVectorEntry`: por dispositivo, hasta qué `seq` se tienen todos sus registros. Se actualiza en la misma transacción que los registros, así que `vector()` no recorre el historial.
- `IsarSyncState`: un solo objeto con el dispositivo, el hogar y el último HLC.
- `IsarSyncPeer`: dispositivos con los que ya se sincronizó.
- `IsarSyncConflict`: la bandeja de conflictos.

## Escribir el cambio con la entidad

Un adaptador Isar de una funcionalidad (p. ej. `item_tracker_isar`) pide `IsarChangeLogWriter` al locator y lo usa **dentro de su transacción de escritura**. Si algo falla, no queda ni la entidad ni el registro:

```dart
await isar.writeTxn(() async {
  await isar.items.put(model);
  final int seq = await writer.nextSeq(deviceId);
  await writer.append(<ChangeRecord>[ChangeRecord(seq: seq, ...)]);
});
```

## Tests

Pasa las baterías `changeLogContract`, `syncStateRepositoryContract` y `conflictRepositoryContract` de `package:core_sync/testing.dart` contra una base Isar real en un directorio temporal. Otros tests comprueban que el writer respeta la transacción de quien lo llama.

```sh
flutter test
```

Cobertura: 100 % (sin contar los `*.g.dart`).
