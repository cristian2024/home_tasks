# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- `SyncIsar`: `IsarFeature` de la sincronización. Con la base abierta registra `ChangeLog`, `SyncStateRepository` y `ConflictRepository` de `core_sync` sobre Isar. Quien compone la app solo lo añade a `IsarStorage`.
- Colecciones: registros de cambio (únicos por `opId` y por dispositivo y `seq`), vector local, estado (dispositivo, hogar y último HLC; sin la clave del hogar), dispositivos conocidos y conflictos.
- El vector se actualiza en la misma transacción que los registros, así que leerlo no recorre el historial.
- `IsarChangeLogWriter`: para que los adaptadores Isar de las funcionalidades escriban el registro de cambio en la misma transacción que la entidad (`nextSeq` y `append`).
- Pasa las baterías `changeLogContract`, `syncStateRepositoryContract` y `conflictRepositoryContract`.
- README del paquete.
