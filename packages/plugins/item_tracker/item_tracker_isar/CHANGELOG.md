# Changelog

## 0.1.2 - 2026-10-30

### Añadido

- Sincronización con `sync_isar`, si la app la compuso (hay `HlcClock` e `IsarChangeLogWriter` en el locator):
  - cada escritura local actualiza las copias sincronizadas (colección nueva `IsarItemTrackerSynced`) y registra sus cambios en la misma transacción;
  - `IsarHouseholdItemRepository` implementa `ItemTrackerSyncStore` y pasa `itemTrackerSyncContract`;
  - `ItemTrackerIsar` añade su `ItemTrackerSyncParticipant` a `SyncParticipants` en el scope raíz, así que un plugin desactivado sigue recibiendo sus cambios. `ItemTrackerIsar(containmentPolicy:)` permite pasar la regla de niveles del plugin.
- Migración (spec §10.4.8): la primera vez que se sincroniza, lo guardado antes recibe su copia, con marcas derivadas de sus fechas, y sus registros de cambio. Se hace una sola vez.

### Cambiado

- item_tracker_domain 0.2.1, sync_isar 0.1.0, core_sync 0.1.1 y core_utils 0.1.1.

## 0.1.1 - 2026-10-29

### Añadido

- `deleteItems` con borrado lógico: el objeto y sus identificadores activos quedan marcados como borrados (`deletedAt`) en una sola transacción, con los objetos movidos y los eventos. Las consultas y los streams solo devuelven objetos activos.
- README del paquete.

### Cambiado

- item_tracker_domain 0.2.0. `IsarHouseholdItem` tiene el campo `deletedAt`; los objetos ya guardados se leen como activos.

## 0.1.0 - 2026-10-27

### Añadido

- Adaptador Isar de item_tracker en un paquete propio, dentro de `packages/plugins/item_tracker/`. Sustituirá a la capa data de `plugin_item_tracker`.
- `ItemTrackerIsar`: `IsarFeature` de `storage_isar`. Quien compone la app solo lo elige; con la base abierta registra `HouseholdItemRepository` en el `ServiceLocator`. Su implementación Isar pasa `householdItemRepositoryContract`.
- Usa los mismos nombres de colección que el plugin, así que los datos ya guardados se siguen leyendo.
