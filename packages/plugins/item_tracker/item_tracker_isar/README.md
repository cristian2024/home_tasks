# item_tracker_isar

Adaptador Isar del seguimiento de objetos. Implementa `HouseholdItemRepository` (`item_tracker_domain`) y pasa su batería de contrato.

## Uso

Quien compone la app solo lo elige, dentro de `IsarStorage` (`storage_isar`):

```dart
IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])
```

Con la base abierta, `ItemTrackerIsar` registra `HouseholdItemRepository` en el `ServiceLocator`, y el plugin lo pide de ahí. `IsarStorage` debe llevar este adaptador aunque el plugin esté desactivado, para que sus colecciones existan.

## Sincronización

Si la app compone la sincronización (`SyncIsar` en `IsarStorage` y `SyncModule`, que registra el `HlcClock`):

```dart
IsarStorage(features: <IsarFeature>[ItemTrackerIsar(), SyncIsar()]),
...
SyncModule(deviceName: 'Teléfono'),
```

- Cada escritura actualiza su copia sincronizada (`IsarItemTrackerSynced`) y registra sus cambios con el `IsarChangeLogWriter` de `sync_isar`, en la misma transacción.
- `ItemTrackerIsar` añade su `ItemTrackerSyncParticipant` a `SyncParticipants` en el scope raíz: aunque el plugin esté desactivado, sus cambios se reciben y se guardan.
- **Migración:** la primera vez, lo guardado antes recibe su copia, con marcas derivadas de sus fechas y este dispositivo como origen, y sus registros de cambio, para que viajen al unirse a un hogar. Se hace una sola vez, al principio de la primera transacción.
- `ItemTrackerIsar(containmentPolicy: …)` usa la regla de niveles del plugin (por defecto, la de `--dart-define=ITEM_TRACKER_MAX_DEPTH`).

Sin la sincronización compuesta no se registra nada y funciona como antes.

## Datos

- Colecciones `IsarHouseholdItem`, `IsarPhysicalIdentifier` e `IsarItemEvent`. Sus nombres no cambian, para que los datos ya guardados se sigan leyendo.
- `IsarItemTrackerSynced`: copias sincronizadas de objetos e identificadores, y la marca de la migración.
- Toda escritura de varias entidades va en una sola transacción.
- Borrado lógico (spec §10.3): un objeto borrado guarda `deletedAt`, y un identificador quitado, `deletedId` y `deletedAt`. Las consultas solo devuelven los activos. Los registros anteriores a estos campos se leen como activos.

## Tests

Pasan `householdItemRepositoryContract` (con y sin sincronización) e `itemTrackerSyncContract`, contra una base real. Usan Isar real: `setUpAll(() => Isar.initializeIsarCore(download: true))` descarga `libisar` en el paquete (está en `.gitignore`).

```sh
flutter test --coverage
```

Cobertura de los mappers: 100 %.
