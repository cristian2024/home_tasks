# Changelog

## 0.1.0 - 2026-10-27

### Añadido

- Adaptador Isar de item_tracker en un paquete propio, dentro de `packages/plugins/item_tracker/`. Sustituirá a la capa data de `plugin_item_tracker`.
- `ItemTrackerIsar`: `IsarFeature` de `storage_isar`. Quien compone la app solo lo elige; con la base abierta registra `HouseholdItemRepository` en el `ServiceLocator`. Su implementación Isar pasa `householdItemRepositoryContract`.
- Usa los mismos nombres de colección que el plugin, así que los datos ya guardados se siguen leyendo.
