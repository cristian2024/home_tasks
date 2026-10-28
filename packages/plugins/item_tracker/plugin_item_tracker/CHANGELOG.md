# Changelog

## 2.0.0 - 2026-10-28

### Cambiado

- **Incompatible:** `HouseholdItemRepository` debe estar registrado en el `ServiceLocator` antes de `initialize()`. Lo registra el adaptador de almacenamiento que elige la app (p. ej. `ItemTrackerIsar` de `item_tracker_isar`); en tests, `InMemoryHouseholdItemRepository`.

### Eliminado

- **Incompatible:** la capa data Isar del plugin: `IsarHouseholdItemRepository`, sus modelos e `itemTrackerSchemas`. Están en `item_tracker_isar`.
- **Incompatible:** `ItemTrackerPlugin` ya no implementa `StorageSchemaContributor` ni usa el `Isar` del locator como respaldo.
- **Incompatible:** el parámetro `repositoryFactory` del constructor. El repositorio sale siempre del locator.
- La dependencia de `core_storage` y la generación de código de Isar (`build_runner`, `isar_community_generator`).

## 1.2.0 - 2026-10-27

### Añadido

- El plugin pide `HouseholdItemRepository` al `ServiceLocator`: lo registra el adaptador de almacenamiento que elige la app (p. ej. `ItemTrackerIsar` de `item_tracker_isar`). Así la app no construye ni pasa el repositorio.

### Obsoleto

- Si no hay `HouseholdItemRepository` registrado, el plugin sigue usando su repositorio Isar sobre el `Isar` del locator, y sigue aportando sus colecciones como `StorageSchemaContributor`. Ambas cosas desaparecerán cuando la app y el ejemplo usen el adaptador.

### Interno

- Los tests de widgets registran el repositorio en memoria en el locator, como haría un adaptador.

## 1.1.2 - 2026-10-27

### Cambiado

- Las entidades, `ItemMetadata`, `ItemValidator`, `ItemTree`, `ContainmentPolicy`, los errores `ItemTrackerException` y `HouseholdItemRepository` vienen ahora de `item_tracker_domain`. El plugin los reexporta, así que se siguen importando desde `package:plugin_item_tracker/plugin_item_tracker.dart`.
- `package:plugin_item_tracker/testing.dart` reexporta `package:item_tracker_domain/testing.dart`, que además trae `householdItemRepositoryContract`.

### Corregido

- Los streams de `InMemoryHouseholdItemRepository` ya no pierden una escritura hecha justo después de suscribirse: leen el estado y escuchan los cambios en cuanto alguien se suscribe, como los de Isar.
- "Mover a…" podía cerrar la pantalla dos veces (y fallar con "There is nothing to pop") si la lista de objetos se actualizaba justo después de mover. Ahora solo reacciona cuando cambia el estado.

### Interno

- `IsarHouseholdItemRepository` pasa `householdItemRepositoryContract`. Los tests de dominio están ahora en `item_tracker_domain`.

## 1.1.1 - 2026-10-27

### Interno

- El paquete pasa a `packages/plugins/item_tracker/plugin_item_tracker`, la carpeta de la funcionalidad item_tracker, con su app de ejemplo. El nombre del paquete no cambia.

## 1.1.0 - 2026-10-24

### Añadido

- La app puede reemplazar los textos del plugin: `registerLocalization()` registra en `LocalizationCoordinator` cómo aplicar los reemplazos. Las claves que la app no reemplaza siguen saliendo de los JSON del plugin.

### Interno

- Tipos explícitos en todo el paquete y en su app de ejemplo.

## 1.0.0 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- Registro de objetos con identificadores de cámara (QR y códigos de barras), NFC o entrada manual.
- Listado, detalle y edición de objetos.
- Añadir y quitar identificadores desde el objeto.
- Contenedores: objetos dentro de objetos, con un máximo de niveles configurable (`ITEM_TRACKER_MAX_DEPTH`).
