# Changelog

## 0.2.1 - 2026-10-30

### Añadido

- Sincronización de item_tracker (spec §10.4):
  - `ItemTrackerCodec` y `ItemTrackerCollections`: campos sincronizados de objetos, identificadores y eventos.
  - `ItemTrackerResolver`: calcula, como función pura del estado, lo que lee la app y los conflictos (`containerDeleted`, `moveReverted` e `identifierBoundTwice`). Todos los dispositivos llegan al mismo resultado sin escribir cambios nuevos.
  - `ItemTrackerSyncStore`: contrato de las copias sincronizadas (`SyncedEntity`, de core_sync) que implementan los repositorios.
  - `ItemTrackerSyncParticipant`: el `SyncParticipant` de item_tracker. Resuelve los conflictos con escrituras normales del repositorio.
- `InMemoryHouseholdItemRepository(hlcClock:, changeLog:)` se sincroniza: registra las escrituras locales e implementa `ItemTrackerSyncStore`. Sin esos parámetros funciona igual que antes.
- `package:item_tracker_domain/testing.dart`: batería `itemTrackerSyncContract` (incluye `syncParticipantContract`), los registros de ejemplo `itemTrackerSyncRecords` y `readItemTrackerState`.

### Cambiado

- core_sync 0.1.1.

## 0.2.0 - 2026-10-29

### Añadido

- **Incompatible:** `HouseholdItemRepository.deleteItems` borra objetos con borrado lógico, junto con sus identificadores activos, que quedan libres. En la misma transacción guarda los objetos movidos (`moved`) y los eventos. Toda implementación debe añadirlo.
- `householdItemRepositoryContract` comprueba el borrado: los objetos borrados no aparecen en ninguna consulta ni stream, sus identificadores se pueden asociar a otro objeto y los ID inexistentes se ignoran.
- `ItemTree.descendantsOf`: todo lo que contiene un objeto a cualquier profundidad.
- `InMemoryHouseholdItemRepository.deletedItems`: los objetos borrados con el momento en que se borraron.
- README del paquete.

## 0.1.1 - 2026-10-27

### Corregido

- Los tests de streams de `householdItemRepositoryContract` esperan la emisión inicial antes de escribir. Una base de datos real (Isar) calcula ese estado de forma asíncrona, y si la escritura terminaba antes la primera emisión ya la incluía: el test fallaba según la velocidad de la máquina.

## 0.1.0 - 2026-10-27

### Añadido

- Dominio de item_tracker en un paquete propio, en Dart puro, dentro de `packages/plugins/item_tracker/`. Las entidades, `ItemMetadata`, `ItemValidator`, `ItemTree`, `ContainmentPolicy`, los errores `ItemTrackerException` y el contrato `HouseholdItemRepository` son los mismos que hoy tiene `plugin_item_tracker`.
- `householdItemRepositoryContract` (`package:item_tracker_domain/testing.dart`): tests de contrato que debe pasar toda implementación de `HouseholdItemRepository`, sea cual sea el motor de base de datos.
- `InMemoryHouseholdItemRepository` (`package:item_tracker_domain/testing.dart`): repositorio en memoria para tests y apps de ejemplo. Pasa `householdItemRepositoryContract`.
