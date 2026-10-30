# item_tracker_isar

Adaptador Isar del seguimiento de objetos. Implementa `HouseholdItemRepository` (`item_tracker_domain`) y pasa su batería de contrato.

## Uso

Quien compone la app solo lo elige, dentro de `IsarStorage` (`storage_isar`):

```dart
IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])
```

Con la base abierta, `ItemTrackerIsar` registra `HouseholdItemRepository` en el `ServiceLocator`, y el plugin lo pide de ahí. `IsarStorage` debe llevar este adaptador aunque el plugin esté desactivado, para que sus colecciones existan.

## Datos

- Colecciones `IsarHouseholdItem`, `IsarPhysicalIdentifier` e `IsarItemEvent`. Sus nombres no cambian, para que los datos ya guardados se sigan leyendo.
- Toda escritura de varias entidades va en una sola transacción.
- Borrado lógico (spec §10.3): un objeto borrado guarda `deletedAt`, y un identificador quitado, `deletedId` y `deletedAt`. Las consultas solo devuelven los activos. Los registros anteriores a estos campos se leen como activos.

## Tests

Usan Isar real: `setUpAll(() => Isar.initializeIsarCore(download: true))` descarga `libisar` en el paquete (está en `.gitignore`).

```sh
flutter test --coverage
```

Cobertura de los mappers: 100 %.
