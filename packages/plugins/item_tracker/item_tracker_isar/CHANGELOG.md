# Changelog

## 0.1.1 - 2026-10-29

### Añadido

- `deleteItems` con borrado lógico: el objeto y sus identificadores activos quedan marcados como borrados (`deletedAt`) en una sola transacción, con los objetos movidos y los eventos. Las consultas y los streams solo devuelven objetos activos.

### Cambiado

- item_tracker_domain 0.2.0. `IsarHouseholdItem` tiene el campo `deletedAt`; los objetos ya guardados se leen como activos.

## 0.1.0 - 2026-10-27

### Añadido

- Adaptador Isar de item_tracker en un paquete propio, dentro de `packages/plugins/item_tracker/`. Sustituirá a la capa data de `plugin_item_tracker`.
- `ItemTrackerIsar`: `IsarFeature` de `storage_isar`. Quien compone la app solo lo elige; con la base abierta registra `HouseholdItemRepository` en el `ServiceLocator`. Su implementación Isar pasa `householdItemRepositoryContract`.
- Usa los mismos nombres de colección que el plugin, así que los datos ya guardados se siguen leyendo.
