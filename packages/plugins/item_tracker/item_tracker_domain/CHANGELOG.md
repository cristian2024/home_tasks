# Changelog

## 0.1.0 - 2026-10-27

### Añadido

- Dominio de item_tracker en un paquete propio, en Dart puro, dentro de `packages/plugins/item_tracker/`. Las entidades, `ItemMetadata`, `ItemValidator`, `ItemTree`, `ContainmentPolicy`, los errores `ItemTrackerException` y el contrato `HouseholdItemRepository` son los mismos que hoy tiene `plugin_item_tracker`.
- `householdItemRepositoryContract` (`package:item_tracker_domain/testing.dart`): tests de contrato que debe pasar toda implementación de `HouseholdItemRepository`, sea cual sea el motor de base de datos.
- `InMemoryHouseholdItemRepository` (`package:item_tracker_domain/testing.dart`): repositorio en memoria para tests y apps de ejemplo. Pasa `householdItemRepositoryContract`.
